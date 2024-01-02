import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';

import 'package:mynotes/constants/routes.dart';

import 'dart:developer' as devtools show log;

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LOGIN "),
      ),
      body: FutureBuilder(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return Column(
                children: [
                  TextField(
                    controller: _email,
                    enableSuggestions: false,
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        hintText: "enter your email here"),
                  ),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(
                        hintText: "enter your password here"),
                  ),
                  TextButton(
                    onPressed: () async {
                      final email = _email.text;
                      final password = _password.text;
                      try {
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                            email: email, password: password);
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            (notesRoutes), (route) => false);
                      } on FirebaseAuthException catch (e) {
                        if (e.code == "user-not-found") {
                          devtools.log("no user with ${_email.text}");
                        }
                        if (e.code == 'wrong-password') {
                          devtools.log("Wrong Password");
                        }
                      } catch (e) {
                        devtools.log(e.runtimeType.toString());
                        devtools.log('Soething went wrong');
                        devtools.log(e.toString());
                      }
                    },
                    child: const Text('Login'),
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            registerRoutes, (route) => false);
                      },
                      child: const Text('Not registered yet? Register here!'))
                ],
              );
            default:
              return const Text('Loading...');
          }
        },
      ),
    );
  }
}