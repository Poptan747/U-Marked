import 'package:flutter/material.dart';
import 'package:u_marked/reusable_widget/appBar.dart';
import 'package:u_marked/reusable_widget/gradientBackground.dart';
import 'package:u_marked/screens/admin/userManagement/allUserList.dart';
import 'package:u_marked/screens/admin/userManagement/lecturerList.dart';
import 'package:u_marked/screens/admin/userManagement/studentList.dart';

class userManagementList extends StatefulWidget {
  const userManagementList({Key? key}) : super(key: key);

  @override
  State<userManagementList> createState() => _userManagementListState();
}

class _userManagementListState extends State<userManagementList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: userManageListAppBar,
      body: Container(
        color: Colors.blue.shade800,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 11, 8, 8),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  height: 70,
                  child: ElevatedButton(
                    onPressed: ()=>{
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => studentList(),
                        ),
                      )
                    },
                    child: Text('Student List',style: TextStyle(fontSize: 30),),
                  ),
                ),
                SizedBox(
                  height: 70,
                  child: ElevatedButton(
                    onPressed: ()=>{
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => lecturerList(),
                        ),
                      )
                    },
                    child: Text('Lecturer List',style: TextStyle(fontSize: 30),),
                  ),
                ),
                SizedBox(
                  height: 70,
                  child: ElevatedButton(
                    onPressed: ()=>{
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => allUserList(),
                        ),
                      )
                    },
                    child: Text('All user List',style: TextStyle(fontSize: 30),),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
