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

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  bool isLogin = true;
  bool loading = false;
  bool obscurePassword = true;
  String selectedRole = "Citizen";

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F0),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ─── Hero Banner ───────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 36),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D6A4F),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.recycling,
                            size: 42, color: Colors.white),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "EcoPickup",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Responsible e-waste, one pickup at a time",
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ─── Form Card ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLogin ? "Welcome back 👋" : "Create account",
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B3A2D),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isLogin
                              ? "Sign in to continue"
                              : "Join the green movement",
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 22),

                        // ── Signup-only fields ──────────────
                        if (!isLogin) ...[
                          // Role selector
                          const Text("I am a",
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _roleChip(
                                  "Citizen", Icons.person_outline_rounded),
                              const SizedBox(width: 10),
                              _roleChip("Collector",
                                  Icons.local_shipping_outlined),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Full name
                          _label("Full Name"),
                          const SizedBox(height: 6),
                          _textField(
                            controller: nameController,
                            hint: "e.g. Aarav Sharma",
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 14),

                          // Phone
                          _label("Phone Number"),
                          const SizedBox(height: 6),
                          _textField(
                            controller: phoneController,
                            hint: "e.g. 9812345678",
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Email
                        _label("Email address"),
                        const SizedBox(height: 6),
                        _textField(
                          controller: emailController,
                          hint: "you@example.com",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),

                        // Password
                        _label("Password"),
                        const SizedBox(height: 6),
                        _textField(
                          controller: passwordController,
                          hint: "••••••••",
                          icon: Icons.lock_outline,
                          obscure: obscurePassword,
                          suffix: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF9CA3AF),
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => obscurePassword = !obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 26),

                        // Submit
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: loading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF2D6A4F)))
                              : ElevatedButton(
                                  onPressed:
                                      isLogin ? loginUser : signupUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2D6A4F),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    isLogin ? "Sign In" : "Create Account",
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 14),

                        // Toggle
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isLogin = !isLogin;
                                // clear fields when switching
                                nameController.clear();
                                phoneController.clear();
                              });
                            },
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFF6B7280)),
                                children: [
                                  TextSpan(
                                      text: isLogin
                                          ? "Don't have an account? "
                                          : "Already have an account? "),
                                  TextSpan(
                                    text: isLogin ? "Sign up" : "Sign in",
                                    style: const TextStyle(
                                      color: Color(0xFF2D6A4F),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151)));

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
        prefixIcon:
            Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF2D6A4F), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
    );
  }

  Widget _roleChip(String role, IconData icon) {
    bool selected = selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF2D6A4F)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2D6A4F)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color:
                      selected ? Colors.white : const Color(0xFF6B7280),
                  size: 22),
              const SizedBox(height: 4),
              Text(
                role,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Auth logic ───────────────────────────────────────────────────────────

  Future<void> signupUser() async {
    // Basic validation
    if (nameController.text.trim().isEmpty) {
      _snack("Please enter your full name");
      return;
    }
    if (phoneController.text.trim().isEmpty) {
      _snack("Please enter your phone number");
      return;
    }
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().length < 6) {
      _snack("Please enter a valid email and password (min 6 chars)");
      return;
    }

    try {
      setState(() => loading = true);

      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = cred.user!.uid;

      // Store full user profile in Firestore
      await _firestore.collection("users").doc(uid).set({
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "email": emailController.text.trim(),
        "role": selectedRole,
        "createdAt": FieldValue.serverTimestamp(),
      });

      navigateUser(selectedRole);
    } catch (e) {
      _snack(e.toString());
    }
    setState(() => loading = false);
  }

  Future<void> loginUser() async {
    try {
      setState(() => loading = true);

      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      DocumentSnapshot doc =
          await _firestore.collection("users").doc(cred.user!.uid).get();
      String role = doc["role"];
      navigateUser(role);
    } catch (e) {
      _snack(e.toString());
    }
    setState(() => loading = false);
  }

  void navigateUser(String role) {
    if (role == "Collector") {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const CollectorMainPage()));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const CitizenHomePage()));
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}