import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'citizen/citizen_home.dart';
import 'collector/collector_main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool loading = false;

  String selectedRole = "Citizen";

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Center(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(25),

          child: Column(

            children: [

              const Icon(Icons.recycling, size: 70, color: Colors.green),

              const SizedBox(height: 20),

              Text(
                isLogin ? "Login" : "Create Account",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              /// ROLE DROPDOWN (ONLY FOR SIGNUP)
              if (!isLogin) ...[
                DropdownButtonFormField(
                  initialValue: selectedRole,
                  items: const [
                    DropdownMenuItem(value: "Citizen", child: Text("Citizen")),
                    DropdownMenuItem(value: "Collector", child: Text("Collector")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                ),
                const SizedBox(height: 10),
              ],

              /// EMAIL
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              /// PASSWORD
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () {
                        if (isLogin) {
                          loginUser();
                        } else {
                          signupUser();
                        }
                      },
                      child: Text(isLogin ? "Login" : "Signup"),
                    ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                  });
                },
                child: Text(
                  isLogin
                      ? "Don't have account? Sign up"
                      : "Already have account? Login",
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// SIGNUP

  Future<void> signupUser() async {

    try {

      setState(() => loading = true);

      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = cred.user!.uid;

      /// STORE ONLY BASIC DATA
      await _firestore.collection("users").doc(uid).set({
        "email": emailController.text.trim(),
        "role": selectedRole,
        "createdAt": FieldValue.serverTimestamp(),
      });

      navigateUser(selectedRole);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => loading = false);
  }

  /// LOGIN

  Future<void> loginUser() async {

    try {

      setState(() => loading = true);

      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = cred.user!.uid;

      DocumentSnapshot doc =
          await _firestore.collection("users").doc(uid).get();

      String role = doc["role"];

      navigateUser(role);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => loading = false);
  }

  /// NAVIGATION

  void navigateUser(String role) {

    if (role == "Collector") {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CollectorMainPage()),
      );

    } else {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CitizenHomePage()),
      );
    }
  }
}