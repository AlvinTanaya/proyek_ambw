import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:proyek_ambw/reusable_widgets/reusable_widget.dart';
import 'package:proyek_ambw/screens/home_screen.dart';
import 'package:proyek_ambw/utils/color_utils.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _userNameTextController = TextEditingController();
  TextEditingController _fullNameTextController = TextEditingController();
  TextEditingController _phoneNumberTextController = TextEditingController();
  DateTime? _birthDate;
  String? _gender;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> _isUsernameUnique(String username) async {
    final result = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return result.docs.isEmpty;
  }

  Future<void> _register() async {
    if (!await _isUsernameUnique(_userNameTextController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Username already exists. Please choose another one.')),
      );
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailTextController.text,
        password: _passwordTextController.text,
      );

      User? user = userCredential.user;

      await _firestore.collection('users').doc(user?.uid).set({
        'username': _userNameTextController.text,
        'fullName': _fullNameTextController.text,
        'email': _emailTextController.text,
        'gender': _gender,
        'birthDate': _birthDate,
        'phoneNumber': _phoneNumberTextController.text,
        'biodata': '',
        'profilePicture': '',
        'countMarketplace': 0,
        'countPost': 0,
        'linked': [],
      });

      await user!.updateProfile(displayName: _userNameTextController.text);
      await user.reload();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to register';
      if (e.code == 'email-already-in-use') {
        message = 'Email is already in use. Please use a different email.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to register: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Sign Up",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hexStringToColor("CB2B93"),
              hexStringToColor("9546C4"),
              hexStringToColor("5E61F4")
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),
                reusableTextField(
                  "Enter UserName",
                  Icons.person_outline,
                  false,
                  _userNameTextController,
                ),
                const SizedBox(height: 20),
                reusableTextField(
                  "Enter Full Name",
                  Icons.person_outline,
                  false,
                  _fullNameTextController,
                ),
                const SizedBox(height: 20),
                reusableTextField(
                  "Enter Email Id",
                  Icons.email_outlined,
                  false,
                  _emailTextController,
                ),
                const SizedBox(height: 20),
                reusableTextField(
                  "Enter Password",
                  Icons.lock_outlined,
                  true,
                  _passwordTextController,
                ),
                const SizedBox(height: 20),
                reusableTextField(
                  "Enter Phone Number",
                  Icons.phone_outlined,
                  false,
                  _phoneNumberTextController,
                ),
                const SizedBox(height: 20),
                _buildGenderField(),
                const SizedBox(height: 20),
                _buildBirthDateField(),
                const SizedBox(height: 20),
                firebaseUIButton(context, "Sign Up", _register)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonFormField<String>(
        value: _gender,
        decoration: InputDecoration(
          enabledBorder: InputBorder.none,
          border: InputBorder.none,
        ),
        hint: Text(
          'Select Gender',
          style: TextStyle(color: Colors.white),
        ),
        dropdownColor: Colors.deepPurple.shade400,
        items: ['Male', 'Female']
            .map((gender) => DropdownMenuItem<String>(
                  value: gender,
                  child: Text(gender, style: TextStyle(color: Colors.white)),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _gender = value;
          });
        },
      ),
    );
  }

  Widget _buildBirthDateField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
      ),
      child: InkWell(
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() {
              _birthDate = picked;
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            enabledBorder: InputBorder.none,
            border: InputBorder.none,
            suffixIcon: Icon(Icons.calendar_today, color: Colors.white),
          ),
          child: Text(
            _birthDate == null
                ? 'Select Birth Date'
                : '${_birthDate!.toLocal()}'.split(' ')[0],
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
