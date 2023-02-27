import 'package:chat_chat/allConstants/app_constants.dart';
import 'package:chat_chat/allProviders/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'allScreens/splash_page.dart';

bool isWhite = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(MyApp(prefs: prefs));
  // runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  MyApp({Key? key, required this.prefs}) : super(key: key);
  // const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AuthProvider(
                  googleSignIn: GoogleSignIn(),
                  firebaseAuth: FirebaseAuth.instance,
                  firebaseFirestore: firebaseFirestore,
                  prefs: prefs,
                ))
      ],
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appTitle,
          theme: ThemeData(
            primaryColor: Colors.black,
          ),
          home: const SplashPage()),
    );
  }
}
