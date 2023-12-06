import 'package:flutter/material.dart';
import 'package:u_marked/reusable_widget/appBar.dart';

class adminClassList extends StatefulWidget {
  const adminClassList({Key? key}) : super(key: key);

  @override
  State<adminClassList> createState() => _adminClassListState();
}

class _adminClassListState extends State<adminClassList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: adminClassListAppBar(context),
     body: SafeArea(
       child: Placeholder(),
     ),
    );
  }
}
