const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.onAuthStateChanged = functions.auth.user().onCreate(async (user) => {
  const uid = user.uid;
  await admin
    .database()
    .ref(`/userSessions/${uid}`)
    .set({ [user.uid]: true });
});

exports.onUserSignOut = functions.auth.user().onDelete(async (user) => {
  const uid = user.uid;
  await admin.database().ref(`/userSessions/${uid}`).remove();
});

exports.checkAttendanceStatus = functions.pubsub
  .schedule("every 5 minutes")
  .timeZone("Asia/Singapore")
  .onRun(async () => {
    try {
      const attendanceRecordsSnapshot = await admin
        .firestore()
        .collection("attendanceRecord")
        .get();

      attendanceRecordsSnapshot.forEach(async (attendanceRecord) => {
        const studentAttendanceListSnapshot = await attendanceRecord.ref
          .collection("studentAttendanceList")
          .get();

        studentAttendanceListSnapshot.forEach(async (studentAttendance) => {
          const attendanceStatus = studentAttendance.data().attendanceStatus;

          if (attendanceStatus === 0) {
            const studentAttendanceSessionSnapshot = await studentAttendance.ref
              .collection("studentAttendanceSession")
              .get();

            if (studentAttendanceSessionSnapshot.empty) {
              // No data in studentAttendanceSession, perform your logic here
              await studentAttendance.ref.update({ attendanceStatus: 2 });
              console.log("No data in studentAttendanceSession");
            } else {
              // Data exists in studentAttendanceSession, perform other logic if needed
              let sessionMatchFound = false;

              studentAttendanceSessionSnapshot.forEach((sessionDoc) => {
                const sessionData = sessionDoc.data();
                const startAtRecord = attendanceRecord.data().startAt;
                const startAtSession = sessionData.startAt;

                if (startAtRecord === startAtSession) {
                  // Match found, update sessionMatchFound
                  sessionMatchFound = true;
                }
              });

              // Set attendanceStatus based on sessionMatchFound
              const updatedAttendanceStatus = sessionMatchFound ? 4 : 3;

              // Update attendanceStatus in studentAttendanceList
              await studentAttendance.ref.update({
                attendanceStatus: updatedAttendanceStatus,
              });
              console.log(
                `Updated attendanceStatus to ${updatedAttendanceStatus} for document:`,
                studentAttendance.id
              );
            }
          }
        });
      });

      return null;
    } catch (error) {
      console.error("Error checking attendance status:", error);
      return null;
    }
  });
