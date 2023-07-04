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
// Initialiser le service de messagerie
const messaging = admin.messaging();

exports.sendInviteNotification = functions.firestore
    .document("lobby/{lobbyId}")
    // This function triggers on update of any lobby document
    .onUpdate(async (change, context) => {
      const newData = change.after.data();
      // Obtain the list of invited players before and after the update
      const oldInvitedPlayers = change.before.data().invited_users || [];
      const newInvitedPlayers = change.after.data().invited_users || [];
      const lobbyId = context.params.lobbyId;
      // Check if any players have been added
      const addedPlayers = newInvitedPlayers.filter(
          (playerId) => !oldInvitedPlayers.includes(playerId),
      );

      // Check if the function has been triggered by our own update
      if (newData.triggeredByFunction) {
        // Reset the trigger flag in the document
        await admin.firestore().collection("users")
            .doc(context.params.userId).update({
              triggeredByFunction: admin.firestore.FieldValue.delete(),
            });
        // Skip this function execution
        return null;
      }

      // Check if the action performer is the user himself
      if (newInvitedPlayers.actionPerformer && newInvitedPlayers
          .actionPerformer === context.params.userId) {
        return null; // The user performed the action himself,
        // so skip this execution
      }

      // If there are no new players, stop the function here
      if (addedPlayers.length === 0) return null;

      // For each added player, add the lobbyID to their invites array
      for (const playerId of addedPlayers) {
        // Get the user document
        const playerDocRef = admin.firestore().collection("users")
            .doc(playerId);
        const playerDoc = await playerDocRef.get();
        const playerInvites = playerDoc.data().invites || {};
        // Ajouté pour obtenir le token du joueur
        const playerToken = playerDoc.data().token || null;

        try {
          // Add the lobbyID to the user's invites object

          const invitingUserId = change.after.data().creator;
          // Assuming 'creator' field stores UID of the user who invites
          playerInvites[invitingUserId] = lobbyId;

          // Update the invites object in the user document
          await playerDocRef.update({
            invites: playerInvites,
            triggeredByFunction: true, // Set the trigger flag
          });
        } catch (error) {
          console.error("Error updating user invites:", error);
          return null; // Stop execution in case of error
        }

        // Send a notification to the player receiving the invite
        const message = {
          "notification": {
            "title": "Game invite",
            "body": `You have been invited to join a room`,
          },
          "data": {
            "notificationType": "gameInvitation",
            "lobbyID": lobbyId,
          },
          "token": playerToken, // Utiliser le token du joueur
        };

        await messaging.send(message);
      }

      return null;
    });

exports.sendFriendRequest = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      const oldData = change.before.data();
      const newData = change.after.data();

      // Check if the function has been triggered by our own update
      if (newData.triggeredByFunction) {
        // Reset the trigger flag in the document
        await admin.firestore().collection("users")
            .doc(context.params.userId).update({
              triggeredByFunction: admin.firestore.FieldValue.delete(),
            });
        // Skip this function execution
        return null;
      }

      // Check if the action performer is the user himself
      if (newData.actionPerformer && newData
          .actionPerformer === context.params.userId) {
        return null; // The user performed the action himself,
        // so skip this execution
      }

      if (Object.keys(oldData.friendRequests).length !== Object
          .keys(newData.friendRequests).length) {
        const addedFriendRequests = Object.keys(newData.friendRequests)
            .filter((friend) => !(friend in oldData.friendRequests));

        if (addedFriendRequests.length > 0) {
          const userId = context.params.userId;

          for (const friendId of addedFriendRequests) {
          // Get the user document
            const playerDocRef = admin.firestore().collection("users")
                .doc(friendId);
            const playerDoc = await playerDocRef.get();
            const playerToken = playerDoc.data().token || null;

            if (newData.friendRequests[friendId].status === "sent") {
              const friendRequest = {
                status: "received",
                date: newData.friendRequests[friendId].date,
              };

              await admin.firestore().collection("users").doc(friendId)
                  .update({
                    [`friendRequests.${userId}`]: friendRequest,
                    triggeredByFunction: true, // Set the trigger flag
                  });
            }

            // Send a notification to the player receiving the invite
            const message = {
              "notification": {
                "title": "New friend request",
                "body": "You received a new friend request",
              },
              "data": {
                "notificationType": "friendRequest",
              },
              "token": playerToken,
            };

            await admin.messaging().send(message);
          }
        }
      }

      return null;
    });

// Triggered when a sent friend request is cancelled
exports.cancelFriendRequest = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      const oldData = change.before.data();
      const newData = change.after.data();

      // Check if the function has been triggered by our own update
      if (newData.triggeredByFunction) {
        // Reset the trigger flag in the document
        await admin.firestore().collection("users")
            .doc(context.params.userId).update({
              triggeredByFunction: admin.firestore.FieldValue.delete(),
            });
        // Skip this function execution
        return null;
      }

      // Check if the action performer is the user himself
      if (newData.actionPerformer && newData
          .actionPerformer === context.params.userId) {
        return null; // The user performed the action himself,
        // so skip this execution
      }

      if (Object.keys(oldData.friendRequests)
          .length !== Object.keys(newData.friendRequests).length) {
        const cancelledFriendRequests = Object.keys(oldData
            .friendRequests).filter((friend) => !(friend in newData
            .friendRequests));

        if (cancelledFriendRequests.length > 0) {
          const userId = context.params.userId;

          for (const friendId of cancelledFriendRequests) {
            // Get the user document
            const playerDocRef = admin.firestore().collection("users")
                .doc(friendId);
            const playerDoc = await playerDocRef.get();
            const playerToken = playerDoc.data().token || null;

            // Send a notification to the player
            const message = {
              "notification": {
                "title": "Friend request cancelled",
                "body": "A friend request has been cancelled",
              },
              "data": {
                "notificationType": "friendRequestCancelled",
              },
              "token": playerToken,
            };

            await admin.messaging().send(message);

            await admin.firestore().collection("users").doc(friendId).update({
              [`friendRequests.${userId}`]: admin.firestore.FieldValue.delete(),
              triggeredByFunction: true, // Set the trigger flag
            });
          }
        }
      }

      return null;
    });

// Triggered when a friend request is accepted
exports.acceptFriendRequest = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      const oldData = change.before.data();
      const newData = change.after.data();

      // Check if the function has been triggered by our own update
      if (newData.triggeredByFunction) {
        // Reset the trigger flag in the document
        await admin.firestore().collection("users")
            .doc(context.params.userId).update({
              triggeredByFunction: admin.firestore.FieldValue.delete(),
            });
        // Skip this function execution
        return null;
      }

      // Check if the action performer is the user himself
      if (newData.actionPerformer && newData
          .actionPerformer === context.params.userId) {
        return null; // The user performed the action himself,
        // so skip this execution
      }

      if (oldData.friends.length !== newData.friends.length) {
        const addedFriends = newData.friends
            .filter((friend) => !oldData.friends.includes(friend));

        if (addedFriends.length > 0) {
          const userId = context.params.userId;

          for (const friendId of addedFriends) {
            // Get the user document
            const playerDocRef = admin.firestore().collection("users")
                .doc(friendId);
            const playerDoc = await playerDocRef.get();
            const playerToken = playerDoc.data().token || null;

            // Send a notification to the player receiving the invite
            const message = {
              "notification": {
                "title": "Friend request accepted",
                "body": "Your friend request has been accepted",
              },
              "data": {
                "notificationType": "friendRequestAccepted",
              },
              "token": playerToken,
            };

            await admin.messaging().send(message);

            try {
            // Add the friend who accepted the request to the user's friends
            // and delete the friend request
              await admin.firestore().collection("users")
                  .doc(friendId).update({
                    friends: admin.firestore.FieldValue.arrayUnion(userId),
                    [`friendRequests.${userId}`]: admin.firestore
                        .FieldValue.delete(),
                    triggeredByFunction: true, // Set the trigger flag
                  });
            } catch (err) {
              console.log("Error updating document", err);
            }
          }
        }
      }

      return null;
    });

// Triggered when a friend request is rejected
exports.rejectFriendRequest = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      const oldData = change.before.data();
      const newData = change.after.data();

      // Check if the function has been triggered by our own update
      if (newData.triggeredByFunction) {
        // Reset the trigger flag in the document
        await admin.firestore().collection("users")
            .doc(context.params.userId).update({
              triggeredByFunction: admin.firestore.FieldValue.delete(),
            });
        // Skip this function execution
        return null;
      }

      // Check if the action performer is the user himself
      if (newData.actionPerformer && newData
          .actionPerformer === context.params.userId) {
        return null; // The user performed the action himself,
        // so skip this execution
      }

      if (Object.keys(oldData.friendRequests)
          .length !== Object.keys(newData.friendRequests).length) {
        const removedFriendRequests = Object.keys(oldData
            .friendRequests).filter((friend) => !(friend in newData
            .friendRequests));

        if (removedFriendRequests.length > 0) {
          const userId = context.params.userId;

          for (const friendId of removedFriendRequests) {
            // Check if the friend request was accepted or rejected
            if (newData.friends.includes(friendId)) {
              // The request was accepted, not rejected
              continue;
            }

            // Get the user document
            const playerDocRef = admin.firestore().collection("users")
                .doc(friendId);
            const playerDoc = await playerDocRef.get();
            const playerToken = playerDoc.data().token || null;

            // Send a notification to the player
            const message = {
              "notification": {
                "title": "Friend request rejected",
                "body": "Your friend request has been rejected",
              },
              "data": {
                "notificationType": "friendRequestRejected",
              },
              "token": playerToken,
            };

            await admin.messaging().send(message);

            await admin.firestore().collection("users").doc(friendId).update({
              [`friendRequests.${userId}`]: admin.firestore.FieldValue.delete(),
              triggeredByFunction: true, // Set the trigger flag
            });
          }
        }
      }

      return null;
    });

// Triggered when a friend is removed
exports.removeFriend = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      const oldData = change.before.data();
      const newData = change.after.data();

      // Check if the function has been triggered by our own update
      if (newData.triggeredByFunction) {
        // Reset the trigger flag in the document
        await admin.firestore().collection("users")
            .doc(context.params.userId).update({
              triggeredByFunction: admin.firestore.FieldValue.delete(),
            });
        // Skip this function execution
        return null;
      }

      // Check if the action performer is the user himself
      if (newData.actionPerformer && newData
          .actionPerformer === context.params.userId) {
        return null; // The user performed the action himself,
        // so skip this execution
      }
      if (oldData.friends.length !== newData.friends.length) {
        const removedFriends = oldData.friends
            .filter((friend) => !newData.friends.includes(friend));

        if (removedFriends.length > 0) {
          const userId = context.params.userId;

          for (const friendId of removedFriends) {
          // Get the user document
            const playerDocRef = admin.firestore().collection("users")
                .doc(friendId);
            const playerDoc = await playerDocRef.get();
            const playerToken = playerDoc.data().token || null;

            await admin.firestore().collection("users").doc(friendId).update({
              friends: admin.firestore.FieldValue.arrayRemove(userId),
              triggeredByFunction: true, // Set the trigger flag
            });

            // Send a notification to the player receiving the invite
            const message = {
              "notification": {
                "title": "Friend deleted",
                "body": "A friend has been removed",
              },
              "data": {
                "notificationType": "friendRemoved",
              },
              "token": playerToken,
            };

            await admin.messaging().send(message);
          }
        }
      }

      return null;
    });


exports.checkPlayersAndDeleteGame = functions.firestore
    .document("games/{gameId}")
    .onUpdate((change, context) => {
      const newValue = change.after.data();
      const players = newValue.players;

      // Si le tableau "players" est vide, supprimer le document
      if (Object.keys(players).length === 0) {
        return admin.firestore().collection("games").doc(context.params.gameId)
            .delete();
      } else {
        console.log("Players array is not empty.");
        return null;
      }
    });

exports.determineWinner = functions.firestore
    .document("games/{gameId}")
    .onUpdate((change, context) => {
      const newValue = change.after.data();
      const previousValue = change.before.data();

      if (newValue.final_scores !== previousValue.final_scores) {
        const finalScores = newValue.final_scores;
        const players = newValue.players;

        if (Object.keys(finalScores).length === players.length) {
          let maxScore = -Infinity;
          let winnerUserId = null;
          for (const userId in finalScores) {
            if (finalScores[userId] > maxScore) {
              maxScore = finalScores[userId];
              winnerUserId = userId;
            }
          }

          const gameRef = admin.firestore().collection("games")
              .doc(context.params.gameId);
          return gameRef.update({winner: winnerUserId});
        }
      }
      return null;
    });


exports.updateRank = functions.firestore
    .document("games/{gameId}")
    .onUpdate((change, context) => {
      const newValue = change.after.data();

      if (newValue.competitive && newValue.winner) {
        const finalScores = newValue.final_scores;
        const winnerUserId = newValue.winner;

        const winnerRef = admin.firestore().collection("users")
            .doc(winnerUserId);

        return admin.firestore().runTransaction(async (transaction) => {
          const winnerDoc = await transaction.get(winnerRef);
          if (!winnerDoc.exists) {
            throw new Error("Winner Document does not exist!");
          }

          // Store loser docs to update after all reads
          const loserDocs = [];

          for (const loserUserId in finalScores) {
            if (loserUserId !== winnerUserId) {
              const loserRef = admin.firestore()
                  .collection("users").doc(loserUserId);
              const loserDoc = await transaction.get(loserRef);
              if (!loserDoc.exists) {
                throw new Error("Loser Document does not exist!");
              }
              loserDocs.push({ref: loserRef, doc: loserDoc});
            }
          }

          // Update winner rank
          const newWinnerRank = winnerDoc.data().rank + 0.1;
          transaction.update(winnerRef, {rank: newWinnerRank});

          // Update loser ranks
          for (const {ref, doc} of loserDocs) {
            let newLoserRank = doc.data().rank - 0.1;
            if (newLoserRank < 0) {
              newLoserRank = 0;
            }
            transaction.update(ref, {rank: newLoserRank});
          }
        });
      }
      return null;
    });
