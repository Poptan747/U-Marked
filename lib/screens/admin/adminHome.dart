import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:u_marked/reusable_widget/alertDialog.dart';
import 'package:u_marked/reusable_widget/gradientBackground.dart';
import 'package:u_marked/screens/admin/locationManagement/locationList.dart';
import 'package:u_marked/screens/admin/userManagement/list.dart';

class adminHome extends StatefulWidget {
  const adminHome({Key? key}) : super(key: key);

  @override
  State<adminHome> createState() => _adminHomeState();
}

class _adminHomeState extends State<adminHome> {
  String _name='';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async{
    var user = FirebaseAuth.instance.currentUser!;
    var userCollection = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    var data = await userCollection.data() as Map<String, dynamic>;

    setState(() {
      _name = data['name'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:SafeArea(
        child: Container(
          decoration: homeBackgroundDecoration,
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 11, 8, 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10,10,10,10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.blueAccent,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hello,', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold,)),
                              Text(_name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold,)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: (){
                                Alerts().logoutAlertDialog(context);
                              },
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.blueAccent,
                                child: Column(
                                  children: [
                                    IconButton(onPressed: (){},
                                      icon: const Icon(Icons.logout,size: 30,),
                                      padding: const EdgeInsets.fromLTRB(6,20,0,0),
                                      highlightColor: Colors.amber,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 10,),
                                    const Text('Logout',style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white,thickness: 3,),
                  const SizedBox(height: 30,),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10,10,10,10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      // color: Colors.blue.shade50,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: ()=>{
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => userManagementList(),
                                ),
                              )
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: const [
                                Text('User Management',style: TextStyle(fontSize: 30),),
                                SizedBox(width: 10,),
                                Icon(Icons.supervised_user_circle),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40,),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: ()=>{},
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: const [
                                Text('Class Management',style: TextStyle(fontSize: 30),),
                                SizedBox(width: 10,),
                                Icon(Icons.school),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40,),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: ()=>{},
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: const [
                                Text('Attendance Management',style: TextStyle(fontSize: 30),),
                                SizedBox(width: 10,),
                                Icon(Icons.how_to_reg),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40,),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: ()=>{
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => locationList(),
                                ),
                              )
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: const [
                                Text('Location Management',style: TextStyle(fontSize: 30),),
                                SizedBox(width: 10,),
                                Icon(Icons.location_city),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
