import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:u_marked/models/userModel.dart';
import 'package:u_marked/screens/admin/adminHome.dart';
import 'package:u_marked/screens/home/homePage.dart';
import 'package:u_marked/screens/home/inbox.dart';
import 'package:u_marked/screens/home/settings.dart';
import '../class/myClass.dart';


class home extends StatefulWidget {
  const home({Key? key}) : super(key: key);

  @override
  State<home> createState() => _homeState();
}

class _homeState extends State<home> {

  @override
  void initState() {
    super.initState();
    User user = FirebaseAuth.instance.currentUser!;
    updateDataIfEmailVerified(user);
  }

  Future<void> updateDataIfEmailVerified(User user) async {
    var userCollection = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    var data = await userCollection.data() as Map<String, dynamic>;

    if(!(data['userType'] == 3)){
      while (!user.emailVerified) {
        await Future.delayed(const Duration(seconds: 10));
        await user.reload();
        user = FirebaseAuth.instance.currentUser!;

        if (user.emailVerified) {
          await updateFirestoreData(user);
          // print('Email verified. Updating Firestore data.');
          break;
        } else {
          // print('Email not verified. Waiting...');
        }
      }
    }
  }

  Future<void> updateFirestoreData(User user) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'isEmailVerified': true,
    });
  }

  int _currentIndex = 0;
  List pages = [
    homePage(),
    inboxPage(),
    SettingsPage(),
  ];
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inbox),
              label: 'Inbox',
            ),
          ],
          onTap: (int newIndex){
            // print('new index ->>>>$newIndex');
            setState(() {
              _currentIndex = newIndex;
            });
          }
      ),
    );
  }
}
