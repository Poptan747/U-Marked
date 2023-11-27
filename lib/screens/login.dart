import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:u_marked/screens/home/home.dart';
import '../reusable_widget/gradientBackground.dart';

final _firebase = FirebaseAuth.instance;

class loginPage extends StatefulWidget {
  const loginPage({Key? key}) : super(key: key);

  @override
  State<loginPage> createState() => _loginPageState();
}

class _loginPageState extends State<loginPage> {
  final _form = GlobalKey<FormState>();
  var _enteredEmail;
  var _enteredPassword;
  String _errorMessage = '';

  void _submit() async{
    final isValid = _form.currentState!.validate();
    if(!isValid){
      return;
    }
    _form.currentState!.save();

    try{
      _errorMessage = '';
      bool canLogin = false;
      CollectionReference colRef = FirebaseFirestore.instance.collection('users');

      // Query the sessions collection for the user
      QuerySnapshot userSnapShot = await colRef.where('email', isEqualTo: _enteredEmail).get();

      if(userSnapShot.docs.isNotEmpty){
        // Check if the user can log in (no existing sessions)
        canLogin = await checkExistingSessions(userSnapShot.docs.first.id);
      }else{
        _errorMessage = 'User not found\n'
            'Please check your email and password again.';
        canLogin = false;
      }

      if (canLogin) {
        var _userCredentials = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword
        );
        String? token = await FirebaseMessaging.instance.getToken();
        // Associate the session token with the user in Firestore
        await createSession(_userCredentials.user!.uid, token!);

        var snackBar = const SnackBar(
          content: Text('Login successful!'),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => home(),
          ),
        );
      } else {
        // Deny the login attempt
        
        var snackBar = SnackBar(
          content: Text(_errorMessage.trim().isEmpty ? 'User already logged in from another device' : _errorMessage),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }on FirebaseAuthException catch(error){
      var snackBar = SnackBar(
        content: Text(error.message?? 'Auth failed'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  // Function to check existing sessions for a user
  Future<bool> checkExistingSessions(String userId) async {
    CollectionReference sessions = FirebaseFirestore.instance.collection('user_sessions');

    // Query the sessions collection for the user
    QuerySnapshot userSessions = await sessions.where('userId', isEqualTo: userId).get();

    // If there are existing sessions, decline the login
    if(userSessions.docs.isNotEmpty){
      return false;
    }
    return userSessions.docs.isEmpty;
  }

  // Create a new session for the user in Firestore
  Future<void> createSession(String userId, String sessionToken) async {
    FirebaseFirestore.instance.collection('user_sessions').doc(userId).set({
      'userId': userId,
      'sessionToken': sessionToken,
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; // Return false to prevent popping the page
      },
      child: Scaffold(
          body: SafeArea(
            child: Container(
              decoration: loginBackgroundDecoration,
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AspectRatio(
                          aspectRatio: 2.0,
                          child: Image.asset('images/U-Marked.png')
                      ),
                      Text('Login', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold,color: Colors.lightBlue.shade900),),
                      const SizedBox(height: 100),
                      Form(
                        key: _form,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              TextFormField(
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                    hintText: "Email",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    icon: const Icon(Icons.email)
                                ),
                                validator: (value){
                                  if(value == null || value.trim().isEmpty || !value.contains('@')){
                                    return 'Please enter a valid university email address!';
                                  }
                                },
                                onSaved: (value){
                                  _enteredEmail = value!;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: "Password",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  icon: const Icon(Icons.password),
                                ),
                                validator: (value){
                                  if(value == null || value.trim().isEmpty){
                                    return 'Please enter a valid password!';
                                  }
                                },
                                onSaved: (value){
                                  _enteredPassword = value!;
                                },
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  // Navigator.of(context).push(
                                  //   MaterialPageRoute(
                                  //     builder: (context) => const home(),
                                  //   ),
                                  // );
                                  _submit();
                                },
                                child: const Text('Login'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
      ),
    );
  }
}