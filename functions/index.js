/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers
 * at https://firebase.google.com/docs/functions
 */


// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// Import Firebase Functions and Firebase Admin SDK
const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin to gain elevated privileges
admin.initializeApp();

exports.sendInviteNotification = functions.firestore
    .document("lobby/{lobbyId}")
    // This function triggers on update of any lobby document
    .onUpdate(async (change, context) => {
    // Obtain the list of invited players before and after the update
      const oldInvitedPlayers = change.before.data().invited_users;
      const newInvitedPlayers = change.after.data().invited_users;
      // Check if any players have been added
      const addedPlayers = newInvitedPlayers.filter(
          (player) => !oldInvitedPlayers || !oldInvitedPlayers.includes(player),
      );

      // If there are no new players, stop the function here
      if (addedPlayers.length === 0) return null;

      // For each added player, add the lobbyID to their invites array
      for (const playerId of addedPlayers) {
      // Get the user document
        const playerDocRef = admin.firestore().collection("users")
            .doc(playerId);
        const playerDoc = await playerDocRef.get();
        const playerInvites = playerDoc.data().invites || {};

        try {
        // Add the lobbyID to the user's invites object
          const lobbyId = context.params.lobbyId;
          // Assuming the lobbyId is obtained from the context
          playerInvites[playerId] = lobbyId;

          // Update the invites object in the user document
          await playerDocRef.update({
            invites: playerInvites,
          });
        } catch (error) {
          console.error("Error updating user invites:", error);
          return null; // Stop execution in case of error
        }
      }

      return null;
    });

exports.sendFriendRequest = functions.firestore
    .document("users/{userId}")
    .onUpdate((change, context) => {
      const oldData = change.before.data();
      const newData = change.after.data();

      // Check if friendRequests object has changed
      if (Object.keys(oldData.friendRequests).length !== Object
          .keys(newData.friendRequests).length) {
        const addedFriendRequests = Object.keys(newData.friendRequests)
            .filter((friend) => !(friend in oldData.friendRequests));

        if (addedFriendRequests.length > 0) {
          const userId = context.params.userId;

          // Process each friend request
          addedFriendRequests.forEach((friendId) => {
            const friendRequest = {
              status: "received",
              date: newData.friendRequests[friendId].date,
            };

            // Update each friend's document separately
            admin.firestore().collection("users").doc(friendId)
                .update({
                  [`friendRequests.${userId}`]: friendRequest,
                });
          });
        }
      }
      return null;
    });

// Triggered when a friend request is accepted
exports.acceptFriendRequest = functions.firestore
    .document("users/{userId}")
    .onUpdate((change, context) => {
      const oldData = change.before.data();
      const newData = change.after.data();

      // Check if friends array has changed
      if (oldData.friends.length !== newData.friends.length) {
        const addedFriends = newData.friends
            .filter((friend) => !oldData.friends.includes(friend));

        if (addedFriends.length > 0) {
          const userId = context.params.userId;

          // Process each friend acceptance
          addedFriends.forEach((friendId) => {
            // Remove friend request from friend's document
            const updateData = {};
            updateData[`friendRequests.${userId}`] = admin
                .firestore.FieldValue.delete();
            updateData["friends"] = admin.firestore.FieldValue
                .arrayUnion(userId);

            // Update each friend's document separately
            admin.firestore().collection("users").doc(friendId)
                .update(updateData);
          });
        }
      }
      return null;
    });

// Triggered when a friend request is rejected
exports.rejectFriendRequest = functions.firestore
    .document("users/{userId}")
    .onUpdate((change, context) => {
      const oldData = change.before.data();
      const newData = change.after.data();

      // Check if friendRequests object has changed
      if (Object.keys(oldData.friendRequests).length !== Object
          .keys(newData.friendRequests).length) {
        const removedFriendRequests = Object.keys(oldData.friendRequests)
            .filter((friend) => !(friend in newData.friendRequests));

        if (removedFriendRequests.length > 0) {
          const userId = context.params.userId;

          // Process each friend request rejection
          removedFriendRequests.forEach((friendId) => {
            // Update each friend's document separately
            admin.firestore().collection("users").doc(friendId)
                .update({
                  [`friendRequests.${userId}`]: admin.firestore
                      .FieldValue.delete(),
                });
          });
        }
      }
      return null;
    });

// Triggered when a friend is removed
exports.removeFriend = functions.firestore
    .document("users/{userId}")
    .onUpdate((change, context) => {
      const oldData = change.before.data();
      const newData = change.after.data();

      // Check if friends array has changed
      if (oldData.friends.length !== newData.friends.length) {
        const removedFriends = oldData.friends
            .filter((friend) => !newData.friends.includes(friend));

        if (removedFriends.length > 0) {
          const userId = context.params.userId;

          // Process each friend removal
          removedFriends.forEach((friendId) => {
            // Update each friend's document separately
            admin.firestore().collection("users").doc(friendId).update({
              friends: admin.firestore.FieldValue.arrayRemove(userId),
            });
          });
        }
      }
      return null;
    });
