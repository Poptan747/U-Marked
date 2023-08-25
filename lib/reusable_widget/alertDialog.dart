import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class Alerts {
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
            onPressed: () => {
              FirebaseAuth.instance.signOut(),
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logout Successful'),
                  behavior: SnackBarBehavior.floating,)
                ),
              Navigator.pop(context, 'Ok')
            },
            child: const Text('Logout'),
          ),
        ],
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
