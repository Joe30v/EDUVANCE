const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// This function runs on the server to reset the password securely
exports.resetPasswordWithAdmin = functions.https.onCall(async (data, context) => {
  const email = data.email;
  const newPassword = data.newPassword;

  // Security Note: In a production app, you should verify the OTP here on the server
  // before allowing the password change.

  try {
    // 1. Find the user by email
    const userRecord = await admin.auth().getUserByEmail(email);

    // 2. Force update the password using Admin SDK
    await admin.auth().updateUser(userRecord.uid, {
      password: newPassword,
    });

    return { success: true, message: "Password updated successfully" };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});