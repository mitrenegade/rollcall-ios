function associateAttendancesWithNewPayment(newPayment, response) {
	// when a new payment is created, reassociate attendances

	var member = newPayment.get("member");
	var startDate = newPayment.get("startDate");
	var type = newPayment.get("type")
	var endDate = newPayment.get("endDate")

	var query = new Parse.Query("Attendance");
	query.equalTo("member", member);
	query.equalTo("attended", 1);
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
			if (response)
				response.success(results);
		},
		error: function(error) {
			console.log(error);
			if (response)
				response.error(error);
		}
	});
}

function associateNewAttendanceWithPayment(newAttendance, paymentType, response) {
	if (paymentType == 1) { // MONTHLY
			console.log("associateNewAttendanceWithMonthlyPayment");
			var member = newAttendance.get("member");
			var date = newAttendance.get("date");

			// associate with any monthly first
			var query = new Parse.Query("Payment");
			query.equalTo("member", member);
			query.equalTo("type", 1);
			query.ascending("receivedDate");
			query.lessThanOrEqualTo("startDate", date);
			query.greaterThanOrEqualTo("endDate", date);

			query.find({
				success: function(results) {
					console.log(results.length + " monthly payments found");
					if (results.length > 0) {
						var payment = results[0];
						console.log("setting monthly payment " + payment.id + " to attendance " + newAttendance.id)
						newAttendance.set("payment", payment);
						response.success(1);
						return;
					}
					else {
						response.success(0);
						return;
					}
				},
				error: function(error) {
					console.log("query error " + error);
				}
			});		
	}
	else if (paymentType == 2) { // DAILY
		var member = newAttendance.get("member");
		var date = newAttendance.get("date");

		// associate with any monthly first
		var query = new Parse.Query("Payment");
		query.equalTo("member", member);
		query.equalTo("type", 2);
		query.lessThanOrEqualTo("startDate", date);
		query.ascending("receivedDate");

		query.find({
			success: function(results) {
				console.log(results.length + " daily payments found");
				if (results.length > 0) {
					var found = 0;
					for (i=0; i<results.length; i++) {
						var payment = results[i];
						var attendancesQuery = new Parse.Query("Attendance");
						attendancesQuery.equalTo("payment", payment);
						attendancesQuery.count({
							success:function(count) {
								if (count < payment.get("days")) {
									console.log("daily payment " + payment.id + " has " + count + " of " + payment.get("days"))
									newAttendance.set("payment", payment);
	//								newAttendance.save();
									response.success(1);
									found = 1;
									return;
								}
								else {
									// go to the next
									console.log("daily payment " + payment.id + " is full");
								}
							},
							error: function(error) {
								// could not count. go to the next
							}
						})
					}
					if (found) {
						console.log("found but still here");
					}
					else {
						console.log("found = 0; no daily payment out of " + results.length + " with attendances left were found");
					}
					response.success(0);
					return;
				}
				else {
					response.success(0);
					return;
				}
			},
			error: function(error) {
				console.log("query error " + error);
			}
		});
	}
}

// manually add a payment (as practice). can be replaced with afterSave on payments
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

					associateAttendancesWithNewPayment(obj, response);
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
});

// use afterSave on payment
Parse.Cloud.afterSave("Payment", function(request) {
	payment = request.object;
	member = payment.get("member")
	console.log("Saved payment " + payment.id + " for member " + member.id);
	associateAttendancesWithNewPayment(payment)
});

// afterSave for an attendance
Parse.Cloud.beforeSave("Attendance", function(request, response) {
	attendance = request.object;
	var attended = attendance.get("attended");
	if (attended == 0 || attended == 2) { // not attended or freebie - no payment needed
		console.log("attendance saved: not attended")
		// remove payment
		payment = attendance.get("payment");
		if (payment) {
			if (payment.get("type") == 2) {
				// daily payment
				var payment = attendance.get("payment");
				attendance.unset("payment");
				console.log("removing daily payment " + payment.id + " from unattendance " + attendance.id);
			}
		}
		response.success();
	}
	else {
		// saving a new attendance
		if (attendance.get("payment")) {
			console.log("payment exists " + attendance.get("payment").id + " for attendance " + attendance.id);
			response.success();
		}
		else {
			console.log("associating new attendance with a payment");
			paymentType = 1;
			associateNewAttendanceWithPayment(attendance, paymentType, {
				success: function(count) {
					if (count == 0) {
						// do daily payments
						paymentType = 2;
						associateNewAttendanceWithPayment(attendance, paymentType, {
							success: function(count) {
								if (count == 0) {
									console.log("attendance could not be associated with a payment");
								}
								else {
									console.log("attendance " + attendance.id + " now has daily payment " + attendance.get("payment").id)
								}
							}
						});
					}
					else {
						console.log("attendance now has monthly payment " + attendance.get("payment").id)
					}
					response.success();
				}
			});
		}
	}
});