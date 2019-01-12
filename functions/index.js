const functions = require('firebase-functions');
const admin = require('firebase-admin');
const request = require('request')
const app = require('express')

const config = functions.config().dev
const stripe = require('stripe')(config.stripe.token)

admin.initializeApp(functions.config().firebase);

/*** Stripe connect ***/
// https://stackoverflow.com/questions/52493606/stripe-connect-firebase-functions
exports.stripeConnectRedirectHandler = functions.https.onRequest((req, res) => {
    // the url will look like: 
    // http://us-central1-balizinha-dev.cloudfunctions.net/stripeConnectRedirectHandler?scope=read_write&code={AUTHORIZATION_CODE}
    console.log("StripeConnectRedirectHandler with query: " + JSON.stringify(req.query))
    var code = req.query.code
    var userId = req.query.state

    // request access token
    let url = "https://connect.stripe.com/oauth/token"
    request.post(url,
        { 
            form: { 
                "client_secret": 'sk_test_UeupqMc6Nu10Jlnqt2tCXroj',
                "code": code,
                "grant_type": "authorization_code"
            },
        },
        function (e, r, body) {
            console.log("StripeConnectRedirectHandler: body " + JSON.stringify(body))
            let json = JSON.parse(body)
            let accessToken = json.access_token
            let refreshToken = json.refresh_token
            let stripeUserId = json.stripe_user_id
            let publishableKey = json.stripe_publishable_key

            return storeStripeConnectTokens(userId, stripeUserId, accessToken, refreshToken, publishableKey).then(result => {
                console.log("StripeConnectRedirectHandler: stored tokens with result " + JSON.stringify(result))
                let url = "rollcall://stripeConnect/" + userId
                return res.redirect(url)
            })
    });
})

storeStripeConnectTokens = function(userId, stripeUserId, accessToken, refreshToken, publishableKey) {
    const ref = `/stripeAccounts/${userId}`
    const params = {"accessToken": accessToken, 
                    "refreshToken": refreshToken,
                    "stripeUserId": stripeUserId,
                    "publishableKey": publishableKey}
    console.log("StoreStripeConnectTokens: ref " + ref + " tokens " + JSON.stringify(params))
    return admin.database().ref(ref).set(params)
}

exports.getConnectAccountInfo = functions.https.onRequest((req, res) => {
	var accountId = req.query.accountId
	if (accountId == undefined) {
		console.log("getConnectAccountInfo: No Stripe account provided")
		return res.status(500).json({"error": "No Stripe account provided"})
	}

	return stripe.accounts.retrieve(accountId,
		function(err, account) {
		// asynchronously called
			if (err != undefined) {
				console.log("getConnectAccountInfo: received error while retrieving accounts: " + JSON.stringify(err))
				return res.status(500).json({"error": "Received error while retrieving accounts", "info": err})
			} else {
				console.log("getConnectAccountInfo: Retrieved accounts for " + accountId + ": " + JSON.stringify(account))
				return res.status(200).json({"account": account})
			}
		}
	);
})

/*
 * Params:
 * amount: Int, cents
 * orgId: String
 * eventId: String
 * chargeId: String, client-generated
 * source: payment token from stripe
 */
exports.createStripeConnectCharge = functions.https.onRequest((req, res) => {
    // Create a charge using the pushId as the idempotency key, protecting against double charges 
    const amount = req.body.amount;
    const orgId = req.body.orgId
    const source = req.body.source
    const eventId = req.body.eventId
    const chargeId = req.body.chargeId
    const idempotency_key = chargeId
    const currency = 'USD'
    console.log("CreateStripeConnectCharge amount " + amount + " orgId " + orgId + " event " + eventId + " source " + source)
    var accountRef = `/stripeAccounts/${orgId}`
    return admin.database().ref(accountRef).once('value').then(snapshot => {
        if (!snapshot.exists()) {
            throw new Error("No Stripe account found for organization")
        }
        const customerDict = snapshot.val()
        const connectId = customerDict["stripeUserId"]
        if (connectId == undefined) {
            throw new Error("No Stripe account associated with organization")
        }
        return connectId
    }).then(stripe_account => {
        const charge = {
            amount, 
            currency,
            source
        }
        const headers = {
//            idempotency_key, 
            stripe_account
        }
        console.log("CreateStripeConnectCharge: creating charge for stripe connect: charge: " + JSON.stringify(charge), " headers: " + JSON.stringify(headers))
        return stripe.charges.create(charge, headers)
        .then(response => {
            // If the result is successful, write it back to the database
            console.log("CreateStripeConnectCharge success with response " + JSON.stringify(response))
            const ref = admin.database().ref(`/charges/events/${eventId}/${chargeId}`)
            return ref.update(response)
        }, error => {
            // We want to capture errors and render them in a user-friendly way, while
            // still logging an exception with Stackdriver
            console.log("CreateStripeConnectCharge createCharge error: " + error)
            const ref = admin.database().ref(`/charges/events/${eventId}/${chargeId}`)
            return ref.child('error').set(error.message)
        })
    }).catch((error) => {
        console.log("CreateStripeConnectCharge caught error: " + error) //JSON.stringify(error))
        return res.status(500).json({"error": error})
    })
})

exports.ephemeralKeys = functions.https.onRequest((req, res) => {
//exports.ephemeralKeys = function(req, res, stripe) {
    let stripe_version = req.body.api_version
    let customerId = req.body.customerId
    console.log('Stripe v1.0 ephemeralKeys with ' + stripe_version + ' and ' + customerId)
    if (!stripe_version) {
        return res.status(400).end();
    }
    // This function assumes that some previous middleware has determined the
    // correct customerId for the session and saved it on the request object.
    return stripe.ephemeralKeys.create(
        {customer: customerId},
        {stripe_version: stripe_version}
    ).then((key) => {
        return res.status(200).json(key);
    }).catch((err) => {
        return res.status(500).json({"error": err});
    })
})

exports.validateStripeCustomer = functions.https.onRequest((req, res) => {
//exports.validateStripeCustomer = function(req, res, exports, admin, stripe) {
    const userId = req.body.userId
    const email = req.body.email

    if (userId == undefined || userId == "") {
        return res.status(500).json({"error": "Could not validate Stripe customer: empty user id"})
    }
    if (email == undefined || email == "") {
        return res.status(500).json({"error": "Could not validate Stripe customer: empty email"})
    }

    var customerRef = `/stripeCustomers/${userId}/customerId`
    return admin.database().ref(customerRef).once('value')
    .then(snapshot => {
        if (!snapshot.exists()) {
            console.log("ValidateStripeCustomer: userId " + userId + " customer not found. Creating...")
            return exports.createStripeCustomer(email, userId)
        } else {
            console.log("ValidateStripeCustomer: userId " + userId + " customer found: " + snapshot.val())
            return snapshot.val()
        }
    }).then(customer => {
        return res.status(200).json({"customerId": customer})
    })
})

createStripeCustomer = function(email, uid) {
    console.log("Stripe 1.0: Creating stripeCustomer " + uid + " " + email)
    const ref = `/stripeCustomers/${uid}/customerId`
    return stripe.customers.create({
        email: email
    }, function(err, customer) {
        if (err != undefined) {
            console.log('CreateStripeCustomer v1.0' + ref + ' resulted in error ' + err)
            return err
        } else {
            console.log('CreateStripeCustomer v1.0 ' + ref + ' email ' + email + ' created with customerId ' + customer.id)
            return admin.database().ref(ref).set(customer.id);
        }
    }).then(result => {
        console.log('createStripeCustomer returning the value')
        return admin.database().ref(ref).once('value')
    })
}
