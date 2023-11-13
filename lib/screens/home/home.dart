import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:u_marked/models/userModel.dart';
import 'package:u_marked/screens/admin/adminHome.dart';
import 'package:u_marked/screens/home/homePage.dart';
import 'package:u_marked/screens/home/inbox.dart';
import 'package:u_marked/screens/home/settings.dart';
import '../myClass.dart';


class home extends StatefulWidget {
  const home({Key? key}) : super(key: key);

  @override
  State<home> createState() => _homeState();
}

class _homeState extends State<home> {

  @override
  void initState() {
    super.initState();
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
      body: pages[_currentIndex],
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
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
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
