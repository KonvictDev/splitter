const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// This HTTPS callable function uses the FCM API (v1 payload format)
exports.sendNotification = functions.https.onCall(async (data, context) => {
  // Check if data is nested under a 'data' property.
  const payload = data.data || data;
  const {token, title, body} = payload;

  console.log("Received token:", token, "Type:", typeof token);

  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: token,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("Successfully sent message:", response);
    return {success: true, response: response};
  } catch (error) {
    console.error("Error sending message:", error);
    return {success: false, error: token};
  }
});

