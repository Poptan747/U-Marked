import 'dart:async';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:u_marked/models/userModel.dart';
import 'package:u_marked/screens/admin/adminHome.dart';
import 'firebase_options.dart';
//--------------------------------------------------
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//--------------------------------------------------
import 'package:u_marked/screens/home/home.dart';
import 'screens/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    // Set appleProvider to `AppleProvider.debug`
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    appleProvider: AppleProvider.debug,
    androidProvider: AndroidProvider.debug,
  );
  try {
    var tokenResponse = await FirebaseAppCheck.instance.getToken();
    print('Integrity Token: ${tokenResponse}');
  } catch (e) {
    print('Error getting Integrity Token: $e');
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,overlays: [SystemUiOverlay.top]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; // Return false to prevent popping the page
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
            statusBarColor: Color(0xFF066cff),
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Color(0xFF066cff),
            systemNavigationBarIconBrightness: Brightness.light
        ),
        child: MaterialApp(
          theme: ThemeData(
            primaryColor: Colors.blue,
          ),
          debugShowCheckedModeBanner: false,
          home: StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator(); // Example loading indicator.
              }
              if (snapshot.hasData && snapshot.data != null) {
                return FutureBuilder(
                  future: _handleAuthState(snapshot.data!),
                  builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return LinearProgressIndicator();
                    }
                    return snapshot.data ?? loginPage();
                  },
                );
              }
              return loginPage();
            },
          ),
        ),
      ),
    );
  }

  Future<Widget> _handleAuthState(User user) async {
    Admin tempAdmin = new Admin(uid: user.uid);
    if (await tempAdmin.checkUserType()) {
      return adminHome();
    } else {
      return home();
    }
  }
}
/**
 *                             _ooOoo_
 *                            o8888888o
 *                            88" . "88
 *                            (| -_- |)
 *                            O\  =  /O
 *                         ____/`---'\____
 *                       .'  \\|     |//  `.
 *                      /  \\|||  :  |||//  \
 *                     /  _||||| -:- |||||-  \
 *                     |   | \\\  -  /// |   |
 *                     | \_|  ''\---/''  |   |
 *                     \  .-\__  `-`  ___/-. /
 *                   ___`. .'  /--.--\  `. . __
 *                ."" '<  `.___\_<|>_/___.'  >'"".
 *               | | :  `- \`.;`\ _ /`;.`/ - ` : | |
 *               \  \ `-.   \_ __\ /__ _/   .-` /  /
 *          ======`-.____`-.___\_____/___.-`____.-'======
 *                             `=---='
 *          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 *                     佛祖保佑        永无BUG
 *            佛曰:
 *                   写字楼里写字间，写字间里程序员；
 *                   程序人员写程序，又拿程序换酒钱。
 *                   酒醒只在网上坐，酒醉还来网下眠；
 *                   酒醉酒醒日复日，网上网下年复年。
 *                   但愿老死电脑间，不愿鞠躬老板前；
 *                   奔驰宝马贵者趣，公交自行程序员。
 *                   别人笑我忒疯癫，我笑自己命太贱；
 *                   不见满街漂亮妹，哪个归得程序员？
*/