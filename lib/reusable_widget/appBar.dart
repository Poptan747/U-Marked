import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:marquee/marquee.dart';
import 'package:u_marked/reusable_widget/bottomSheet.dart';
import 'package:u_marked/screens/admin/classManagement/addClassPage.dart';
import 'package:u_marked/screens/class/memberList.dart';
import 'gradientBackground.dart';

GFAppBar myClassAppBar = GFAppBar(
  centerTitle: true,
  elevation: 0,
  // automaticallyImplyLeading: false,
  flexibleSpace: Container(
    decoration: myClassAppBarBackgroundDecoration,
  ),
  title: Text("My Class"),
  actions: [
    // GFIconButton(
    //   icon: Icon(
    //     Icons.account_circle_rounded,
    //     color: Colors.white,
    //   ),
    //   onPressed: () {},
    //   type: GFButtonType.transparent,
    // ),
  ],
);

GFAppBar classDetailsAppBar(String className, BuildContext context){
  return GFAppBar(
    centerTitle: true,
    elevation: 0,
    //automaticallyImplyLeading: false,
    flexibleSpace: Container(
      decoration: myClassAppBarBackgroundDecoration,
    ),
    title: SingleChildScrollView(scrollDirection:Axis.horizontal, child: Text(className)),
  );
}

GFAppBar memberListAppBar(int count){
  return GFAppBar(
    centerTitle: true,
    elevation: 0,
    // automaticallyImplyLeading: false,
    flexibleSpace: Container(
      decoration: myClassAppBarBackgroundDecoration,
    ),
    title: Text("Member List ($count)"),
  );
}

GFAppBar studentAttendanceListAppBar(int count){
  return GFAppBar(
    centerTitle: true,
    elevation: 0,
    // automaticallyImplyLeading: false,
    flexibleSpace: Container(
      decoration: myClassAppBarBackgroundDecoration,
    ),
    title: Text("Student Attendance List ($count)"),
  );
}

GFAppBar AttendanceAppBar = GFAppBar(
  centerTitle: true,
  elevation: 0,
  // automaticallyImplyLeading: false,
  flexibleSpace: Container(
    decoration: myClassAppBarBackgroundDecoration,
  ),
  title: Text("Attendance"),
);

GFAppBar attendanceDashBoardAppBar = GFAppBar(
  centerTitle: true,
  elevation: 0,
  // automaticallyImplyLeading: false,
  flexibleSpace: Container(
    decoration: myClassAppBarBackgroundDecoration,
  ),
  title: const Text("Attendance Dashboard"),
);

GFAppBar chatroomAppBar(String userName) {
  return GFAppBar(
    centerTitle: true,
    elevation: 0,
    // automaticallyImplyLeading: false,
    flexibleSpace: Container(
      decoration: myClassAppBarBackgroundDecoration,
    ),
    title: Text(userName),
  );
}

GFAppBar inboxAppBar = GFAppBar(
  centerTitle: true,
  elevation: 0,
  // automaticallyImplyLeading: false,
  flexibleSpace: Container(
    decoration: myClassAppBarBackgroundDecoration,
  ),
  title: Text("Inbox"),
);

GFAppBar userManageListAppBar = GFAppBar(
  centerTitle: true,
  elevation: 0,
  // automaticallyImplyLeading: false,
  flexibleSpace: Container(
    decoration: myClassAppBarBackgroundDecoration,
  ),
  title: Text("User Management"),
);

GFAppBar studentListAppBar(BuildContext context) {
  return GFAppBar(
    centerTitle: true,
    elevation: 0,
    // automaticallyImplyLeading: false,
    flexibleSpace: Container(
      decoration: myClassAppBarBackgroundDecoration,
    ),
    title: const Text("Student List"),
    actions: [
      GFIconButton(
        icon: const Icon(
          Icons.person_add,
          color: Colors.white,
        ),
        onPressed: () {
          showModalBottomSheet(
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            context: context,
            builder: (BuildContext context) {
              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: createStudentBottomSheet(),
              );
            },
          );
        },
        type: GFButtonType.transparent,
      )
    ],
  );
}

GFAppBar lecturerListAppBar(BuildContext context) {
  return GFAppBar(
    centerTitle: true,
    elevation: 0,
    // automaticallyImplyLeading: false,
    flexibleSpace: Container(
      decoration: myClassAppBarBackgroundDecoration,
    ),
    title: const Text("Lecturer List"),
    actions: [
      GFIconButton(
        icon: const Icon(
          Icons.person_add,
          color: Colors.white,
        ),
        onPressed: () {
          showModalBottomSheet(
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            context: context,
            builder: (BuildContext context) {
              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: createLecturerBottomSheet(),
              );
            },
          );
        },
        type: GFButtonType.transparent,
      )
    ],
  );
}

GFAppBar allUserListAppBar(BuildContext context) {
  return GFAppBar(
    centerTitle: true,
    elevation: 0,
    // automaticallyImplyLeading: false,
    flexibleSpace: Container(
      decoration: myClassAppBarBackgroundDecoration,
    ),
    title: const Text("Users List"),
  );
}

GFAppBar locationListAppBar(BuildContext context) {
  return GFAppBar(
    centerTitle: true,
    elevation: 0,
    // automaticallyImplyLeading: false,
    flexibleSpace: Container(
      decoration: myClassAppBarBackgroundDecoration,
    ),
    title: const Text("Location List"),
    actions: [
      GFIconButton(
        icon: const Icon(
          Icons.add_home,
          color: Colors.white,
        ),
        onPressed: () {
          showModalBottomSheet(
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            context: context,
            builder: (BuildContext context) {
              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: createLocationBottomSheet(),
              );
            },
          );
        },
        type: GFButtonType.transparent,
      )
    ],
  );
}

GFAppBar adminClassListAppBar(BuildContext context) {
  return GFAppBar(
    centerTitle: true,
    elevation: 0,
    // automaticallyImplyLeading: false,
    flexibleSpace: Container(
      decoration: myClassAppBarBackgroundDecoration,
    ),
    title: const Text("Class List"),
    actions: [
      GFIconButton(
        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const addClassPage(),
            ),
          );
        },
        type: GFButtonType.transparent,
      )
    ],
  );
}

GFAppBar addClassAppBar(BuildContext context) {
  return GFAppBar(
    centerTitle: true,
    elevation: 0,
    // automaticallyImplyLeading: false,
    flexibleSpace: Container(
      decoration: myClassAppBarBackgroundDecoration,
    ),
    title: const Text("New Class"),
  );
}

GFAppBar editClassAppBar(BuildContext context) {
  return GFAppBar(
    centerTitle: true,
    elevation: 0,
    // automaticallyImplyLeading: false,
    flexibleSpace: Container(
      decoration: myClassAppBarBackgroundDecoration,
    ),
    title: const Text("Edit Class"),
  );
}

GFAppBar profilePageAppBar(BuildContext context) {
  return GFAppBar(
    centerTitle: true,
    elevation: 0,
    // automaticallyImplyLeading: false,
    flexibleSpace: Container(
      decoration: myClassAppBarBackgroundDecoration,
    ),
    title: const Text("Profile"),
  );
}