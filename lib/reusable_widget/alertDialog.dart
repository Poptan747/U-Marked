import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:u_marked/main.dart';
import 'package:u_marked/screens/login.dart';


class Alerts {
  // Function to handle user logout
  Future<void> handleLogout(context) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Remove the session information from the database
      removeSession(user.uid, context);
    }
  }

// Function to remove session information from the database
  Future<void> removeSession(String userId, context) async {
    CollectionReference sessions = await FirebaseFirestore.instance.collection('user_sessions');

    // Delete the session information for the user
    await sessions.doc(userId).delete().then((value) => print('deleted'));
    // Sign out the user
    await FirebaseAuth.instance.signOut();

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout Successful'),
          behavior: SnackBarBehavior.floating,)
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MyApp(),
      ),
    );
  }

  void logoutAlertDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              handleLogout(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void emailVerificationDialog(context, isVerify, emailAddress) {

    const TextStyle blackTextStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.normal,
      color: Colors.black,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(32.0))),
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 15),
                !isVerify?
                Text('A verification email has been sent to :\n\n'
                    '$emailAddress\n\n'
                    'Please check your inbox.',textAlign: TextAlign.center,style: blackTextStyle,)
                :const Text('Your email has been verified.',textAlign: TextAlign.center,style: blackTextStyle,),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
        ),
      ),
    );
  }

  void timePickerAlertDialog(BuildContext context){
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            AlertDialog(
              title: const Text('Alert'),
              content: const Text('The "End at" time must be after "Start at" time'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'Ok'),
                  child: const Text('Ok'),
                ),
              ],
            ),
    );
  }

  void startAtFirstAlertDialog(BuildContext context){
    showDialog(
      context: context,
      builder: (BuildContext context) =>
          AlertDialog(
            title: const Text('Alert'),
            content: const Text('Please select "Start at" time first.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'Ok'),
                child: const Text('Ok'),
              ),
            ],
          ),
    );
  }
}
