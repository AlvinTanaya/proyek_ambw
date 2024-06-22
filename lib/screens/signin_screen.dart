  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';
  import 'package:proyek_ambw/reusable_widgets/reusable_widget.dart';
  import 'package:proyek_ambw/screens/reset_password.dart';
  import 'package:proyek_ambw/screens/signup_screen.dart';
  import 'base_screen.dart';

  class SignInScreen extends StatefulWidget {
    const SignInScreen({Key? key}) : super(key: key);

    @override
    _SignInScreenState createState() => _SignInScreenState();
  }

  class _SignInScreenState extends State<SignInScreen> {
    TextEditingController _passwordTextController = TextEditingController();
    TextEditingController _emailTextController = TextEditingController();

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).size.height * 0.15, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.people,
                  color: Colors.white,
                  size: 200,
                ),
                Text(
                  'FansFavorite.',
                  style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 30),
                reusableTextField("Enter Email", Icons.email, false,
                    _emailTextController),
                const SizedBox(height: 20),
                reusableTextField("Enter Password", Icons.lock_outline, true,
                    _passwordTextController),
                const SizedBox(height: 10),
                forgetPassword(context),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await FirebaseAuth.instance
                                  .signInWithEmailAndPassword(
                                      email: _emailTextController.text.trim(),
                                      password:
                                          _passwordTextController.text.trim());
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => BaseScreen(currentIndex: 0),));
                            } on FirebaseAuthException catch (e) {
                              String errorMessage = "An error occurred";
                              if (e.code == 'user-not-found') {
                                errorMessage = "No user found for that email.";
                              } else if (e.code == 'wrong-password') {
                                errorMessage =
                                    "Wrong password provided for that user.";
                              } else if (e.code == 'invalid-email') {
                                errorMessage =
                                    "Email address is badly formatted.";
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(errorMessage)),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Failed to sign in: $e")),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "Login",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SignUpScreen()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    }

    Widget forgetPassword(BuildContext context) {
      return Container(
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.centerRight,
        child: TextButton(
          child: const Text(
            "Forgot Password?",
            style: TextStyle(color: Colors.white70),
          ),
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (context) => ResetPassword())),
        ),
      );
    }
  }
