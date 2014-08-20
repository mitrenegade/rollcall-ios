
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

					results = { "payments": payments, "attendances": attendances};
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

	/*
	var query = new Parse.Query("Member");
	query.equalTo("objectId", memberId);
	query.find({
		success: function(results) {
			console.log(results.length + " results for member with objectId " + memberId + ": " + results[0]);
			console.log("searching for payments with member: " + results[0])
			var paymentQuery = new Parse.Query("Payment");
			paymentQuery.equalTo("member", results[0]);
			paymentQuery.find({
				success: function(paymentResults) {
					console.log("found payments: " + paymentResults);
					response.success(paymentResults);
				},
				error : function(error) {
					console.log("payment query error: " + error);
					response.error(error);
				}
			})
		},
		error: function(error) {
			console.log("error: " + error.status);
			response.error(error);
		}
	});
*/
});
