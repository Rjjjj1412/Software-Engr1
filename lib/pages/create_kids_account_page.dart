import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'kids_setup_page.dart';
import 'package:flutter/services.dart';

class CreateKidAccountPage extends StatefulWidget {
  const CreateKidAccountPage({super.key});

  @override
  State<CreateKidAccountPage> createState() => _CreateKidAccountPageState();
}

class _CreateKidAccountPageState extends State<CreateKidAccountPage> {
  String selectedAvatar = 'assets/avatar1.png';
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController numberController = TextEditingController(text: '09');
  final TextEditingController passwordController = TextEditingController();

  void _showAvatarPicker() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 20,
              children: [
                for (var i = 1; i <= 6; i++)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAvatar = 'assets/avatar$i.png';
                      });
                      Navigator.of(context).pop();
                    },
                    child: CircleAvatar(
                      backgroundImage: AssetImage('assets/avatar$i.png'),
                      radius: 30,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2015),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF4E88CF),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      dobController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    final overlay = Overlay.of(context);
    final color = isError ? Colors.red : Colors.green;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewInsets.top + 40,
        left: 20,
        right: 20,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: TextStyle(
                fontFamily: GoogleFonts.fredoka().fontFamily,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Future<void> _submit() async {
    final name = nameController.text.trim();
    final dob = dobController.text.trim();
    final phone = numberController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || dob.isEmpty || phone.isEmpty || password.isEmpty) {
      _showSnackbar('All fields are required', isError: true);
      return;
    }

    if (!RegExp(r'^09\d{9}$').hasMatch(phone)) {
      _showSnackbar('Phone number must start with 09 and be 11 digits', isError: true);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackbar('User not authenticated', isError: true);
        return;
      }

      await FirebaseFirestore.instance.collection('kids').add({
        'firstName': name,
        'date_of_birth': dob,
        'phone': phone,
        'password': password,
        'avatar': selectedAvatar,
        'user_id': user.uid,
        'created_at': FieldValue.serverTimestamp(),
      });

      _showSnackbar('Kid account created successfully!', isError: false);

      await Future.delayed(const Duration(milliseconds: 1500));
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const KidsSetupPage()),
      );
    } catch (e) {
      _showSnackbar('Error saving data: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFCA26),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage(selectedAvatar),
                    radius: 60,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: GestureDetector(
                      onTap: _showAvatarPicker,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.purple,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Set Up Kid’s Account',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      fontFamily: GoogleFonts.fredoka().fontFamily,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F1F1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Column(
                  children: [
                    _buildLabel('Name'),
                    _buildField(nameController),
                    const SizedBox(height: 20),
                    _buildLabel('Date of birth'),
                    _buildField(dobController, onTap: _pickDate, readOnly: true),
                    const SizedBox(height: 20),
                    _buildLabel('Number'),
                    _buildField(numberController, keyboardType: TextInputType.phone,  isContactNumber: true,),
                    const SizedBox(height: 20),
                    _buildLabel('Password'),
                    _buildField(passwordController, obscure: true),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4E88CF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.black, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: GoogleFonts.fredoka().fontFamily,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: GoogleFonts.fredoka().fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller, {
    bool obscure = false,
    bool readOnly = false,
    int? maxLength,
    TextInputType? keyboardType,
    void Function()? onTap,
    bool isContactNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFAEDDFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        readOnly: readOnly,
        maxLength: isContactNumber ? 11 : maxLength,
        keyboardType: keyboardType,
        onTap: onTap,
        obscuringCharacter: '*',
        style: TextStyle(
          fontFamily: GoogleFonts.fredoka().fontFamily,
          fontSize: 24,
        ),
        decoration: const InputDecoration(
          counterText: "",
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
        inputFormatters: isContactNumber
            ? [
                // Allow only digits
                FilteringTextInputFormatter.digitsOnly,
              ]
            : null,
      ),
    );
  }
}
