import 'package:flutter/material.dart';

BottomNavigationBar bottomNavigationBar = BottomNavigationBar(
  items: [
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
    print(newIndex);

  }
);