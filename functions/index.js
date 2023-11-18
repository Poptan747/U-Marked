const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.onAuthStateChanged = functions.auth.user().onCreate(async (user) => {
  const uid = user.uid;
  await admin.database().ref(`/userSessions/${uid}`).set({ [user.uid]: true });
});

exports.onUserSignOut = functions.auth.user().onDelete(async (user) => {
  const uid = user.uid;
  await admin.database().ref(`/userSessions/${uid}`).remove();
});
