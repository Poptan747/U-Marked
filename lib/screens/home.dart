import 'package:flutter/material.dart';
import 'package:u_marked/screens/homePage.dart';
import 'package:u_marked/screens/inbox.dart';
import 'package:u_marked/screens/settings.dart';
import 'myClass.dart';


class home extends StatefulWidget {
  const home({Key? key}) : super(key: key);

  @override
  State<home> createState() => _homeState();
}

class _homeState extends State<home> {

  @override
  void initState() {
    super.initState();
    homePage();
  }

  int _currentIndex = 0;
  List pages = [
    homePage(),
    inboxPage(),
    settingsPage(),
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
