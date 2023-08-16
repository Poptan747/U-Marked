import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:getwidget/getwidget.dart';
import 'package:u_marked/reusable_widget/appBar.dart';
import 'package:u_marked/reusable_widget/gradientBackground.dart';

class UserOrdersDisplay extends StatefulWidget {

  @override
  State<UserOrdersDisplay> createState() => _UserOrdersDisplayState();
}

class _UserOrdersDisplayState extends State<UserOrdersDisplay> {
  final user = FirebaseAuth.instance.currentUser!;
  var _nameMap = <String, String>{};
  var _subjectIDMap = <String, String>{};
  var _timeMap = <String, String>{};
  var _dateMap = <String, String>{};

  @override
  void initState() {
    super.initState();
    preloadData();
  }

  loadData(var classID) async {
    final userData = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classID)
        .get();

    if (userData.exists) {
      final data = userData.data() as Map<String, dynamic>;
      setState(() {
        _nameMap[classID] = data['className'];
        _subjectIDMap[classID] = data['subjectID'];
        _timeMap[classID] = data['lectureHour'];

        // Formatting the timestamp
        var classTimestamp = data['createAt'] as Timestamp;
        var classDateTime = classTimestamp.toDate();
        var timeFormatted = '${classDateTime.hour}:${classDateTime.minute}';

        // Formatting the date
        var dateFormatted = '${classDateTime.year}/${classDateTime.month}/${classDateTime.day}';
        // _timeMap[classID] = timeFormatted;
        _dateMap[classID] = dateFormatted;

        // print(data['className']);
      });
    } else {
      print('Class data not found');
    }
  }

  preloadData() async {
    final classCollection = await FirebaseFirestore.instance
        .collection('students')
        .doc(user.uid)
        .collection('classes')
        .get();

    for (var doc in classCollection.docs) {
      var orderData = doc.data() as Map<String, dynamic>;
      var classID = orderData['classID'];
      // print(classID);
      await loadData(classID);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: myClassAppBar,
      body: Container(
        decoration: homeBackgroundDecoration,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('students').doc(user.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return Center(child: Text('User not found.'));
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('students').doc(user.uid).collection('classes').snapshots(),
              builder: (context, orderSnapshot) {
                if (orderSnapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (!orderSnapshot.hasData) {
                  return Text('No orders available.');
                }

                return ListView.builder(
                  itemCount: orderSnapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var orderData = orderSnapshot.data!.docs[index].data() as Map<String, dynamic>;
                    var classID = orderData['classID'];
                    // print(_nameMap[classID]); // Print the corresponding class name
                    return GFListTile(
                      padding: EdgeInsets.all(20),
                      avatar:GFAvatar(
                        backgroundImage: AssetImage('images/location/IEB.jpg'),
                        size: GFSize.LARGE,
                        shape: GFAvatarShape.standard,
                      ),
                      titleText: '${_subjectIDMap[classID] ?? "..."} ${_nameMap[classID] ?? "Loading..."}',
                      subTitleText:'${_timeMap[classID] ?? ".."} ${_dateMap[classID] ?? "Loading..."}',
                      color: Colors.white,
                      icon: Icon(Icons.keyboard_double_arrow_right),
                      onTap: (){
                        print('tapped');
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
