import 'package:chat_chat/allProviders/auth_provider.dart';
import 'package:chat_chat/allScreens/home_page.dart';
import 'package:chat_chat/allWidgets/loading_view.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_toast_message/flutter_toast_message.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    switch (authProvider.status) {
      case Status.authenticateError:
        Fluttertoast.showToast(msg: 'Sign in fail');
        break;
      case Status.authenticateCanceled:
        Fluttertoast.showToast(msg: 'Sign in canceled');
        break;
      case Status.authenticated:
        Fluttertoast.showToast(msg: 'Sign in success');
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Screen'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Image.asset('images/back.png'),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(
              20,
            ),
            child: GestureDetector(
              onTap: () async {
                bool isSuccess = await authProvider.handleSignIn();
                if (isSuccess) {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (cxt) => const HomePage(),
                      ),
                    );
                  }
                }
              },
              child: Image.asset("images/google_login.jpg"),
            ),
          ),
          Positioned(
              child: authProvider.status == Status.authenticating
                  ? const LoadingView()
                  : const SizedBox.shrink()),
        ],
      ),
    );
  }
}
