import 'package:chat_chat/allConstants/color_constants.dart';
import 'package:chat_chat/allScreens/login_page.dart';
import 'package:chat_chat/allScreens/settings_page.dart';
import 'package:chat_chat/appCoreFeatures/logger.dart';
import 'package:chat_chat/main.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../allModels/popup_choices.dart';
import '../allProviders/auth_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();
  int _limit = 20;
  int _limitIncrement = 20;
  String _textSearch = "";
  bool isLoading = false;

  String currentUserId = "";
  late AuthProvider authProvider;
  // late HomeProvider homeProvider;
  List<PopupChoices> choices = <PopupChoices>[
    PopupChoices(title: 'Settings', icon: Icons.settings),
    PopupChoices(title: 'Sign out', icon: Icons.exit_to_app),
  ];

  Future<void> handleSignOut() async {
    authProvider.handleSignOut();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (cxt) => const LoginPage(),
      ),
    );
  }

  void scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onItemMenuPressed(PopupChoices choice) {
    if (choice.title == "Sign out") {
      handleSignOut();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (cxt) => const SettingsPage(),
        ),
      );
    }
  }

  Widget buildPopupMenu() {
    return PopupMenuButton<PopupChoices>(
        icon: const Icon(
          Icons.more_vert,
          color: Colors.grey,
        ),
        onSelected: onItemMenuPressed,
        itemBuilder: (cxt) {
          return choices.map((PopupChoices choice) {
            return PopupMenuItem<PopupChoices>(
                value: choice,
                child: Row(
                  children: <Widget>[
                    Icon(
                      choice.icon,
                      color: ColorConstants.primaryColor,
                    ),
                    Container(
                      width: 10,
                    ),
                    Text(
                      choice.title,
                      style:
                          const TextStyle(color: ColorConstants.primaryColor),
                    ),
                  ],
                ));
          }).toList();
        });
  }

  @override
  void initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    if (authProvider.getUserFirebaseId()?.isNotEmpty == true) {
      currentUserId = authProvider.getUserFirebaseId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (cxt) => const LoginPage()),
          (route) => false);
    }
    listScrollController.addListener(() {});
  }

  @override
  Widget build(BuildContext context) {
    const tag = 'homepage';
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.black,
        leading: IconButton(
          onPressed: () {},
          icon: Switch(
            value: isWhite,
            onChanged: (val) {
              setState(() {
                isWhite = val;
                Logger.clap(tag, isWhite);
              });
            },
            activeColor: Colors.white,
            activeTrackColor: Colors.grey,
            inactiveTrackColor: Colors.grey,
            inactiveThumbColor: Colors.black45,
          ),
        ),
        actions: [
          buildPopupMenu(),
        ],
      ),
    );
  }
}
