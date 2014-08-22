
// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
Parse.Cloud.define("associatePayments", function(request, response) {
	var memberId = request.params.memberId;
	console.log("searching for memberId " + memberId);
	var innerQuery = new Parse.Query("Member");
	innerQuery.equalTo("objectId", memberId);

	var payments;
	var attendances;

	// first query for users, then match the results of that query as a condition for the payments query
	var paymentsQuery = new Parse.Query("Payment");
	paymentsQuery.matchesQuery("member", innerQuery);
	paymentsQuery.find({
		success: function(paymentResults) {
			console.log(paymentResults.length + " payments found for user " + memberId);
			payments = paymentResults;

			var attendancesQuery = new Parse.Query("Attendance");
			attendancesQuery.matchesQuery("member", innerQuery);
			attendancesQuery.find({
				success: function(attendancesResults) {
					console.log(attendancesResults.length + " attendances found for user " + memberId);
					attendances = attendancesResults;

					new_attendances = setPaymentForAttendances(payments[1], attendances);
					results = { "payments": payments, "attendances": new_attendances};

					response.success(results)
				},
				error: function(error) {
					console.log(error);
				}
			})

		},
		error: function(error) {
			console.log(error);
		}
	})
});

function setPaymentForAttendances(newPayment, response) {
	var member = newPayment.get("member");
	var startDate = newPayment.get("startDate");
	var type = newPayment.get("type")
	var endDate = newPayment.get("endDate")

	var query = new Parse.Query("Attendance");
	query.equalTo("member", member);
	query.ascending("date");
	query.greaterThanOrEqualTo("date", startDate);
	if (type == 1) {
		// monthly payment
		console.log("searching for monthly attendances between " + startDate + " and " + endDate);
		query.lessThanOrEqualTo("date", endDate);
	}
	else if (type == 2) {
		// daily payment
		console.log("searching for unpaid attendances after " + startDate);
		query.limit(newPayment.get("days"));
		query.doesNotExist("payment");
	}

	query.find({
		success: function(results) {
			console.log(results.length + " attendances found");
			for (i = 0; i<results.length; i++) {
				var attendance = results[i];
				var oldPayment = attendance.get("payment"); // only returns objectId, not the actual payment
				attendance.set("payment", newPayment);
				attendance.save()
				var payment2 = attendance.get("payment");
				console.log("**** attendance " + attendance.id + ": old payment " + oldPayment.id + " => new payment " + payment2.id);
			}
			response.success(results);
		},
		error: function(error) {
			console.log(error);
			response.error(error);
		}
	});
}

function createPaymentForMember(paymentParams, member) {
	// create payment and associate with member
	var newPayment = new Parse.Object("Payment");
	paymentParams.member = member;
	newPayment.save(paymentParams); 
	console.log("created payment: " + JSON.stringify(newPayment));
	return newPayment;
}

Parse.Cloud.define("addPayment", function(request, response) {
	var memberId = request.params.memberId;
	console.log("searching for memberId " + memberId);
	var innerQuery = new Parse.Query("Member");
	innerQuery.equalTo("objectId", memberId);

	innerQuery.find({
		success: function(results) {
			var member = results[0];
			console.log("found member: " + JSON.stringify(member));

			// create payment and associate with member
			var newPaymentParams = request.params.payment
			var newPayment = new Parse.Object("Payment");
			newPaymentParams.member = member;
			newPayment.save(newPaymentParams, {
				success: function(obj) {
					console.log("save success: " + obj.id);
					console.log("adding a new payment with id " + obj.id + ": " + JSON.stringify(obj));

					setPaymentForAttendances(obj, response);
				},
				error: function(error) {
					console.log("save error: " + JSON.stringify(error));
					response.error(error);
				}
			});
		},
		error: function(error) {
			console.log("could not find member. error: " + JSON.stringify(error));
		}
	});
/*
	var startDate = newPayment.get("startDate");
	var type = newPayment.get("type")
	var endDate = newPayment.get("endDate")

	if (type == 1) {
		console.log("monthly payment for dates " + startDate + " - " + endDate)
		var query = new Parse.Query("Attendance");
		query.greaterThanOrEqualTo("date", startDate);
		query.lessThanOrEqualTo("date", endDate);
		query.matchesQuery("member", innerQuery);
		query.find({
			success: function(results) {
				console.log(results.length + " attendances found");
				for (i = 0; i<results.length; i++) {
					var attendance = results[i];
					var payment = attendance.get("payment"); // only returns objectId, not the actual payment
					console.log("**** attendance " + attendance.id + ": old payment " + payment.id);
					attendance.set("payment", newPayment);
					attendance.save()
					var payment2 = attendance.get("payment");
					console.log("****** attendance " + attendance.id + ": new payment " + JSON.stringify(payment2));
				}
				response.success(results);
			},
			error: function(error) {
				console.log(error);
			}
		});
	}
	else if (newPayment.type == 2) {
		console.log("daily payment starting at date " + startDate + " with " + newPayment.days + " days left");
	}
	*/
});