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
      console.log("Function started.");
      const oldData = change.before.data();
      const newData = change.after.data();


      if (Object.keys(oldData.friendRequests || {}).length !==
        Object.keys(newData.friendRequests || {}).length) {
        console.log("Number of friend requests changed.");

        const addedFriendRequests = Object.keys(newData.friendRequests || {})
            .filter((friendId) => {
              return !(friendId in (oldData.friendRequests || {})) &&
            newData.friendRequests[friendId].status === "sent";
            });

        console.log(`Added friend requests:
${JSON.stringify(addedFriendRequests)}`);

        for (const friendId of addedFriendRequests) {
          if (newData.friends && newData.friends.includes(friendId)) {
            console.log(`Already friends with ${friendId}`);
            continue;
          }

          if (newData.friendRequests && newData.friendRequests[friendId] &&
            newData.friendRequests[friendId].status === "received") {
            console.log(`Already received a request from ${friendId}`);
            continue;
          }

          const friendDocRef = admin.firestore()
              .collection("users").doc(friendId);
          const friendDoc = await friendDocRef.get();
          const friendData = friendDoc.data();

          if (!friendDoc.exists) {
            console.log(`User with id ${friendId} does not exist.`);
            continue;
          }

          console.log(`Found user ${friendId}, updating friendRequests.`);
          const friendToken = friendData.token || null;
          const friendRequest = {
            status: "received",
            date: admin.firestore.Timestamp.now(),
          };

          await friendDocRef.update({
            [`friendRequests.${context.params.userId}`]: friendRequest,
          });
          console.log(`Request sent to ${friendId}.`);

          const message = {
            "notification": {
              "title": "New friend request",
              "body": `You received a request from ${newData.username}.`,
            },
            "data": {
              "notificationType": "friendRequest",
            },
            "token": friendToken,
          };

          await admin.messaging().send(message);
          console.log(`Notification sent to ${friendId}.`);
        }
      } else {
        console.log("No change in number of requests. Exiting function.");
      }

      return null;
    });


exports.cancelFriendRequest = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      console.log("Function started."); // Initial log

      const oldData = change.before.data();
      const newData = change.after.data();
      const userId = context.params.userId;

      console.log(`Context userId: ${userId}`);
      console.log(`OldData: ${JSON.stringify(oldData)}`);
      console.log(`NewData: ${JSON.stringify(newData)}`);


      if (Object.keys(oldData.friendRequests).length !== Object
          .keys(newData.friendRequests).length) {
        console.log("Number of friend requests changed."); // Log

        const cancelledFriendRequests = Object.keys(oldData.friendRequests)
            .filter((friend) => !(friend in newData.friendRequests));

        console.log(`Cancelled friend requests:
 ${JSON.stringify(cancelledFriendRequests)}`); // Log

        if (cancelledFriendRequests.length > 0) {
          for (const friendId of cancelledFriendRequests) {
            console.log(`Processing cancelled request for friendId:
 ${friendId}`);

            // Use Firestore transaction
            await admin.firestore().runTransaction(async (transaction) => {
              const friendDocRef = admin.firestore().collection("users")
                  .doc(friendId);
              const friendDoc = await transaction.get(friendDocRef);

              console.log(`Friend doc exists: ${friendDoc.exists}`);

              if (friendDoc.exists && friendDoc.data().friends
                  .includes(userId)) {
                console.log(`Friend request from ${friendId}
 has already been accepted.`); // Log
                return;
              }

              const friendToken = friendDoc.data().token || null;

              // Send notification
              const message = {
                "notification": {
                  "title": "Friend request cancelled",
                  "body": "A friend request has been cancelled",
                },
                "data": {
                  "notificationType": "friendRequestCancelled",
                },
                "token": friendToken,
              };

              await admin.messaging().send(message);

              console.log(`Notification sent to ${friendId}.`);
              // Log

              // Update friend's document within the transaction
              transaction.update(friendDocRef, {
                [`friendRequests.${userId}`]: admin.firestore
                    .FieldValue.delete(),
                // Define who performed the action
              });

              console.log(`Deleted friend request
from ${userId} for ${friendId}.`); // Log
            });
          }
        }
      }
      console.log("Function execution finished."); // Final log
      return null;
    });


exports.acceptFriendRequest = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      console.log("Function acceptFriendRequest started."); // Log ajouté

      const oldData = change.before.data();
      const newData = change.after.data();
      const userId = context.params.userId;


      if (oldData.friends.length !== newData.friends.length) {
        const addedFriends = newData.friends.filter((friend) => !oldData
            .friends.includes(friend));

        if (addedFriends.length > 0) {
          console.log(`New friends added: ${JSON.stringify(addedFriends)}`);
          // Log ajouté

          for (const friendId of addedFriends) {
            const friendDocRef = admin.firestore().collection("users")
                .doc(friendId);

            await admin.firestore().runTransaction(async (transaction) => {
              const friendDoc = await transaction.get(friendDocRef);
              if (!friendDoc.exists) {
                console.log(`Friend document for ${friendId} does not exist.
 Exiting.`); // Log ajouté
                return;
              }

              const friendData = friendDoc.data();
              if (!friendData.friendRequests || !(userId in friendData
                  .friendRequests)) {
                console.log(`Friend request from ${userId} to ${friendId}
 has been cancelled. Exiting.`); // Log existant
                return;
              }

              console.log(`Processing friend request acceptance
from ${userId} to ${friendId}.`); // Log ajouté

              const friendToken = friendData.token || null;
              const message = {
                "notification": {
                  "title": "Friend request accepted",
                  "body": "Your friend request has been accepted",
                },
                "data": {
                  "notificationType": "friendRequestAccepted",
                },
                "token": friendToken,
              };

              await admin.messaging().send(message);
              console.log(`Notification sent to ${friendId}.`); // Log ajouté


              transaction.update(friendDocRef, {
                friends: admin.firestore.FieldValue.arrayUnion(userId),
                [`friendRequests.${userId}`]: admin
                    .firestore.FieldValue.delete(),
              });

              console.log(`Successfully updated friend
 document for ${friendId}.`); // Log ajouté
            });
          }
        }
      }

      console.log("Function acceptFriendRequest finished."); // Log ajouté
      return null;
    });


exports.rejectFriendRequest = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      const oldData = change.before.data();
      const newData = change.after.data();
      const userId = context.params.userId;


      if (Object.keys(oldData.friendRequests).length !== Object
          .keys(newData.friendRequests).length) {
        const removedFriendRequests = Object.keys(oldData.friendRequests)
            .filter((friend) => !(friend in newData.friendRequests));

        if (removedFriendRequests.length > 0) {
          for (const friendId of removedFriendRequests) {
            if (newData.friends.includes(friendId)) {
              continue; // La demande a été acceptée, pas rejetée
            }

            const friendDocRef = admin.firestore().collection("users")
                .doc(friendId);

            // Utiliser une transaction pour mettre à jour le document de l'ami
            await admin.firestore().runTransaction(async (transaction) => {
              const friendDoc = await transaction.get(friendDocRef);
              if (!friendDoc.exists) {
                return;
              }

              const friendData = friendDoc.data();
              const friendToken = friendData.token || null;

              const message = {
                "notification": {
                  "title": "Friend request rejected",
                  "body": "Your friend request has been rejected",
                },
                "data": {
                  "notificationType": "friendRequestRejected",
                },
                "token": friendToken,
              };

              await admin.messaging().send(message);

              // Supprimer la demande d'ami du document de l'ami

              transaction.update(friendDocRef, {
                [`friendRequests.${userId}`]: admin.firestore
                    .FieldValue.delete(),
                // Définir qui a effectué l'action
              });
            });
          }
        }
      }
      return null;
    });


exports.removeFriend = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      const oldData = change.before.data();
      const newData = change.after.data();
      const userId = context.params.userId;


      if (oldData.friends.length !== newData.friends.length) {
        const removedFriends = oldData.friends
            .filter((friend) => !newData.friends.includes(friend));

        if (removedFriends.length > 0) {
          for (const friendId of removedFriends) {
            const friendDocRef = admin.firestore()
                .collection("users").doc(friendId);

            // Utiliser une transaction pour garantir la cohérence des données
            await admin.firestore().runTransaction(async (transaction) => {
              const friendDoc = await transaction.get(friendDocRef);
              if (!friendDoc.exists) {
                return;
              }

              const friendData = friendDoc.data();
              const friendToken = friendData.token || null;

              // Supprimer l'ami de la liste de l'utilisateur
              transaction.update(friendDocRef, {
                friends: admin.firestore.FieldValue.arrayRemove(userId),
              });


              // Envoyer une notification à l'ami
              const message = {
                "notification": {
                  "title": "Friend deleted",
                  "body": "A friend has been removed",
                },
                "data": {
                  "notificationType": "friendRemoved",
                },
                "token": friendToken,
              };

              await admin.messaging().send(message);

              // Retirer l'ami de tous les groupes
              // Attention, cela n'utilise pas de transactions,
              // donc ce pourrait être une opération séparée
              const groupQuerySnapshot = await admin.firestore()
                  .collection("groups")
                  .where("members", "array-contains", userId).get();

              const batch = admin.firestore().batch();

              groupQuerySnapshot.forEach((groupDoc) => {
                const groupDocRef = admin.firestore()
                    .collection("groups").doc(groupDoc.id);
                batch.update(groupDocRef, {
                  members: admin.firestore.FieldValue
                      .arrayRemove(friendId),
                });
              });

              await batch.commit();
            });
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
        return admin.firestore().collection("games")
            .doc(context.params.gameId)
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
          const newWinnerRank = winnerDoc.data().rank + 1;
          // if (newWinnerRank > 60) {
          //  newWinnerRank = 60;
          // }
          transaction.update(winnerRef, {rank: newWinnerRank});


          // Update loser ranks
          for (const {ref, doc} of loserDocs) {
            let newLoserRank = doc.data().rank - 1;
            if (newLoserRank < 0) {
              newLoserRank = 0;
            }
            transaction.update(ref, {rank: newLoserRank});
          }
        });
      }
      return null;
    });
