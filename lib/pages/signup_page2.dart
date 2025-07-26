import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';

class SignupCardPage extends StatefulWidget {
  final String email;
  final String password;
  final String familyName;
  final String cardName;
  final String cardNumber;
  final String exp;
  final String ccv;

  const SignupCardPage({
    super.key,
    required this.email,
    required this.password,
    required this.familyName,
    this.cardName = '',
    this.cardNumber = '',
    this.exp = '',
    this.ccv = '',
  });

  @override
  State<SignupCardPage> createState() => _SignupCardPageState();
}

class _SignupCardPageState extends State<SignupCardPage> {
  late TextEditingController _nameController;
  late TextEditingController _cardNumberController;
  late TextEditingController _expController;
  late TextEditingController _ccvController;

  final _formKey = GlobalKey<FormState>();
  final FocusNode _cardFocus = FocusNode();
  final FocusNode _expFocus = FocusNode();
  final FocusNode _ccvFocus = FocusNode();

  final bool _obscureCcv = true;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.cardName);
    _cardNumberController = TextEditingController(text: widget.cardNumber);
    _expController = TextEditingController(text: widget.exp);
    _ccvController = TextEditingController(text: widget.ccv);
  }

  void _showTopSnackBar(String message, {bool isError = true}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50.0,
        left: 20.0,
        right: 20.0,
        child: Material(
          elevation: 10.0,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: isError ? Colors.redAccent : Colors.green,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Text(
              message,
              style: GoogleFonts.fredoka(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2)).then((value) => overlayEntry.remove());
  }

  Future<void> _registerUser() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      String userId = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'email': widget.email,
        'family_name': widget.familyName,
        'created_at': Timestamp.now(),
      });

      await FirebaseFirestore.instance.collection('family_payment_info').add({
        'user_id': userId,
        'card_name': _nameController.text.trim(),
        'card_number': _cardNumberController.text.trim(),
        'exp': _expController.text.trim(),
        'ccv': _ccvController.text.trim(),
        'created_at': Timestamp.now(),
      });

      _showTopSnackBar('Account registered successfully!', isError: false);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    } catch (e) {
      _showTopSnackBar('Error: ${e.toString()}');
    }
  }

  OutlineInputBorder _buildBorder(bool isValid) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: isValid ? Colors.black : Colors.red,
          width: 3,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFCA26),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  'KidsBank',
                  style: GoogleFonts.fredoka(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name on Card',
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_cardFocus),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFAEDDFF),
                              border: _buildBorder(true),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Card Number',
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _cardNumberController,
                          focusNode: _cardFocus,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                          ],
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_expFocus),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFAEDDFF),
                            border: _buildBorder(!_submitted || _cardNumberController.text.length == 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Exp',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      final now = DateTime.now();
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: now,
                                        firstDate: now,
                                        lastDate: DateTime(now.year + 10),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          _expController.text =
                                              "${picked.month.toString().padLeft(2, '0')}/${picked.year.toString().substring(2)}";
                                        });
                                      }
                                    },
                                    child: AbsorbPointer(
                                      child: TextFormField(
                                        controller: _expController,
                                        focusNode: _expFocus,
                                        textInputAction: TextInputAction.next,
                                        onFieldSubmitted: (_) =>
                                            FocusScope.of(context).requestFocus(_ccvFocus),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: const Color(0xFFAEDDFF),
                                          border: _buildBorder(!_submitted || _expController.text.isNotEmpty),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CCV',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _ccvController,
                                    focusNode: _ccvFocus,
                                    obscureText: _obscureCcv,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                    ],
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFAEDDFF),
                                      border: _buildBorder(!_submitted || _ccvController.text.length == 4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => _submitted = true);

                                final cardNumber = _cardNumberController.text.trim();
                                final ccv = _ccvController.text.trim();

                                if (_nameController.text.isEmpty ||
                                    cardNumber.isEmpty ||
                                    _expController.text.isEmpty ||
                                    ccv.isEmpty) {
                                  _showTopSnackBar('Please fill out all fields!');
                                } else if (cardNumber.length != 16) {
                                  _showTopSnackBar('Card number must be 16 digits!');
                                } else if (ccv.length != 4) {
                                  _showTopSnackBar('CCV must be 4 digits!');
                                } else {
                                  _registerUser();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4e88cf),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Register',
                                style: GoogleFonts.fredoka(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, {
                        'cardName': _nameController.text.trim(),
                        'cardNumber': _cardNumberController.text.trim(),
                        'exp': _expController.text.trim(),
                        'ccv': _ccvController.text.trim(),
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    label: Text(
                      "Back",
                      style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
