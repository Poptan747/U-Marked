import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
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

