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


const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendInviteNotification = functions.firestore
    .document("lobby/{lobbyId}")
    .onUpdate(async (change, context) => {
      // Obtain the list of invited players before and after the update
      const oldInvitedPlayers = change.before.data().invited_users;
      const newInvitedPlayers = change.after.data().invited_users;
      // Check if any players have been added
      const addedPlayers = newInvitedPlayers
          .filter((player) => !oldInvitedPlayers || !oldInvitedPlayers
              .includes(player));

      // If there are no new players, stop the function here
      if (addedPlayers.length === 0) return null;

      // For each added player, add the lobbyID to their invites array
      for (const playerId of addedPlayers) {
        // Get the user document
        const playerDocRef = admin.firestore().collection("users")
            .doc(playerId);
        const playerDoc = await playerDocRef.get();
        const playerInvites = playerDoc.data().invites || [];
        try {
          // Add the lobbyID to the user's invites array
          playerInvites.push(context.params.lobbyId);

          // Update the invites array in the user document
          await playerDocRef.update({
            invites: playerInvites,
          });
        } catch (error) {
          console.error("Error updating user invites:", error);
          return null; // Stop execution in case of error
        }

        // Get the FCM token of the player
        const playerToken = playerDoc.data().fcmToken;
        const playerIdref = playerId;
        if (!playerToken) {
          console.error("Invalid FCM token for player:", playerIdref);
          continue; // Skip this iteration of the loop
        }
        // Prepare the notification
        const message = {
          notification: {
            title: "Nouvelle invitation",
            body: "Vous avez ete invite a rejoindre un lobby",
          },
          token: playerToken,
        };
        try {
          // Send the notification
          await admin.messaging().send(message);
        } catch (error) {
          console.error("Error sending message:", error);
          // Check if the error is due to an invalid token
          if (error.code === "messaging/invalid-registration-token" ||
              error.code === "messaging/registration-token-not-registered") {
            // The token is invalid - remove it from your database
            try {
              // Remove the token from the user's tokens array
              const index = playerInvites.indexOf(playerToken);
              if (index !== -1) {
                playerInvites.splice(index, 1);
              }

              // Update the invites array in the user document
              await playerDocRef.update({
                invites: playerInvites,
              });
            } catch (updateError) {
              console.error("Error updating user invites:", updateError);
            }
          }
        }
      }

      return null;
    });
