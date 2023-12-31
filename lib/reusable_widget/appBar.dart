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

GFAppBar classDetailsAppBar(String className,String lecturerID, String classID, BuildContext context){
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => memberList(classID: classID, lecturerID: lecturerID,),
          ),
        );
      },
      type: GFButtonType.transparent,
    )
    ],
  );
}

GFAppBar memberListAppBar = GFAppBar(
  centerTitle: true,
  elevation: 0,
  // automaticallyImplyLeading: false,
  flexibleSpace: Container(
    decoration: myClassAppBarBackgroundDecoration,
  ),
  title: Text("Member List"),
);

GFAppBar chatroomAppBar(String userName) {
  return GFAppBar(
    centerTitle: true,
    elevation: 0,
    // automaticallyImplyLeading: false,
    flexibleSpace: Container(
      decoration: myClassAppBarBackgroundDecoration,
    ),
    title: Text(userName),
  );
}

GFAppBar inboxAppBar = GFAppBar(
  centerTitle: true,
  elevation: 0,
  // automaticallyImplyLeading: false,
  flexibleSpace: Container(
    decoration: myClassAppBarBackgroundDecoration,
  ),
  title: Text("Inbox"),
);
