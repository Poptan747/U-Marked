import 'dart:js';

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:u_marked/screens/memberList.dart';
import 'gradientBackground.dart';

GFAppBar myClassAppBar = GFAppBar(
  centerTitle: true,
  elevation: 0,
  // automaticallyImplyLeading: false,
  flexibleSpace: Container(
    decoration: myClassAppBarBackgroundDecoration,
  ),
  title: Text("My Class"),
  actions: [
    // GFIconButton(
    //   icon: Icon(
    //     Icons.account_circle_rounded,
    //     color: Colors.white,
    //   ),
    //   onPressed: () {},
    //   type: GFButtonType.transparent,
    // ),
  ],
);

GFAppBar classDetailsAppBar(String className,String classID){
  return GFAppBar(
    centerTitle: true,
    elevation: 0,
    //automaticallyImplyLeading: false,
    flexibleSpace: Container(
      decoration: myClassAppBarBackgroundDecoration,
    ),
    title: Text(className),
    actions: [
    GFIconButton(
      icon: Icon(
        Icons.people,
        color: Colors.white,
      ),
      onPressed: () {
        Navigator.of(context as BuildContext).push(
          MaterialPageRoute(
            builder: (context) => memberList(classID: classID),
          ),
        );
      },
      type: GFButtonType.transparent,
    )
    ],
  );
}

