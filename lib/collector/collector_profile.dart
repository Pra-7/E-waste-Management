import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../login.dart';
import 'completed_pickups.dart';

class CollectorProfilePage extends StatefulWidget {
  const CollectorProfilePage({super.key});

  @override
  State<CollectorProfilePage> createState() => _CollectorProfilePageState();
}

class _CollectorProfilePageState extends State<CollectorProfilePage> {
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
  int completedCount = 0;

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

    final pickups = await FirebaseFirestore.instance
        .collection("pickup_requests")
        .where("collectorId", isEqualTo: uid)
        .where("status", isEqualTo: "Completed")
        .get();

    setState(() {
      nameController.text = data["name"] ?? "";
      phoneController.text = data["phone"] ?? "";
      userEmail = data["email"] ?? FirebaseAuth.instance.currentUser?.email ?? "";
      completedCount = pickups.docs.length;
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
      _snack("Profile updated!", success: true);
    } catch (e) {
      _snack("Error: $e");
    }
    setState(() => savingProfile = false);
  }

  Future<void> _changePassword() async {
    if (currentPasswordController.text.isEmpty) { _snack("Please enter your current password"); return; }
    if (newPasswordController.text.length < 6) { _snack("Password must be at least 6 characters"); return; }
    if (newPasswordController.text != confirmPasswordController.text) { _snack("Passwords don't match"); return; }

    setState(() => savingPassword = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final credential = EmailAuthProvider.credential(email: user.email!, password: currentPasswordController.text);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPasswordController.text);

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      setState(() => showPasswordSection = false);
      _snack("Password changed!", success: true);
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
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF1A3A6C))));
    }

    final initials = nameController.text.trim().isNotEmpty
        ? nameController.text.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : "CO";

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // ─── Header ────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A3A6C),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Center(child: Text(initials,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1A3A6C)))),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      nameController.text.isNotEmpty ? nameController.text : "Collector",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(userEmail, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Text("$completedCount Pickups Completed",
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ─── Personal Info ──────────────────────
                    _sectionTitle("Personal Information"),
                    const SizedBox(height: 10),
                    _card(children: [
                      _editField(controller: nameController, label: "Full Name", icon: Icons.badge_outlined, hint: "Your name"),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      _editField(controller: phoneController, label: "Phone Number", icon: Icons.phone_outlined, hint: "9812345678", keyboardType: TextInputType.phone),
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
                                Text(userEmail, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
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

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: savingProfile ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3A6C), foregroundColor: Colors.white,
                          elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: savingProfile
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Save Changes", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── Quick Links ────────────────────────
                    _sectionTitle("Quick Links"),
                    const SizedBox(height: 10),
                    _card(children: [
                      ListTile(
                        leading: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.history_rounded, color: Color(0xFF2D6A4F), size: 18),
                        ),
                        title: const Text("Completed Pickups", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1B2C4E))),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF9CA3AF)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompletedPickupsPage())),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // ─── Security — Change Password toggle ──
                    _sectionTitle("Security"),
                    const SizedBox(height: 10),

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
                            color: showPasswordSection ? const Color(0xFF1A3A6C) : const Color(0xFFE5E7EB),
                            width: showPasswordSection ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: showPasswordSection ? const Color(0xFFE3EBF8) : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.lock_outline_rounded,
                                  color: showPasswordSection ? const Color(0xFF1A3A6C) : const Color(0xFFE65100),
                                  size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Change Password",
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1B2C4E))),
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

                    if (showPasswordSection) ...[
                      const SizedBox(height: 10),
                      _card(children: [
                        _passwordField(controller: currentPasswordController, label: "Current Password", obscure: obscureCurrent, onToggle: () => setState(() => obscureCurrent = !obscureCurrent)),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        _passwordField(controller: newPasswordController, label: "New Password", obscure: obscureNew, onToggle: () => setState(() => obscureNew = !obscureNew)),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        _passwordField(controller: confirmPasswordController, label: "Confirm Password", obscure: obscureConfirm, onToggle: () => setState(() => obscureConfirm = !obscureConfirm)),
                      ]),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: savingPassword ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100), foregroundColor: Colors.white,
                            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: savingPassword
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Update Password", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ─── Logout ─────────────────────────────
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: const Text("Sign Out", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushAndRemoveUntil(context,
                              MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEE2E2), foregroundColor: const Color(0xFFDC2626),
                          elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
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