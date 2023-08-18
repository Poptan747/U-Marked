import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:u_marked/reusable_widget/alertDialog.dart';
import 'package:u_marked/screens/classList.dart';
import '../reusable_widget/gradientBackground.dart';

class homePage extends StatefulWidget {
  const homePage({Key? key}) : super(key: key);

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  String _name = '';
  String _studentID = '';
  String _lecturerID = '';
  String _batch = '';
  var _isStudent = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async{
    final user = FirebaseAuth.instance.currentUser!;
    final userCollection = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = await userCollection.data() as Map<String, dynamic>;
    if(data['userType'] == 1){
      _isStudent = true;
    }else{
      _isStudent = false;
    }
    final userData = await FirebaseFirestore.instance
        .collection(_isStudent? 'students' : 'lecturers').doc(user.uid).get();

    if(userData.exists) {
      final data = await userData.data() as Map<String, dynamic>;
      setState(() {
        _name = data['name'];
        if(_isStudent){
          _studentID = data['studentID'];
          _batch = data['batch'];
        }else{
          _lecturerID = data['lecturerID'];
        }
      });
    }else{
      print('User data not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Container(
          decoration: homeBackgroundDecoration,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 11, 8, 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hello,', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold,)),
                            Text(_name!,
                                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold,)),
                            SizedBox(height: 4,),
                            Text(_isStudent? _studentID! : _lecturerID,style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(_batch!,style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(onPressed: (){
                              // FirebaseAuth.instance.signOut();
                              Alerts().logoutAlertDialog(context);
                            },
                              icon: Icon(Icons.logout,size: 40,),
                              color: Colors.white,
                            ),
                            const Text('Logout',style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10,),
                  Row(
                    children: [
                      Flexible(
                        child: Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.8,
                            child: Container(
                              height: 70,
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      IconButton(onPressed: (){
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => UserOrdersDisplay(),
                                          ),
                                        );
                                      },
                                        icon: Icon(Icons.school),
                                        color: Colors.blue.shade900,),
                                      const Expanded(child: Text('My Class'))
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      IconButton(onPressed: (){}, icon: Icon(Icons.history_edu),color: Colors.blue.shade900),
                                      const Expanded(child: Text('My Attendance'))
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      IconButton(onPressed: (){}, icon: Icon(Icons.apps),color: Colors.blue.shade900),
                                      const Expanded(child: Text('Quick-tools'))
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Flexible(
                        child: Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.9,
                            child: Container(
                                height: 510,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                  color: Colors.white,
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                        color: Colors.black54,
                                        blurRadius: 10.0,
                                        offset: Offset(0.0, 0.75)
                                    )
                                  ],
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 50,
                                              decoration: const BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius: BorderRadius.all(Radius.circular(3)),
                                              ),
                                              child: const Padding(
                                                padding: EdgeInsets.fromLTRB(8, 13, 8, 8),
                                                child: Text('Recent Attendance',style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          Column(
                                            children: [
                                              GFListTile(
                                                  padding: EdgeInsets.all(20),
                                                  avatar:GFAvatar(
                                                    backgroundImage: AssetImage('images/location/IEB.jpg'),
                                                  ),
                                                  titleText:'BGEN1013 Academic English',
                                                  subTitleText:'10.00am-12-00am, 13/7/2023',
                                                  color: Colors.white,
                                                  icon: Icon(Icons.keyboard_double_arrow_right)
                                              ),
                                              GFListTile(
                                                  padding: EdgeInsets.all(20),
                                                  avatar:GFAvatar(
                                                    backgroundImage: AssetImage('images/location/IEB.jpg'),
                                                  ),
                                                  titleText:'BGEN1013 Academic English',
                                                  subTitleText:'10.00am-12-00am, 13/7/2023',
                                                  color: Colors.white,
                                                  icon: Icon(Icons.keyboard_double_arrow_right)
                                              ),
                                              GFListTile(
                                                  padding: EdgeInsets.all(20),
                                                  avatar:GFAvatar(
                                                    backgroundImage: AssetImage('images/location/IEB.jpg'),
                                                  ),
                                                  titleText:'BGEN1013 Academic English',
                                                  subTitleText:'10.00am-12-00am, 13/7/2023',
                                                  color: Colors.white,
                                                  icon: Icon(Icons.keyboard_double_arrow_right)
                                              ),
                                              GFListTile(
                                                  padding: EdgeInsets.all(20),
                                                  avatar:GFAvatar(
                                                    backgroundImage: AssetImage('images/location/IEB.jpg'),
                                                  ),
                                                  titleText:'BGEN1013 Academic English',
                                                  subTitleText:'10.00am-12-00am, 13/7/2023',
                                                  color: Colors.white,
                                                  icon: Icon(Icons.keyboard_double_arrow_right)
                                              ),
                                              GFListTile(
                                                  padding: EdgeInsets.all(20),
                                                  avatar:GFAvatar(
                                                    backgroundImage: AssetImage('images/location/IEB.jpg'),
                                                  ),
                                                  titleText:'BGEN1013 Academic English',
                                                  subTitleText:'10.00am-12-00am, 13/7/2023',
                                                  color: Colors.white,
                                                  icon: Icon(Icons.keyboard_double_arrow_right)
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10)
                ],
              ),
            ),
          ),
        ),
    );
  }
}