import 'package:cloud_firestore/cloud_firestore.dart';

class UserGet {
  final String uid;
  final String email;
  final int userType;

  UserGet({
    required this.uid,
    required this.email,
    required this.userType,
  });

  int getUserType(){
    return userType;
  }
}

class UserDetail extends UserGet{
  UserDetail({required super.uid, required super.email, required super.userType});
  bool _isAdmin = false;

  String _name='';
  String _studentID='';
  String _batch='';
  String _lecturerID='';

  Future<Map<String, dynamic>> getUserDetail() async {
    await loadDetail();
    return {
      'name': _name,
      'studentID': _studentID,
      'batch': _batch,
      'lecturerID' : _lecturerID,
      'uid': uid,
      'userType' : userType
    };
  }

  Future<void> loadDetail() async {
    if(userType == 1){
      //is Student
      var userData = await FirebaseFirestore.instance.collection('students').doc(uid).get();
      if(userData.exists) {
        final data = await userData.data() as Map<String, dynamic>;
        _name = data['name'];
        _studentID = data['studentID'];
        _batch = data['batch'];
      }else{
        print('User data not found');
      }
    }else if(userType == 2){
      // is Lec
      var userData = await FirebaseFirestore.instance.collection('lecturers').doc(uid).get();
      if(userData.exists) {
        final data = await userData.data() as Map<String, dynamic>;
        _name = data['name'];
        _lecturerID = data['lecturerID'];
      }else{
        print('User data not found');
      }
    }else{
      _isAdmin = true;
    }

  }
  
}

class Admin {
  final String uid;

  Admin({
    required this.uid,
  });

  Future<bool> checkUserType() async {
    var userCollection = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    var data = await userCollection.data() as Map<String, dynamic>;

    if(data['userType']==3){
      return true;
    }else{
      return false;
    }
  }

  Future<String> getAdminName() async {
    var userCollection = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    var data = await userCollection.data() as Map<String, dynamic>;
    return data['name'];
  }
}
