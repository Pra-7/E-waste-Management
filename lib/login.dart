import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'citizen/citizen_home.dart';
import 'collector/collector_home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String selectedRole = 'Citizen';
  bool isLogin = true;
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Waste Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              /// ROLE SELECT
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: "Select Role",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: "Citizen",
                    child: Text("Citizen"),
                  ),
                  DropdownMenuItem(
                    value: "Collector",
                    child: Text("Collector"),
                  ),
                ],
                onChanged: isLogin
                    ? null
                    : (value) {
                        setState(() {
                          selectedRole = value!;
                        });
                      },
              ),

              const SizedBox(height: 15),

              /// EMAIL
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter email";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              /// PASSWORD
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              /// LOGIN / SIGNUP BUTTON
              loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {

                          if (!_formKey.currentState!.validate()) return;

                          setState(() => loading = true);

                          if (isLogin) {
                            await loginUser();
                          } else {
                            await signupUser();
                          }

                          if (!mounted) return;
                          setState(() => loading = false);
                        },
                        child: Text(isLogin ? "Login" : "Sign Up"),
                      ),
                    ),

              /// SWITCH LOGIN / SIGNUP
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                  });
                },
                child: Text(
                  isLogin
                      ? "New user? Create account"
                      : "Already have an account? Login",
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// -------------------------
  /// SIGNUP FUNCTION
  /// -------------------------
  Future<void> signupUser() async {
  try {

    print("Signup started");

    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    String uid = cred.user!.uid;

    print("User created: $uid");

    await _firestore.collection("users").doc(uid).set({
      "email": emailController.text.trim(),
      "role": selectedRole,
      "createdAt": FieldValue.serverTimestamp(),
    });

    print("Firestore data saved");

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account created successfully")),
    );

    if (selectedRole == "Collector") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CollectorHomePage(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CitizenHomePage(),
        ),
      );
    }

  } catch (e) {

    print("Signup error: $e");

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Signup failed: $e")),
    );
  }
}
  /// -------------------------
  /// LOGIN FUNCTION
  /// -------------------------
  Future<void> loginUser() async {
    try {

      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = cred.user!.uid;

      DocumentSnapshot doc =
          await _firestore.collection("users").doc(uid).get();

      String role = doc["role"];

      if (!mounted) return;

      if (role == "Collector") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const CollectorHomePage(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const CitizenHomePage(),
          ),
        );
      }

    } on FirebaseAuthException catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Login failed")),
      );
    }
  }
}