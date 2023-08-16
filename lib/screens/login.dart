import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  void _submit() async{
    final isValid = _form.currentState!.validate();
    if(!isValid){
      return;
    }
    _form.currentState!.save();

    try{
      final _userCredentials = await _firebase.signInWithEmailAndPassword(
          email: _enteredEmail, password: _enteredPassword
      );

      var snackBar = const SnackBar(
        content: Text('Login successful!'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      // print(_userCredentials);
    }on FirebaseAuthException catch(error){
      var snackBar = SnackBar(
        content: Text(error.message?? 'Auth failed'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    const SizedBox(height: 16),
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
                                print('pressed');
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
    );
  }
}