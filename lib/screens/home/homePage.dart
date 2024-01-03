import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:u_marked/models/userModel.dart';
import 'package:u_marked/reusable_widget/alertDialog.dart';
import 'package:u_marked/screens/attendance/myAttendance.dart';
import 'package:u_marked/screens/class/classList.dart';
import 'package:u_marked/screens/home/recentAttendance.dart';
import 'package:u_marked/screens/profile/profilePage.dart';
import '../../reusable_widget/gradientBackground.dart';

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
  bool _isEmailVerify = false;
  bool _isPhoneVerify = false;
  var _isStudent = true;

  void setupPushNotification() async{
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();
    final token = await fcm.getToken();
    // print('TOKEN HERE');
    // print(token);
  }

  @override
  void initState() {
    super.initState();
    loadData();
    setupPushNotification();
  }

  loadData() async{
    var user = FirebaseAuth.instance.currentUser!;
    var userCollection = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    var data = await userCollection.data() as Map<String, dynamic>;

    UserDetail newUser = UserDetail(uid: user.uid, email: data['email'], userType: data['userType']);
    Map<String, dynamic> userDetailmap = await newUser.getUserDetail();

      setState(() {
        if(userDetailmap['userType'] == 1){
          _isStudent = true;
        }else{
          _isStudent = false;
        }
        _isEmailVerify = data['isEmailVerified'];
        _isPhoneVerify = data['isPhoneVerified'];
        _name = userDetailmap['name'];
        _studentID = userDetailmap['studentID'];
        _batch = userDetailmap['batch'];
        _lecturerID = userDetailmap['lecturerID'];
      });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                              Text('Hello, $_name', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold,)),
                              Text(_isStudent? _studentID! : _lecturerID,style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              _batch.trim().isNotEmpty ? Text(_batch!,style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)) : SizedBox(),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: IconButton(onPressed: (){
                            // FirebaseAuth.instance.signOut();
                            // Alerts().logoutAlertDialog(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ProfilePage(),
                              ),
                            );
                          },
                            icon: Icon(Icons.account_circle,size: 60,),
                            color: Colors.white,
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
                                        if(_isPhoneVerify && _isEmailVerify){
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => myClassList(),
                                            ),
                                          );
                                        }else{
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) => AlertDialog(
                                              title: const Text('Verify Account'),
                                              content: const Text('Please verify your account before proceeding'),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () async {
                                                    Navigator.pop(context);
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) => const ProfilePage(),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                        icon: Icon(Icons.school),
                                        color: Colors.blue.shade900,),
                                      Expanded(child: Text('My Class',style: Theme.of(context).textTheme.labelLarge))
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      IconButton(onPressed: (){
                                        if(_isPhoneVerify && _isEmailVerify){
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => MyAttendance(),
                                            ),
                                          );
                                        }else{
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) => AlertDialog(
                                              title: const Text('Verify Account'),
                                              content: const Text('Please verify your account before proceeding'),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () async {
                                                    Navigator.pop(context);
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) => const ProfilePage(),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      }, icon: Icon(Icons.history_edu),color: Colors.blue.shade900),
                                      Expanded(child: Text('My Attendance',style: Theme.of(context).textTheme.labelLarge))
                                    ],
                                  ),
                                  // Column(
                                  //   children: [
                                  //     IconButton(onPressed: (){}, icon: Icon(Icons.apps),color: Colors.blue.shade900),
                                  //     const Expanded(child: Text('Quick-tools'))
                                  //   ],
                                  // ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white,thickness: 3,),
                  const SizedBox(height: 20),
                  RecentAttendance(isStudent: _isStudent,isEmailVerify: _isEmailVerify,isPhoneVerify: _isPhoneVerify,)
                ],
              ),
            ),
          ),
        ),
    );
  }
}
