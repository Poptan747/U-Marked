import 'package:flutter/material.dart';

class memberList extends StatefulWidget {
  const memberList({Key? key, required this.classID}) : super(key: key);
  final String classID;

  @override
  State<memberList> createState() => _memberListState();
}

class _memberListState extends State<memberList> {

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async{
    
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder(color: Colors.greenAccent,);
  }
}
