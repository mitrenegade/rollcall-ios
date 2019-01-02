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
	if (accountId === undefined) {
		console.log("getConnectAccountInfo: No Stripe account provided")
		return res.status(500).json({"error": "No Stripe account provided"})
	}

	return stripe.accounts.retrieve(accountId,
		function(err, account) {
		// asynchronously called
			if (err !== undefined) {
				console.log("getConnectAccountInfo: received error while retrieving accounts: " + JSON.stringify(err))
				return res.status(500).json({"error": "Received error while retrieving accounts", "info": err})
			} else {
				console.log("getConnectAccountInfo: Retrieved accounts for " + accountId + ": " + JSON.stringify(account))
				return res.status(200).json({"account": account})
			}
		}
	);
})
