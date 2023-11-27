import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:getwidget/getwidget.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:u_marked/main.dart';
import 'package:u_marked/screens/login.dart';


class Alerts {
  // Function to handle user logout
  Future<void> handleLogout(context) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Remove the session information from the database
      removeSession(user.uid, context);
    }
  }

// Function to remove session information from the database
  Future<void> removeSession(String userId, context) async {
    CollectionReference sessions = await FirebaseFirestore.instance.collection('user_sessions');

    // Delete the session information for the user
    await sessions.doc(userId).delete().then((value) => print('deleted'));
    // Sign out the user
    await FirebaseAuth.instance.signOut();

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout Successful'),
          behavior: SnackBarBehavior.floating,)
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MyApp(),
      ),
    );
  }

  void logoutAlertDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              handleLogout(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void emailVerificationDialog(context, isVerify, emailAddress) {

    const TextStyle blackTextStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.normal,
      color: Colors.black,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(32.0))),
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 15),
                !isVerify?
                Text('A verification email has been sent to :\n\n'
                    '$emailAddress\n\n'
                    'Please check your inbox.',textAlign: TextAlign.center,style: blackTextStyle,)
                :const Text('Your email has been verified.',textAlign: TextAlign.center,style: blackTextStyle,),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
        ),
      ),
    );
  }

  void phoneVerificationDialog(context){
    final _form = GlobalKey<FormState>();
    var _enteredPhone;
    String _errorMessage = '';

    const TextStyle blackTextStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.normal,
      color: Colors.black,
    );

    void _submit() async{
      final isValid = _form.currentState!.validate();
      if(!isValid){
        return;
      }
      _form.currentState!.save();

      var phoneNum = _enteredPhone;
      FirebaseAuth auth = FirebaseAuth.instance;
      User? user = auth.currentUser;

      try {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: '+60164114385',
          verificationCompleted: (PhoneAuthCredential credential) {
            print('Completed');
          },
          verificationFailed: (FirebaseAuthException e) {
            print("ERROR HERE");
            print(e.message);
          },
          codeSent: (String verificationId, int? resendToken) {
            print('Verification ID: $verificationId');
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            print('TIME OUT');
          },
        );

      }on FirebaseAuthException catch (error){
        print("ERROR HERE");
        print(error.message);
      }

    }

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0))),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 15),
                const Text('Enter your phone number ',textAlign: TextAlign.center,style: blackTextStyle,),
                const SizedBox(height: 15),
                TextFormField(
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                      hintText: "012345678",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      icon: const Icon(Icons.phone)
                  ),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || value.trim().length > 15){
                      return 'Please enter a valid phone number!';
                    }
                  },
                  onSaved: (value){
                    _enteredPhone = value!;
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        _submit();
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void timePickerAlertDialog(BuildContext context){
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            AlertDialog(
              title: const Text('Alert'),
              content: const Text('The "End at" time must be after "Start at" time'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'Ok'),
                  child: const Text('Ok'),
                ),
              ],
            ),
    );
  }

  void startAtFirstAlertDialog(BuildContext context){
    showDialog(
      context: context,
      builder: (BuildContext context) =>
          AlertDialog(
            title: const Text('Alert'),
            content: const Text('Please select "Start at" time first.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'Ok'),
                child: const Text('Ok'),
              ),
            ],
          ),
    );
  }
}

class phoneVerificationDialog extends StatefulWidget {
  const phoneVerificationDialog({Key? key}) : super(key: key);

  @override
  State<phoneVerificationDialog> createState() => _phoneVerificationDialogState();
}

class _phoneVerificationDialogState extends State<phoneVerificationDialog> {

  final _form = GlobalKey<FormState>();
  FocusNode focusNode = FocusNode();
  var _enteredPhone;
  String _errorMessage = '';
  bool _isError = false;

  void _submit() async{
    _isError = false;
    _errorMessage = '';
    final isValid = _form.currentState!.validate();
    if(!isValid){
      return;
    }
    _form.currentState!.save();

    String phoneNum = _enteredPhone;
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if(phoneNum.trim().isEmpty){
      setState(() {
        _isError = true;
        _errorMessage = 'Please enter a valid phone number.';
      });
    }

    if(!_isError){
      Navigator.pop(context);
      showDialog(context: context, builder: (BuildContext context) {
        return verifyOTPDialog(phoneNum: phoneNum);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0))),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 15),
                const Text('Enter your phone number ',textAlign: TextAlign.center,
                  style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,),
                ),
                const SizedBox(height: 15),
                IntlPhoneField(
                  focusNode: focusNode,
                  disableLengthCheck: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  initialCountryCode: 'MY',
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(),
                    ),
                  ),
                  languageCode: "en",
                  validator: (phone){
                    if(phone!.completeNumber.contains('-') || phone!.completeNumber.contains(' ')){
                      return '"-" and empty spaces are not needed.';
                    }
                    if(phone.number.isEmpty || phone.number.length <5){
                      return 'Please enter a valid phone number.';
                    }
                  },
                  onSaved: (phone){
                    if(phone!.number.isNotEmpty){
                      _enteredPhone = phone!.completeNumber;
                    }else{
                      _enteredPhone = '';
                    }
                  },
                ),
                const SizedBox(height: 10),
                _errorMessage.trim().isNotEmpty ? Text(_errorMessage,style: const TextStyle(color: Colors.red))
                    : const SizedBox(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GFButton(
                      shape: GFButtonShape.pills,
                      size: GFSize.LARGE,
                        onPressed: (){
                          _submit();
                        },
                        text:"Submit"
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class verifyOTPDialog extends StatefulWidget {
  const verifyOTPDialog({Key? key, required this.phoneNum}) : super(key: key);

  final String phoneNum;

  @override
  State<verifyOTPDialog> createState() => _verifyOTPDialogState();
}

class _verifyOTPDialogState extends State<verifyOTPDialog> {

  String _errorMessage = '';
  bool _isError = false;
  bool _resendOTP = false;
  bool _isSent = false;
  String verifyOTPId = '';

  @override
  void initState() {
    super.initState();
    _resentOTP();
  }

  void _submit(String code) async{
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verifyOTPId,
        smsCode: code,
      );

      // Get the current user
      User? currentUser = FirebaseAuth.instance.currentUser;

      // Link the phone number credential with the current user
      await currentUser?.linkWithCredential(credential);

      var snackBar = const SnackBar(
        content: Text('Phone number linked successfully.'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message!;
      });
      print("Error: $e");
    }
  }

  void _resentOTP() async{
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    setState(() {
      _isError = false;
      _isSent = false;
      _errorMessage = '';
    });
    try {
      await auth.verifyPhoneNumber(
        phoneNumber: widget.phoneNum,
        verificationCompleted: (PhoneAuthCredential credential) {
          print('Completed');
          print(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _errorMessage = e.message!;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            verifyOTPId = verificationId;
            _isSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('TIME OUT');
          setState(() {
            _resendOTP = true;
          });
        },
      );

    }on FirebaseAuthException catch (error){
      print("ERROR HERE");
      print(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    String phoneNum = widget.phoneNum;
    return Dialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32.0))),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 5),
            const Text('Verify Phone OTP ',textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.normal,
                color: Colors.black,),
            ),
            const SizedBox(height: 10),
            _isSent? Text('An OTP code has been sent to $phoneNum',textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.normal,
                color: Colors.black,),
            ) :
                const SizedBox(),
            const SizedBox(height: 15),
            _errorMessage.trim().isNotEmpty ? Text(_errorMessage,style: const TextStyle(color: Colors.red))
                : const SizedBox(),
            OtpTextField(
              fieldWidth: 40,
              numberOfFields: 6,
              borderColor: Colors.blue,
              showFieldAsBox: true,
              onSubmit: (String verificationCode){
                _submit(verificationCode);
              },
            ),
            const SizedBox(height: 15),
            GFButton(
                shape: GFButtonShape.pills,
                size: GFSize.LARGE,
                onPressed: !_resendOTP ? null : (){
                  setState(() {
                    _resendOTP = false;
                  });
                },
                text:"Resend OTP"
            ),
          ],
        ),
      ),
    );
  }
}
