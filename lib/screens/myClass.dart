import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:u_marked/reusable_widget/appBar.dart';
import 'package:u_marked/reusable_widget/gradientBackground.dart';

class myClass extends StatefulWidget {
  const myClass({Key? key}) : super(key: key);

  @override
  State<myClass> createState() => _myClassState();
}

class _myClassState extends State<myClass> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myClassAppBar,
      body: SafeArea(
        child: Container(
          decoration: homeBackgroundDecoration,
          child: FractionallySizedBox(
            heightFactor: 1,
            child: Scrollbar(
              scrollbarOrientation: ScrollbarOrientation.right,
              radius: Radius.circular(10),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                      GFListTile(
                      padding: EdgeInsets.all(20),
                        avatar:GFAvatar(
                          backgroundImage: AssetImage('images/location/IEB.jpg'),
                          size: GFSize.LARGE,
                          shape: GFAvatarShape.standard,
                        ),
                        titleText:'BGEN1013 Academic English',
                        subTitleText:'10.00am-12-00am, 13/7/2023',
                        color: Colors.white,
                        icon: Icon(Icons.keyboard_double_arrow_right),
                        onTap: (){
                          print('tapped');
                        },
                    ),
                    GFListTile(
                      padding: EdgeInsets.all(20),
                      avatar:GFAvatar(
                        backgroundImage: AssetImage('images/location/IEB.jpg'),
                        size: GFSize.LARGE,
                        shape: GFAvatarShape.standard,
                      ),
                      titleText:'BGEN1013 Academic English',
                      subTitleText:'10.00am-12-00am, 13/7/2023',
                      color: Colors.white,
                      icon: Icon(Icons.keyboard_double_arrow_right),
                      onTap: (){
                        print('tapped');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
