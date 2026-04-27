import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loadingProfile = true;
  bool savingProfile = false;
  bool savingPassword = false;
  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;
  bool showPasswordSection = false; // hidden by default

  String userEmail = "";
  String userRole = "";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      nameController.text = data["name"] ?? "";
      phoneController.text = data["phone"] ?? "";
      userEmail = data["email"] ?? FirebaseAuth.instance.currentUser?.email ?? "";
      userRole = data["role"] ?? "Citizen";
      loadingProfile = false;
    });
  }

  Future<void> _saveProfile() async {
    if (nameController.text.trim().isEmpty) { _snack("Name cannot be empty"); return; }
    if (phoneController.text.trim().isEmpty) { _snack("Phone cannot be empty"); return; }
    setState(() => savingProfile = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
      });
      _snack("Profile updated successfully!", success: true);
    } catch (e) {
      _snack("Error: $e");
    }
    setState(() => savingProfile = false);
  }

  Future<void> _changePassword() async {
    if (currentPasswordController.text.isEmpty) { _snack("Please enter your current password"); return; }
    if (newPasswordController.text.length < 6) { _snack("New password must be at least 6 characters"); return; }
    if (newPasswordController.text != confirmPasswordController.text) { _snack("New passwords don't match"); return; }

    setState(() => savingPassword = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPasswordController.text);

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      setState(() => showPasswordSection = false);
      _snack("Password changed successfully!", success: true);
    } on FirebaseAuthException catch (e) {
      _snack(e.code == 'wrong-password' ? "Current password is incorrect" : "Error: ${e.message}");
    } catch (e) {
      _snack("Error: $e");
    }
    setState(() => savingPassword = false);
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: success ? const Color(0xFF2D6A4F) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (loadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F))));
    }

    final initials = nameController.text.trim().isNotEmpty
        ? nameController.text.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : "?";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── Avatar Header ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              color: const Color(0xFF2D6A4F),
              child: Column(
                children: [
                  Container(
                    width: 74, height: 74,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Center(child: Text(initials,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF2D6A4F)))),
                  ),
                  const SizedBox(height: 10),
                  Text(userEmail, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(userRole, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ─── Personal Info ──────────────────────────
                  _sectionTitle("Personal Information"),
                  const SizedBox(height: 10),
                  _card(children: [
                    _editField(controller: nameController, label: "Full Name", icon: Icons.badge_outlined, hint: "Your full name"),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    _editField(controller: phoneController, label: "Phone Number", icon: Icons.phone_outlined, hint: "e.g. 9812345678", keyboardType: TextInputType.phone),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined, color: Color(0xFF9CA3AF), size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Email", style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                              const SizedBox(height: 2),
                              Text(userEmail, style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280))),
                            ],
                          )),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
                            child: const Text("Cannot edit", style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                          ),
                        ],
                      ),
                    ),
                  ]),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: savingProfile ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F), foregroundColor: Colors.white,
                        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: savingProfile
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Save Changes", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ─── Security Section ───────────────────────
                  _sectionTitle("Security"),
                  const SizedBox(height: 10),

                  // Toggle button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showPasswordSection = !showPasswordSection;
                        if (!showPasswordSection) {
                          currentPasswordController.clear();
                          newPasswordController.clear();
                          confirmPasswordController.clear();
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: showPasswordSection ? const Color(0xFF2D6A4F) : const Color(0xFFE5E7EB),
                          width: showPasswordSection ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: showPasswordSection ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.lock_outline_rounded,
                                color: showPasswordSection ? const Color(0xFF2D6A4F) : const Color(0xFFE65100),
                                size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Change Password",
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1B3A2D))),
                                Text(
                                  showPasswordSection ? "Tap to cancel" : "Tap to update your password",
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            showPasswordSection ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Password fields — only shown when toggled open
                  if (showPasswordSection) ...[
                    const SizedBox(height: 10),
                    _card(children: [
                      _passwordField(controller: currentPasswordController, label: "Current Password", obscure: obscureCurrent, onToggle: () => setState(() => obscureCurrent = !obscureCurrent)),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      _passwordField(controller: newPasswordController, label: "New Password", obscure: obscureNew, onToggle: () => setState(() => obscureNew = !obscureNew)),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      _passwordField(controller: confirmPasswordController, label: "Confirm New Password", obscure: obscureConfirm, onToggle: () => setState(() => obscureConfirm = !obscureConfirm)),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: savingPassword ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3A6C), foregroundColor: Colors.white,
                          elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: savingPassword
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Update Password", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.8));

  Widget _card({required List<Widget> children}) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(children: children),
      );

  Widget _editField({required TextEditingController controller, required String label, required IconData icon, required String hint, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
          const SizedBox(width: 12),
          Expanded(child: TextField(
            controller: controller, keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1B3A2D)),
            decoration: InputDecoration(labelText: label, hintText: hint, border: InputBorder.none,
                labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          )),
        ],
      ),
    );
  }

  Widget _passwordField({required TextEditingController controller, required String label, required bool obscure, required VoidCallback onToggle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF), size: 20),
          const SizedBox(width: 12),
          Expanded(child: TextField(
            controller: controller, obscureText: obscure,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1B3A2D)),
            decoration: InputDecoration(labelText: label, border: InputBorder.none,
                labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          )),
          IconButton(
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF9CA3AF), size: 18),
            onPressed: onToggle,
          ),
        ],
      ),
    );
  }
}