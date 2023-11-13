import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:u_marked/models/userModel.dart';
import 'package:u_marked/reusable_widget/alertDialog.dart';

class FormBottomSheet extends StatefulWidget {
  const FormBottomSheet({Key? key, required this.classID}) : super(key: key);
  final String classID;

  @override
  _FormBottomSheetState createState() => _FormBottomSheetState();
}

class _FormBottomSheetState extends State<FormBottomSheet> {
  final _textEditingController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController startAtTimeController = TextEditingController();
  TextEditingController endAtTimeController = TextEditingController();
  String selectedValue = 'Option 1';
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _textEditingController.dispose();
    dateController.dispose();
    startAtTimeController.dispose();
    endAtTimeController.dispose();
    super.dispose();
  }

  void _submit() async{
    final isValid = _form.currentState!.validate();
    if(!isValid){
      return;
    }
    _form.currentState!.save();

    try{
      var attendanceRecord =
      FirebaseFirestore.instance.collection('attendanceRecord').add({
        'classID' : widget.classID,
        'startAt' : startAtTimeController.text,
        'endAt' : endAtTimeController.text,
        'date' : dateController.text,
        'createBy': FirebaseAuth.instance.currentUser!.uid,
        'attendanceType': 1,
        'geofencingRange': selectedValue,
        'markedUser' : 0,

      }).then((value){
        FirebaseFirestore.instance.collection('classes').doc(widget.classID).collection('attendanceRecord').doc(value.id).set({
          'attendanceRecordID' : value.id
        });
        loadClass(widget.classID,value.id);
      });

      var snackBar = const SnackBar(
        content: Text('Done'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      _textEditingController.clear();
      dateController.clear();
      startAtTimeController.clear();
      endAtTimeController.clear();

      Navigator.pop(context);
    }on FirebaseFirestore catch(error){
      var snackBar = SnackBar(
        content: Text(error.toString()),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  loadClass(String classID, String recordID) async{
    final studentCollection = await FirebaseFirestore.instance.collection('classes').doc(classID).collection('members').get();
    for (var doc in studentCollection.docs) {
      var studentData = doc.data() as Map<String, dynamic>;
      var studentUID = studentData['uid'];
      FirebaseFirestore.instance.collection('attendanceRecord').doc(recordID).collection('studentAttendanceList').add({
        'attendanceRecordID' : recordID,
        'studentUID' : studentUID,
        'attendanceStatus' : 0, //0=pending 1=Present 2=Absent 3=Late 4=Leave early 5=sick
        'attendanceTime' : '',
        'notes': '',
      }).then((value){
        FirebaseFirestore.instance.collection('students').doc(studentUID).collection('attendanceRecord').doc(recordID).set({
          'attendanceRecordID' : recordID,
          'studentAttendanceRecordID' : value.id
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'New Attendance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Attendance Date',icon:Icon(Icons.date_range)),
              readOnly: true,
              validator: (value){
                if(value == null || value.trim().isEmpty){
                  return 'Please select a date';
                }
              },
              onTap: () async{
                DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(), //get today's date
                    firstDate: DateTime(2000), //DateTime.now() - not to allow to choose before today.
                    lastDate: DateTime(2101)
                );
                if(pickedDate != null ){
                  String formattedDate = DateFormat.yMMMEd().format(pickedDate);
                  setState(() {
                    dateController.text = formattedDate;
                  });
                }else{
                  print("Date is not selected");
                }
              },
            ),
            TextFormField(
              controller: startAtTimeController,
              decoration: const InputDecoration(labelText: 'Start at',icon:Icon(Icons.access_time)),
              readOnly: true,
              validator: (value){
                if(value == null || value.trim().isEmpty){
                  return 'Please select a start at time';
                }
              },
              onTap: () async{
                DateTime datetime = DateTime.now();
                var pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: datetime.hour, minute: datetime.minute),
                );
                if(pickedTime != null ){
                  DateTime selectedDateTime = DateTime(
                    datetime.year,
                    datetime.month,
                    datetime.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                  print(selectedDateTime);
                  String formattedTime = DateFormat.jm().format(selectedDateTime);
                  setState(() {
                    startAtTimeController.text = formattedTime;
                  });
                }else{
                  print("Date is not selected");
                }
              },
            ),
            TextFormField(
              controller: endAtTimeController,
              decoration: const InputDecoration(labelText: 'End at',icon:Icon(Icons.access_time)),
              readOnly: true,
              validator: (value){
                if(value == null || value.trim().isEmpty){
                  return 'Please select a end at time';
                }
              },
              onTap: () async{
                DateTime datetime = DateTime.now();
                var pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: datetime.hour, minute: datetime.minute),
                );
                if(pickedTime != null ){
                  DateTime selectedDateTime = DateTime(
                    datetime.year,
                    datetime.month,
                    datetime.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );

                  if(startAtTimeController.text.isNotEmpty){
                    DateTime startDateTime = DateFormat.jm().parse(startAtTimeController.text);

                    DateTime compareStartTime = DateTime(
                      datetime.year,
                      datetime.month,
                      datetime.day,
                      startDateTime.hour,
                      startDateTime.minute
                    );

                    if(selectedDateTime.isAfter(compareStartTime)){
                      String formattedTime = DateFormat.jm().format(selectedDateTime);
                      setState(() {
                        endAtTimeController.text = formattedTime;
                      });
                    } else{
                      Alerts().timePickerAlertDialog(context);
                    }
                  }else{
                    Alerts().startAtFirstAlertDialog(context);
                  }
                }else{
                  print("Date is not selected");
                }
              },
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedValue,
              icon: Icon(Icons.share_location),
              onChanged: (newValue) {
                print(newValue);
                setState(() {
                  selectedValue = newValue!;
                });
              },
              validator: (value){
                if(value == null || value.trim().isEmpty){
                  return 'Please select a Geofencing option';
                }
              },
              items: ['Option 1', 'Option 2', 'Option 3']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text('${['Close - Classroom range', 'Medium - Building range', 'Large - Campus range']
                  [['Option 1', 'Option 2', 'Option 3'].indexOf(value)]}'),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Select an GeoFencing option',
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String itemName = _textEditingController.text;
                _submit();
                // Navigator.pop(context);
              },
              child: Text('Add new attendance record'),
            ),
          ],
        ),
      ),
    );
  }
}

class createStudentBottomSheet extends StatefulWidget {
  const createStudentBottomSheet({Key? key}) : super(key: key);

  @override
  State<createStudentBottomSheet> createState() => _createStudentBottomSheetState();
}

class _createStudentBottomSheetState extends State<createStudentBottomSheet> {

  final _createStudentForm = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _enteredEmailController = TextEditingController();
  final TextEditingController _enteredNameController = TextEditingController();
  final TextEditingController _enteredStudentIDController = TextEditingController();
  final TextEditingController _enteredBatchController = TextEditingController();
  String _errorMessage = '';
  bool isLoading = false;
  File? _pickedImageFile;

  @override
  void dispose() {
    _passwordController.dispose();
    _enteredEmailController.dispose();
    _enteredStudentIDController.dispose();
    _enteredBatchController.dispose();
    _enteredNameController.dispose();
    super.dispose();
  }

  void _submit() async{
    setState(() {
      _errorMessage = '';
    });
    final isValid = _createStudentForm.currentState!.validate();
    if(!isValid){
      return;
    }
    _createStudentForm.currentState!.save();

    try{
      setState(() {
        isLoading = true;
      });
      var currentUserUid = FirebaseAuth.instance.currentUser!.uid;
      String currentUEmail = FirebaseAuth.instance.currentUser!.email!;
      var userCollection = await FirebaseFirestore.instance.collection('users').doc(currentUserUid).get();
      var data = await userCollection.data() as Map<String, dynamic>;

      var userCredentials = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _enteredEmailController.text, password: _passwordController.text
      );

      User? user = userCredentials.user;
      if (user != null) {

        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email' : _enteredEmailController.text,
          'password' : _passwordController.text,
          'userType' : 1, //student 1 , lec, 2 , admin 3
          'createAt' : DateTime.now(),
          'phoneNum' : '',
        }).then((value) async {
          if(_pickedImageFile !=null){
            final storageRef = FirebaseStorage.instance.ref().child('user_images').child('${user.uid}.jpg');
            await storageRef.putFile(_pickedImageFile!);
            FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'imagePath' :  await storageRef.getDownloadURL(),
            });
          }else{
            final storageRef = FirebaseStorage.instance.ref().child('user_images').child('default_user.jpg');
            FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'imagePath' :  await storageRef.getDownloadURL(),
            });
          }
        }).catchError((error) {
          print(error);
        });

        FirebaseFirestore.instance.collection('students').doc(user.uid).set({
          'batch' : _enteredBatchController.text,
          'name' : _enteredNameController.text,
          'studentID' : _enteredStudentIDController.text,
        }).catchError((error) {
          print(error);
        });

        var _siginAgain = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: currentUEmail, password: data['password']
        );
      }

      setState(() {
        isLoading = false;
      });

      Navigator.pop(context);

      var snackBar = const SnackBar(
        content: Text('Student account created!'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

    }on FirebaseAuthException catch(error){
      setState(() {
        _errorMessage = error.message.toString();
      });
    }
  }

  String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  void _pickImage() async{
    final pickImage = await ImagePicker().pickImage(source: ImageSource.gallery, maxHeight: 480,
        maxWidth: 640,
        imageQuality: 100);

    if(pickImage == null){
      return;
    }

    setState(() {
      _pickedImageFile = File(pickImage.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _createStudentForm,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 20),
                const Text(
                  'New Student',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                CircleAvatar(
                  foregroundImage: _pickedImageFile!=null? FileImage(_pickedImageFile!) : null,
                  radius: 50,
                ),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Add profile picture'),
                ),
                isLoading? const CircularProgressIndicator() : const SizedBox(height: 1),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredStudentIDController,
                  decoration: const InputDecoration(labelText: 'Student ID',icon:Icon(Icons.badge)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || value.trim().length > 50){
                      return 'Please enter a valid student ID !';
                    }
                  },
                  onSaved: (value){
                    _enteredStudentIDController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredBatchController,
                  decoration: const InputDecoration(labelText: 'Batch',icon:Icon(Icons.groups_2)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid batch !';
                    }
                  },
                  onSaved: (value){
                    _enteredBatchController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredNameController,
                  decoration: const InputDecoration(labelText: 'Name',icon:Icon(Icons.person)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid name !';
                    }
                  },
                  onSaved: (value){
                    _enteredNameController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email',icon:Icon(Icons.email)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || !value.contains('@')){
                      return 'Please enter a valid email address !';
                    }
                  },
                  onSaved: (value){
                    _enteredEmailController.text = value!;
                  },
                ),
                _errorMessage.trim().isNotEmpty ?
                Text(_errorMessage, style: TextStyle(color: Colors.red),) :
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password',icon:Icon(Icons.password)),
                        validator: (value){
                          if(value == null || value.trim().isEmpty){
                            return 'Please select a date';
                          }
                        },
                        onSaved: (value){
                          _passwordController.text = value!;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.shuffle),
                      onPressed: () {
                        setState(() {
                          _passwordController.text = generateRandomString(8);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _submit();
                  },
                  child: const Text('Create Student Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class editStudentBottomSheet extends StatefulWidget {
  final String uid;
  const editStudentBottomSheet({Key? key,required this.uid}) : super(key: key);

  @override
  State<editStudentBottomSheet> createState() => _editStudentBottomSheetState();
}

class _editStudentBottomSheetState extends State<editStudentBottomSheet> {
  final _editStudentForm = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _enteredEmailController = TextEditingController();
  final TextEditingController _enteredNameController = TextEditingController();
  final TextEditingController _enteredStudentIDController = TextEditingController();
  final TextEditingController _enteredBatchController = TextEditingController();
  String _errorMessage = '';
  File? _pickedImageFile;
  String imageUrl ='';
  bool changeImage = false;
  bool isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _enteredEmailController.dispose();
    _enteredStudentIDController.dispose();
    _enteredBatchController.dispose();
    _enteredNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadData();
    print(widget.uid);
  }

  loadData() async{
    String uid = widget.uid;
    var userCollection = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    var data = await userCollection.data() as Map<String, dynamic>;

    UserDetail newUser = UserDetail(uid: uid, email: data['email'], userType: data['userType']);
    Map<String, dynamic> userDetailmap = await newUser.getUserDetail();

    setState(() {
      _enteredNameController.text = userDetailmap['name'];
      _enteredStudentIDController.text = userDetailmap['studentID'];
      _enteredBatchController.text = userDetailmap['batch'];
      _enteredEmailController.text = data['email'];
      _passwordController.text = data['password'];
      imageUrl = data['imagePath'];
    });
  }

  _submit() async{
    bool hasError = false;
    String newEmail='';
    setState(() {
      _errorMessage = '';
    });
    final isValid = _editStudentForm.currentState!.validate();
    if(!isValid){
      return;
    }
    _editStudentForm.currentState!.save();

    try{
      setState(() {
        isLoading = true;
      });
      var userCollection = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      var data = await userCollection.data() as Map<String, dynamic>;

      if(data['email'] != _enteredEmailController.text){
        List<String> signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(_enteredEmailController.text);
        if (signInMethods.isEmpty) {
          newEmail = _enteredEmailController.text;
        } else {
          setState(() {
            _errorMessage = 'Email is already in use.';
            hasError = true;
          });
        }
      }else{
        newEmail = data['email'];
      }

      if(!hasError){
        var currentUserUid = FirebaseAuth.instance.currentUser!.uid;
        String currentUEmail = FirebaseAuth.instance.currentUser!.email!;
        var currentUserCollection = await FirebaseFirestore.instance.collection('users').doc(currentUserUid).get();
        var currentUserData = await currentUserCollection.data() as Map<String, dynamic>;

        //change to user
        var _siginAsUser = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: data['email'], password: data['password']
        );

        await _siginAsUser.user!.updateEmail(newEmail);
        await _siginAsUser.user!.updatePassword(_passwordController.text);

        //change to admin
        var _siginAsAdmin = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: currentUEmail, password: currentUserData['password']
        );

        if(changeImage){
          final storageRef = FirebaseStorage.instance.ref().child('user_images').child('${widget.uid}.jpg');
          await storageRef.delete();
          await storageRef.putFile(_pickedImageFile!);

          FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
            'email' : _enteredEmailController.text,
            'password' : _passwordController.text,
            'imagePath' :  await storageRef.getDownloadURL(),
          }).catchError((error) {
            print(error);
          });
        }else{
          FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
            'email' : _enteredEmailController.text,
            'password' : _passwordController.text,
          }).catchError((error) {
            print(error);
          });
        }

        FirebaseFirestore.instance.collection('students').doc(widget.uid).update({
          'batch' : _enteredBatchController.text,
          'name' : _enteredNameController.text,
          'studentID' : _enteredStudentIDController.text,
        }).catchError((error) {
          print(error);
        });

        Navigator.pop(context);

        var snackBar = const SnackBar(
          content: Text('Student Information changed!'),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
      setState(() {
        isLoading = false;
      });
    }on FirebaseAuthException catch(error){
      setState(() {
        isLoading = false;
        _errorMessage = error.message.toString();
      });
    }
  }

  String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  void _pickImage() async{
    final pickImage = await ImagePicker().pickImage(source: ImageSource.gallery, maxHeight: 480,
        maxWidth: 640,
        imageQuality: 100);

    if(pickImage == null){
      return;
    }

    setState(() {
      _pickedImageFile = File(pickImage.path);
      changeImage = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _editStudentForm,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 20),
                const Text(
                  'Modify Student Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                changeImage? CircleAvatar(
                  foregroundImage: _pickedImageFile!=null? FileImage(_pickedImageFile!) : null,
                  radius: 50,
                ) :
                CircleAvatar(
                  foregroundImage: imageUrl.trim().isNotEmpty? NetworkImage(imageUrl) : null,
                  radius: 50,
                ),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Add profile picture'),
                ),
                const SizedBox(height: 10),
                isLoading? const CircularProgressIndicator() : const SizedBox(height: 1),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredStudentIDController,
                  decoration: const InputDecoration(labelText: 'Student ID',icon:Icon(Icons.badge)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || value.trim().length > 50){
                      return 'Please enter a valid student ID !';
                    }
                  },
                  onSaved: (value){
                    _enteredStudentIDController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredBatchController,
                  decoration: const InputDecoration(labelText: 'Batch',icon:Icon(Icons.groups_2)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid batch !';
                    }
                  },
                  onSaved: (value){
                    _enteredBatchController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredNameController,
                  decoration: const InputDecoration(labelText: 'Name',icon:Icon(Icons.person)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid name !';
                    }
                  },
                  onSaved: (value){
                    _enteredNameController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email',icon:Icon(Icons.email)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || !value.contains('@')){
                      return 'Please enter a valid email address !';
                    }
                  },
                  onSaved: (value){
                    _enteredEmailController.text = value!;
                  },
                ),
                _errorMessage.trim().isNotEmpty ?
                Text(_errorMessage, style: TextStyle(color: Colors.red),) :
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password',icon:Icon(Icons.password)),
                        validator: (value){
                          if(value == null || value.trim().isEmpty){
                            return 'Please select a date';
                          }
                        },
                        onSaved: (value){
                          _passwordController.text = value!;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.shuffle),
                      onPressed: () {
                        setState(() {
                          _passwordController.text = generateRandomString(8);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _submit();
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class createLecturerBottomSheet extends StatefulWidget {
  const createLecturerBottomSheet({Key? key}) : super(key: key);

  @override
  _createLecturerBottomSheetState createState() => _createLecturerBottomSheetState();
}

class _createLecturerBottomSheetState extends State<createLecturerBottomSheet> {

  final _createLecturerForm = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _enteredEmailController = TextEditingController();
  final TextEditingController _enteredNameController = TextEditingController();
  final TextEditingController _enteredLecturerIDController = TextEditingController();
  String _errorMessage = '';
  File? _pickedImageFile;

  @override
  void dispose() {
    _passwordController.dispose();
    _enteredEmailController.dispose();
    _enteredLecturerIDController.dispose();
    _enteredNameController.dispose();
    super.dispose();
  }

  void _submit() async{
    setState(() {
      _errorMessage = '';
    });
    final isValid = _createLecturerForm.currentState!.validate();
    if(!isValid){
      return;
    }
    _createLecturerForm.currentState!.save();

    try{
      var currentUserUid = FirebaseAuth.instance.currentUser!.uid;
      String currentUEmail = FirebaseAuth.instance.currentUser!.email!;
      var userCollection = await FirebaseFirestore.instance.collection('users').doc(currentUserUid).get();
      var data = await userCollection.data() as Map<String, dynamic>;

      var userCredentials = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _enteredEmailController.text, password: _passwordController.text
      );

      User? user = userCredentials.user;
      if (user != null) {

        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email' : _enteredEmailController.text,
          'password' : _passwordController.text,
          'userType' : 2, //student 1 , lec, 2 , admin 3
          'createAt' : DateTime.now(),
          'phoneNum' : '',
        }).then((value) async {
          if(_pickedImageFile !=null){
            final storageRef = FirebaseStorage.instance.ref().child('user_images').child('${user.uid}.jpg');
            await storageRef.putFile(_pickedImageFile!);
            FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'imagePath' :  await storageRef.getDownloadURL(),
            });
          }else{
            final storageRef = FirebaseStorage.instance.ref().child('user_images').child('default_user.jpg');
            FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'imagePath' :  await storageRef.getDownloadURL(),
            });
          }
        }).catchError((error) {
          print(error);
        });

        FirebaseFirestore.instance.collection('lecturers').doc(user.uid).set({
          'name' : _enteredNameController.text,
          'lecturerID' : _enteredLecturerIDController.text,
        }).catchError((error) {
          print(error);
        });

        var _siginAgain = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: currentUEmail, password: data['password']
        );
      }

      Navigator.pop(context);

      var snackBar = const SnackBar(
        content: Text('Lecturer account created!'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

    }on FirebaseAuthException catch(error){
      setState(() {
        _errorMessage = error.message.toString();
      });
    }
  }

  String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  void _pickImage() async{
    final pickImage = await ImagePicker().pickImage(source: ImageSource.gallery, maxHeight: 480,
        maxWidth: 640,
        imageQuality: 100);

    if(pickImage == null){
      return;
    }

    setState(() {
      _pickedImageFile = File(pickImage.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _createLecturerForm,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 20),
                const Text(
                  'New Lecturer',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                CircleAvatar(
                  foregroundImage: _pickedImageFile!=null? FileImage(_pickedImageFile!) : null,
                  radius: 50,
                ),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Add profile picture'),
                ),
                TextFormField(
                  controller: _enteredLecturerIDController,
                  decoration: const InputDecoration(labelText: 'Lecturer ID',icon:Icon(Icons.badge)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || value.trim().length > 50){
                      return 'Please enter a valid Lecturer ID !';
                    }
                  },
                  onSaved: (value){
                    _enteredLecturerIDController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredNameController,
                  decoration: const InputDecoration(labelText: 'Name',icon:Icon(Icons.person)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid name !';
                    }
                  },
                  onSaved: (value){
                    _enteredNameController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email',icon:Icon(Icons.email)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || !value.contains('@')){
                      return 'Please enter a valid email address !';
                    }
                  },
                  onSaved: (value){
                    _enteredEmailController.text = value!;
                  },
                ),
                _errorMessage.trim().isNotEmpty ?
                Text(_errorMessage, style: TextStyle(color: Colors.red),) :
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password',icon:Icon(Icons.password)),
                        validator: (value){
                          if(value == null || value.trim().isEmpty){
                            return 'Please select a date';
                          }
                        },
                        onSaved: (value){
                          _passwordController.text = value!;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.shuffle),
                      onPressed: () {
                        setState(() {
                          _passwordController.text = generateRandomString(8);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _submit();
                  },
                  child: const Text('Create Lecturer Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class editLecturerBottomSheet extends StatefulWidget {
  final String uid;
  const editLecturerBottomSheet({Key? key,required this.uid}) : super(key: key);

  @override
  State<editLecturerBottomSheet> createState() => _editLecturerBottomSheet();
}

class _editLecturerBottomSheet extends State<editLecturerBottomSheet> {
  final _editLecturerForm = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _enteredEmailController = TextEditingController();
  final TextEditingController _enteredNameController = TextEditingController();
  final TextEditingController _enteredLecturerIDController = TextEditingController();
  String _errorMessage = '';
  String imageUrl = '';
  bool changeImage = false;
  File? _pickedImageFile;
  bool isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _enteredEmailController.dispose();
    _enteredLecturerIDController.dispose();
    _enteredNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async{
    String uid = widget.uid;
    var userCollection = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    var data = await userCollection.data() as Map<String, dynamic>;

    UserDetail newUser = UserDetail(uid: uid, email: data['email'], userType: data['userType']);
    Map<String, dynamic> userDetailmap = await newUser.getUserDetail();

    setState(() {
      _enteredNameController.text = userDetailmap['name'];
      _enteredLecturerIDController.text = userDetailmap['lecturerID'];
      _enteredEmailController.text = data['email'];
      _passwordController.text = data['password'];
      imageUrl = data['imagePath'];
    });
  }

  _submit() async{
    bool hasError = false;
    String newEmail='';
    setState(() {
      _errorMessage = '';
    });
    final isValid = _editLecturerForm.currentState!.validate();
    if(!isValid){
      return;
    }
    _editLecturerForm.currentState!.save();

    try{
      setState(() {
        isLoading = true;
      });
      var userCollection = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      var data = await userCollection.data() as Map<String, dynamic>;

      if(data['email'] != _enteredEmailController.text){
        List<String> signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(_enteredEmailController.text);
        if (signInMethods.isEmpty) {
          newEmail = _enteredEmailController.text;
        } else {
          setState(() {
            _errorMessage = 'Email is already in use.';
            hasError = true;
          });
        }
      }else{
        newEmail = data['email'];
      }

      if(!hasError){
        var currentUserUid = FirebaseAuth.instance.currentUser!.uid;
        String currentUEmail = FirebaseAuth.instance.currentUser!.email!;
        var currentUserCollection = await FirebaseFirestore.instance.collection('users').doc(currentUserUid).get();
        var currentUserData = await currentUserCollection.data() as Map<String, dynamic>;

        //change to user
        var _siginAsUser = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: data['email'], password: data['password']
        );

        await _siginAsUser.user!.updateEmail(newEmail);
        await _siginAsUser.user!.updatePassword(_passwordController.text);

        //change to admin
        var _siginAsAdmin = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: currentUEmail, password: currentUserData['password']
        );

        if(changeImage){
          final storageRef = FirebaseStorage.instance.ref().child('user_images').child('${widget.uid}.jpg');
          await storageRef.delete();
          await storageRef.putFile(_pickedImageFile!);

          FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
            'email' : newEmail,
            'password' : _passwordController.text,
            'imagePath' : await storageRef.getDownloadURL(),
          }).catchError((error) {
            print(error);
          });
        }else{
          FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
            'email' : newEmail,
            'password' : _passwordController.text,
          }).catchError((error) {
            print(error);
          });
        }

        FirebaseFirestore.instance.collection('lecturers').doc(widget.uid).update({
          'name' : _enteredNameController.text,
          'lecturerID' : _enteredLecturerIDController.text,
        }).catchError((error) {
          print(error);
        });

        Navigator.pop(context);

        var snackBar = const SnackBar(
          content: Text('Lecturer Information changed!'),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

      setState(() {
        isLoading = false;
      });
    }on FirebaseAuthException catch(error){
      setState(() {
        isLoading = false;
        _errorMessage = error.message.toString();
      });
    }
  }

  String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  void _pickImage() async{
    final pickImage = await ImagePicker().pickImage(source: ImageSource.gallery, maxHeight: 480,
        maxWidth: 640,
        imageQuality: 100);

    if(pickImage == null){
      return;
    }

    setState(() {
      _pickedImageFile = File(pickImage.path);
      changeImage = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _editLecturerForm,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 20),
                const Text(
                  'Modify Lecturer Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                changeImage? CircleAvatar(
                  foregroundImage: _pickedImageFile!=null? FileImage(_pickedImageFile!) : null,
                  radius: 50,
                ) :
                CircleAvatar(
                  foregroundImage: imageUrl.trim().isNotEmpty? NetworkImage(imageUrl) : null,
                  radius: 50,
                ),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Add profile picture'),
                ),
                const SizedBox(height: 10),
                isLoading? const CircularProgressIndicator() : const SizedBox(height: 1),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredLecturerIDController,
                  decoration: const InputDecoration(labelText: 'Student ID',icon:Icon(Icons.badge)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || value.trim().length > 50){
                      return 'Please enter a valid student ID !';
                    }
                  },
                  onSaved: (value){
                    _enteredLecturerIDController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredNameController,
                  decoration: const InputDecoration(labelText: 'Name',icon:Icon(Icons.person)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid name !';
                    }
                  },
                  onSaved: (value){
                    _enteredNameController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email',icon:Icon(Icons.email)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || !value.contains('@')){
                      return 'Please enter a valid email address !';
                    }
                  },
                  onSaved: (value){
                    _enteredEmailController.text = value!;
                  },
                ),
                _errorMessage.trim().isNotEmpty ?
                Text(_errorMessage, style: TextStyle(color: Colors.red),) :
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password',icon:Icon(Icons.password)),
                        validator: (value){
                          if(value == null || value.trim().isEmpty){
                            return 'Please select a date';
                          }
                        },
                        onSaved: (value){
                          _passwordController.text = value!;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.shuffle),
                      onPressed: () {
                        setState(() {
                          _passwordController.text = generateRandomString(8);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _submit();
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class createLocationBottomSheet extends StatefulWidget {
  const createLocationBottomSheet({Key? key}) : super(key: key);

  @override
  _createLocationBottomSheetState createState() => _createLocationBottomSheetState();
}

class _createLocationBottomSheetState extends State<createLocationBottomSheet> {

  final _createLocationForm = GlobalKey<FormState>();
  String _errorMessage = '';
  String selectedOption = 'Option 1';
  bool showOtherInput = false;
  File? _pickedImageFile;
  TextEditingController otherInputController = TextEditingController();
  TextEditingController roomNameInputController = TextEditingController();
  TextEditingController roomImageInputController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    roomNameInputController.dispose();
    otherInputController.dispose();
    roomImageInputController.dispose();
  }

  void _submit() async{
    setState(() {
      _errorMessage = '';
    });
    final isValid = _createLocationForm.currentState!.validate();
    if(!isValid){
      return;
    }
    _createLocationForm.currentState!.save();

    try{

      FirebaseFirestore.instance.collection('locations').add({
        'roomNo' : roomNameInputController.text,
        'building' : selectedOption,
      }).then((doc) async {
        final storageRef = FirebaseStorage.instance.ref().child('location_images').child('${doc.id}.jpg');
        await storageRef.putFile(_pickedImageFile!);
        FirebaseFirestore.instance.collection('locations').doc(doc.id).update({
          'imagePath' :  await storageRef.getDownloadURL(),
        });
      });

      Navigator.pop(context);

      var snackBar = const SnackBar(
        content: Text('Location created!'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

    }on FirebaseAuthException catch(error){
      setState(() {
        _errorMessage = error.message.toString();
      });
    }
  }

  void _pickImage() async{
    final pickImage = await ImagePicker().pickImage(source: ImageSource.gallery, maxHeight: 480,
        maxWidth: 640,
        imageQuality: 100);

    if(pickImage == null){
      return;
    }

    setState(() {
      roomImageInputController.text = pickImage.path;
      _pickedImageFile = File(pickImage.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _createLocationForm,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 20),
                const Text(
                  'New Location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _errorMessage.trim().isNotEmpty ?
                Text(_errorMessage, style: TextStyle(color: Colors.red),) :
                const SizedBox(height: 10),
                TextFormField(
                  controller: roomNameInputController,
                  decoration: const InputDecoration(labelText: 'Room Name',icon:Icon(Icons.door_front_door)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || value.trim().length > 50){
                      return 'Please enter a valid room name !';
                    }
                  },
                  onSaved: (value){
                    roomNameInputController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: 'Main Building',
                  decoration: const InputDecoration(
                    labelText: 'Select a building',
                      icon:Icon(Icons.maps_home_work)
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Main Building',
                      child: Text('Main building'),
                    ),
                    DropdownMenuItem(
                      value: 'IEB',
                      child: Text('IEB'),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child: Text('Other'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      if (value == 'Other') {
                        showOtherInput = true;
                      } else {
                        selectedOption = value!;
                        showOtherInput = false;
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                if (showOtherInput)
                  TextFormField(
                    controller: otherInputController,
                    decoration: const InputDecoration(labelText: 'Other Option'),
                    validator: (value){
                      if(showOtherInput = true){
                        if(value == null || value.trim().isEmpty || value.trim().length > 50){
                          return 'Please enter a valid building name !';
                        }
                      }
                    },
                    onSaved: (value){
                      if(showOtherInput = true){
                        selectedOption = value!;
                      }
                    },
                  ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: roomImageInputController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Room image',icon: Icon(Icons.image)),
                  onTap: _pickImage,
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please upload a image. ';
                    }
                  },
                  onSaved: (value){
                    // roomNameInputController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                _pickedImageFile!= null?
                GFImageOverlay(
                    height: 200,
                    width: 300,
                    shape: BoxShape.rectangle,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    image: FileImage(_pickedImageFile!),
                ) :
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _submit();
                  },
                  child: const Text('Create new location'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class editLocationBottomSheet extends StatefulWidget {
  final String locationId;
  const editLocationBottomSheet({Key? key,required this.locationId}) : super(key: key);

  @override
  State<editLocationBottomSheet> createState() => _editLocationBottomSheet();
}

class _editLocationBottomSheet extends State<editLocationBottomSheet> {
  final _editLocationForm = GlobalKey<FormState>();
  String _errorMessage = '';
  String selectedOption = 'Option 1';
  bool showOtherInput = false;
  String imageUrl = '';
  File? _pickedImageFile;
  TextEditingController otherInputController = TextEditingController();
  TextEditingController roomNameInputController = TextEditingController();
  TextEditingController roomImageInputController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    roomNameInputController.dispose();
    otherInputController.dispose();
    roomImageInputController.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async{
    String locationId = widget.locationId;
    var userCollection = await FirebaseFirestore.instance.collection('locations').doc(locationId).get();
    var data = await userCollection.data() as Map<String, dynamic>;

    setState(() {
      roomNameInputController.text = data['roomNo'];
      selectedOption = data['building'];
      imageUrl = data['imagePath'];
    });
  }

  _submit() async{
    bool hasError = false;
    String newEmail='';
    setState(() {
      _errorMessage = '';
    });
    final isValid = _editLocationForm.currentState!.validate();
    if(!isValid){
      return;
    }
    _editLocationForm.currentState!.save();

    try{
      setState(() {
        isLoading = true;
      });
      String locationID = widget.locationId;
      FirebaseFirestore.instance.collection('locations').doc(locationID).update({
        'roomNo' : roomNameInputController.text,
        'building' : selectedOption,
      }).then((doc) async {
        if(_pickedImageFile!=null){
          final storageRef = FirebaseStorage.instance.ref().child('location_images').child('${locationID}.jpg');
          await storageRef.delete();
          await storageRef.putFile(_pickedImageFile!);
          FirebaseFirestore.instance.collection('locations').doc(locationID).update({
            'imagePath' :  await storageRef.getDownloadURL(),
          });
        }
      });

      setState(() {
        isLoading = false;
      });

      Navigator.pop(context);

      var snackBar = const SnackBar(
        content: Text('Location information changed!'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

    }on FirebaseAuthException catch(error){
      setState(() {
        setState(() {
          isLoading = false;
        });
        _errorMessage = error.message.toString();
      });
    }
  }

  void _pickImage() async{
    final pickImage = await ImagePicker().pickImage(source: ImageSource.gallery, maxHeight: 480,
        maxWidth: 640,
        imageQuality: 100);

    if(pickImage == null){
      return;
    }

    setState(() {
      roomImageInputController.text = pickImage.path;
      _pickedImageFile = File(pickImage.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _editLocationForm,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 20),
                const Text(
                  'New Location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    height: 200,
                    width: 300,
                    child: Image.network(
                      imageUrl,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        } else {
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          );
                        }
                      },
                      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                        return const Text('Error loading image');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                isLoading? const CircularProgressIndicator() : const SizedBox(height: 1),
                _errorMessage.trim().isNotEmpty ?
                Text(_errorMessage, style: TextStyle(color: Colors.red),) :
                const SizedBox(height: 10),
                TextFormField(
                  controller: roomNameInputController,
                  decoration: const InputDecoration(labelText: 'Room Name',icon:Icon(Icons.door_front_door)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || value.trim().length > 50){
                      return 'Please enter a valid room name !';
                    }
                  },
                  onSaved: (value){
                    roomNameInputController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedOption != 'Main Building' && selectedOption!= 'IEB'? 'Other': selectedOption,
                  decoration: const InputDecoration(
                      labelText: 'Select a building',
                      icon:Icon(Icons.maps_home_work)
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Main Building',
                      child: Text('Main building'),
                    ),
                    DropdownMenuItem(
                      value: 'IEB',
                      child: Text('IEB'),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child: Text('Other'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      if (value == 'Other') {
                        showOtherInput = true;
                      } else {
                        selectedOption = value!;
                        showOtherInput = false;
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                if (selectedOption != 'Main Building' && selectedOption!= 'IEB')
                  TextFormField(
                    controller: otherInputController,
                    decoration: const InputDecoration(labelText: 'Other Option'),
                    validator: (value){
                      if(showOtherInput = true){
                        if(value == null || value.trim().isEmpty || value.trim().length > 50){
                          return 'Please enter a valid building name !';
                        }
                      }
                    },
                    onSaved: (value){
                      if(showOtherInput = true){
                        selectedOption = value!;
                      }
                    },
                  ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: roomImageInputController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Room image',icon: Icon(Icons.image)),
                  onTap: _pickImage,
                  onSaved: (value){
                    // roomNameInputController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                _pickedImageFile!= null?
                GFImageOverlay(
                  height: 200,
                  width: 300,
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  image: FileImage(_pickedImageFile!),
                ) :
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _submit();
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}