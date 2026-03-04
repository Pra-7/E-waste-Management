import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final householdController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    householdController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': emailController.text.trim(),
        'role': 'citizen',
        'householdName': householdController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return; // ✅ FIX

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return; // ✅ FIX

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } catch (e) {
      if (!mounted) return; // ✅ FIX

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong')),
      );
    }

    if (!mounted) return; // ✅ FIX
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: householdController,
                decoration: const InputDecoration(
                    labelText: "Household / Family Name"),
                validator: (value) =>
                    value == null || value.isEmpty
                        ? "Enter household name"
                        : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: emailController,
                decoration:
                    const InputDecoration(labelText: "Email"),
                validator: (value) =>
                    value == null || value.isEmpty
                        ? "Enter email"
                        : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: passwordController,
                decoration:
                    const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) =>
                    value == null || value.length < 6
                        ? "Password must be at least 6 characters"
                        : null,
              ),
              const SizedBox(height: 20),
              loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: register,
                      child: const Text("Register"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}