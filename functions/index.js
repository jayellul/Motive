// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp();

//exports.dbWrite = functions.database.ref('/users/{uid}/display').onWrite((change, context) => {
//	const beforeData = change.before.val(); // data before the write
//	const afterData = change.after.val(); // data after the write
//	console.log(beforeData)
//	console.log(afterData)
//});

// cron guide
// https://firebase.googleblog.com/2017/03/how-to-schedule-cron-jobs-with-cloud.html

// THIS JOB IS RAN EVERY HOUR : 
// https://console.firebase.google.com/project/wyddatabase/functions/logs?search=&severity=DEBUG
// https://console.cloud.google.com/logs/viewer?project=wyddatabase&folder&organizationId&minLogLevel=0&expandAll=false&timestamp=2018-06-15T17:17:58.606000000Z&customFacets=&limitCustomFacetWidth=true&dateRangeEnd=2018-06-15T17:17:58.856Z&interval=PT1H&resource=gae_app&scrollTimestamp=2018-06-15T17:17:04.075000000Z&dateRangeStart=2018-06-15T16:17:58.856Z
// https://console.cloud.google.com/appengine/taskqueues/cron?project=wyddatabase&folder&organizationId&tab=CRON
/*exports.hourly_job =
	functions.pubsub.topic('hourly-tick').onPublish((event) => {
		// get current date and time
		var currentDate = new Date();
		// time is stored in negatives in the database, so multiply by -1
		var currentNumMilliseconds = currentDate.getTime() * -1;
		var runTime = new Date(currentNumMilliseconds * -1);
		console.log("Hourly Archive Ran at: " + runTime);
		// add 2 days worth of time
		// UPDATE: 3 days
		var twoDaysAgo = currentNumMilliseconds + (3 * 24 * 60 * 60 * 1000);
		var cutoffDate = new Date(twoDaysAgo * -1);
		console.log("Query start at date: " + cutoffDate);
		const ref = admin.database().ref('motives');
		// query all motives more than 2 days old
		return ref.orderByChild("time").startAt(twoDaysAgo).once('value').then(function (snapshot) {
			snapshot.forEach(function(childSnapshot) {
		    	var key = childSnapshot.key;
  				var motive = childSnapshot.val();
				// add to archives
				const archiveRef = admin.database().ref('archive/' + motive.id).set({
					creator: motive.creator,
					text: motive.text,
					id: motive.id,
					latitude: motive.latitude,
					longitude: motive.longitude,
					time: motive.time,
					numGoing: motive.numGoing,
					nC: motive.nC,
					icon: motive.icon
				});
				// copy motivesGoing to archivesGoing
				const archiveGoingRef = admin.database().ref('archiveGoing/' + motive.id);
				const goingRef = admin.database().ref('motivesGoing/' + motive.id).once("value", function(snapshot) {
					snapshot.forEach(function(childSnapshot) {
						archiveGoingRef.child(childSnapshot.key).set(childSnapshot.key);
					});
				});
				// add points to the users directory 
				const pointsRef = admin.database().ref('users/' + motive.creator + '/p');
				const addPoints = pointsRef.once("value", function(snapshot) {
					if (motive.numGoing > 0) {
						var currentPoints = snapshot.val();
						var newPoints = currentPoints + (motive.numGoing * 5);
						pointsRef.set(newPoints);
						console.log("User " + motive.creator + " new point count: " + newPoints);
					}
				});
				// promise to wait for all of the archives to set in database before deleting
   				Promise.all([goingRef, archiveRef, addPoints]).then(() => {
	   				// delete from motives & motivesGoing
					const deleteRef = admin.database().ref('motives/' + motive.id).remove();
					const delegeGoingRef = admin.database().ref('motivesGoing/' + motive.id).remove();
					var createTime = new Date(motive.time * -1);
					console.log("Motive created on: " + createTime + " Archived: " + motive.id);
				});
   			
			});

		});

  	});*/

exports.countGoing = functions.https.onCall((data, context) => {
	// Checking that the user is authenticated.
	if (!context.auth) {
		throw new functions.https.HttpsError('failed-precondition', 'The function must be called ' + 'while authenticated.');
	}
	const id = data.id;
	const creator = data.creator;
	const name = data.name;
	var numGoing = 0;
	var token = '';
	const goingPromise = admin.database().ref('motivesGoing/' + id).once('value');
	const tokensPromise = admin.database().ref('tokens/' + creator).once('value');
	return Promise.all([goingPromise, tokensPromise]).then(results => {
		let goingSnapshot = results[0];
		let tokensSnapshot = results[1];

		if (goingSnapshot.exists()) {
			numGoing = goingSnapshot.numChildren();
		}

		if (tokensSnapshot.exists()) {
			token = tokensSnapshot.val();
			console.log(token);
		}

		const payload = {
          notification: {
            title: '',
            body: name + ' is going to your Motive.',
            sound: 'default'
          }
	    };
	    if (name != '' && token != ''&& creator != context.auth.uid) {
			return admin.messaging().sendToDevice(token, payload);
		} else {
			return 
		}

	}).then(() => {
		console.log(id + ' sent to client ' + numGoing);
			return { num: numGoing };
	})
});

exports.countComments = functions.https.onCall((data, context) => {
	// Checking that the user is authenticated.
	if (!context.auth) {
		throw new functions.https.HttpsError('failed-precondition', 'The function must be called ' + 'while authenticated.');
	}
	const id = data.id;
	const creator = data.creator;
	const name = data.name;
	const commentText = data.commentText;
	var numComments = 0;
	var token = '';
	const commentsPromise = admin.database().ref('motiveComments/' + id).once('value');
	const tokensPromise = admin.database().ref('tokens/' + creator).once('value');
	return Promise.all([commentsPromise, tokensPromise]).then(results => {
		let commentsSnapshot = results[0];
		let tokensSnapshot = results[1];

		if (commentsSnapshot.exists()) {
			numComments = commentsSnapshot.numChildren();
		}

		if (tokensSnapshot.exists()) {
			token = tokensSnapshot.val();
		}

		const payload = {
          notification: {
            title: '',
            body: name + ' commented \"' + commentText + '\" on your Motive.',
            sound: 'default'
          }
	    };
	    if (name != '' && token != '' && creator != context.auth.uid) {
			return admin.messaging().sendToDevice(token, payload);
		} else {
			return 
		}

	}).then(() => {
		console.log('Comment ' + id + ' sent to client ' + numComments);
			return { num: numComments };
	})
});

/*	return admin.database().ref('motiveComments/' + id).once("value", function(snapshot) {
		
		if (snapshot.exists()) {
			numComments = snapshot.numChildren();
		}

	}).then(() => {
			return { num: numComments };
	})
});*/

exports.countFollowers = functions.https.onCall((data, context) => {
	// Checking that the user is authenticated.
	if (!context.auth) {
		throw new functions.https.HttpsError('failed-precondition', 'The function must be called ' + 'while authenticated.');
	}
	const id = data.id;
	const name = data.name;
	var token = '';
	var numFollowers = 0;
	const followersPromise = admin.database().ref('followers/' + id).once('value');
	const tokensPromise = admin.database().ref('tokens/' + id).once('value');
	return Promise.all([followersPromise, tokensPromise]).then(results => {
		let followersSnapshot = results[0];
		let tokensSnapshot = results[1];

		if (followersSnapshot.exists()) {
			numFollowers = followersSnapshot.numChildren();
		}

		if (tokensSnapshot.exists()) {
			token = tokensSnapshot.val();
		}

		const payload = {
          notification: {
            title: '',
            body: name + ' is now following you.',
            sound: 'default'
          }
	    };
	    if (name != '' && token != '' && id != context.auth.uid) {
			return admin.messaging().sendToDevice(token, payload);
		} else {
			return 
		}

	}).then(() => {
		console.log('numfollowers sent to client: ' + numFollowers);
		return { num: numFollowers };
	})
});

// function called when request is accepted - counts currentusers followers and other users following
exports.requestAccepted = functions.https.onCall((data, context) => {
	// Checking that the user is authenticated.
	if (!context.auth) {
		throw new functions.https.HttpsError('failed-precondition', 'The function must be called ' + 'while authenticated.');
	}
	const currentUserUid = data.currentUserUid;
	const id = data.id;
	const name = data.name;
	var numFollowers = 0;
	var numFollowing = 0;
	var token = '';
	// count followers of current user - nested promises
	const followersPromise = admin.database().ref('followers/' + currentUserUid).once('value');
	const followingPromise = admin.database().ref('following/' + id).once('value');
	const tokensPromise = admin.database().ref('tokens/' + id).once('value');
	return Promise.all([followersPromise, followingPromise, tokensPromise]).then(results => {
		let followersSnapshot = results[0];
		let followingSnapshot = results[1];
		let tokensSnapshot = results[2];
		if (followersSnapshot.exists()) {
			numFollowers = followersSnapshot.numChildren();
		}
		if (followingSnapshot.exists()) {
			numFollowing = followingSnapshot.numChildren();
		}
		if (tokensSnapshot.exists()) {
			token = tokensSnapshot.val();
		}
		const payload = {
        	notification: {
            	title: '',
            	body: name + ' has accepted your follow request. You can now view their profile and posted Motives.',
            	sound: 'default'
          	}
	    };
	    if (name != '' && token != '' && id != currentUserUid) {
			return admin.messaging().sendToDevice(token, payload);
		} else {
			return 
		}

	}).then(() => {
		console.log('numfollowers of: ' + currentUserUid  +' : ' + numFollowers);
		console.log('numfollowing of: ' + id + ' : ' + numFollowing);
		return { numFollowers: numFollowers, numFollowing: numFollowing };
	})
});

