import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:getwidget/getwidget.dart';
import 'package:u_marked/models/userModel.dart';
import 'package:u_marked/reusable_widget/alertDialog.dart';
import 'package:u_marked/reusable_widget/appBar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User _user;

  bool _isStudent = false;
  bool _isEmailVerify = false;
  bool _isPhoneVerify = false;
  String _name = '';
  String _studentID = '';
  String _batch = '';
  String _lecturerID = '';
  String _email = '';
  String _phoneNum = '';
  String _imageUrl = 'https://firebasestorage.googleapis.com/v0/b/u-marked.appspot.com/o/user_images%2FikKc94gdIZVnebd8PDwCBvFho3D3.jpg?alt=media&token=8ae73d60-a706-498d-a44e-671d4669f5ec';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async{
    var user = FirebaseAuth.instance.currentUser!;
    if(user.phoneNumber == null || user.phoneNumber!.isEmpty){
      _isPhoneVerify = false;
    }
    var userCollection = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    var data = await userCollection.data() as Map<String, dynamic>;

    UserDetail newUser = UserDetail(uid: user.uid, email: data['email'], userType: data['userType']);
    Map<String, dynamic> userDetailmap = await newUser.getUserDetail();

    if(userDetailmap['userType'] == 1){
      _isStudent = true;
    }else{
      _isStudent = false;
    }

    setState(() {
      _name = userDetailmap['name'];
      _studentID = userDetailmap['studentID'];
      _batch = userDetailmap['batch'];
      _lecturerID = userDetailmap['lecturerID'];
      _email = data['email'];
      _phoneNum = data['phoneNum'];
      _imageUrl = data['imagePath'];
      _isEmailVerify = user.emailVerified;
    });
  }

  void sendEmailVerify() async{
    User? user = FirebaseAuth.instance.currentUser;
    await user?.sendEmailVerification();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: profilePageAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.blue.shade900,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(_imageUrl)
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_name,style: whiteTextStyle),
                              Text(_isStudent? _studentID : _lecturerID,style: whiteTextStyle),
                              Text(_batch,style: whiteTextStyle),
                              Text(_email,style: whiteTextStyle),
                              Text(_phoneNum,style: whiteTextStyle),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.lightBlue.shade50,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Badge(
                          label: Text('  '),
                          backgroundColor: _isEmailVerify? Colors.green : Colors.red,
                          child: GFButton(
                            padding: const EdgeInsets.symmetric(horizontal: 90),
                            text: "Email Verification",
                            icon: const Icon(Icons.email_outlined,color: Colors.blueAccent),
                            shape: GFButtonShape.pills,
                            type: GFButtonType.outline,
                            size: GFSize.LARGE,
                            onPressed: (){
                              if(!_isEmailVerify){
                                sendEmailVerify();
                              }
                              Alerts().emailVerificationDialog(context, _isEmailVerify, _email);
                            },
                          ),
                        ),
                        Badge(
                          label: Text('  '),
                          backgroundColor: _isPhoneVerify? Colors.green : Colors.red,
                          child: GFButton(
                            padding: const EdgeInsets.symmetric(horizontal: 90),
                            text: "Phone Verification",
                            icon: const Icon(Icons.phone_android_outlined,color: Colors.blueAccent),
                            shape: GFButtonShape.pills,
                            type: GFButtonType.outline,
                            size: GFSize.LARGE,
                            onPressed: (){

                            },
                          ),
                        ),
                        GFButton(
                          padding: const EdgeInsets.symmetric(horizontal: 90),
                          text: "Edit Profile",
                          icon: const Icon(Icons.edit_outlined,color: Colors.blueAccent),
                          shape: GFButtonShape.pills,
                          type: GFButtonType.outline,
                          size: GFSize.LARGE,
                          onPressed: (){

                          },
                        ),
                        GFButton(
                          padding: const EdgeInsets.symmetric(horizontal: 90),
                          text: "Logout",
                          icon: const Icon(Icons.logout_outlined,color: Colors.redAccent),
                          shape: GFButtonShape.pills,
                          type: GFButtonType.outline,
                          color: Colors.red,
                          size: GFSize.LARGE,
                          onPressed: (){
                            Alerts().logoutAlertDialog(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
    );
  }

  static const TextStyle whiteTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );
}
