const express = require('express');
const admin = require('firebase-admin');
const bodyParser = require('body-parser');
const cors = require('cors');

// 1. Initialize Firebase Admin
// Make sure you put your downloaded key file in the same folder and name it 'serviceAccountKey.json'
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const app = express();

// Allow connections from your Flutter app
app.use(cors());
app.use(bodyParser.json());

// 2. The Reset Password Endpoint
app.post('/reset-password', async (req, res) => {
  const { email, newPassword } = req.body;

  // Basic validation
  if (!email || !newPassword) {
    return res.status(400).send({ error: 'Email and password are required' });
  }

  try {
    // A. Find the user by their email
    const userRecord = await admin.auth().getUserByEmail(email);
    
    // B. Force update the password (Admin privilege)
    await admin.auth().updateUser(userRecord.uid, {
      password: newPassword
    });

    console.log(`✅ Success: Password updated for ${email}`);
    res.status(200).send({ success: true, message: 'Password updated successfully' });

  } catch (error) {
    console.error('❌ Error updating password:', error);
    res.status(500).send({ error: error.message });
  }
});

// 3. Start the Server
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`\n🚀 Server is running!`);
  console.log(`   Listening on port: ${PORT}`);
  console.log(`   Endpoint ready: http://localhost:${PORT}/reset-password\n`);
});