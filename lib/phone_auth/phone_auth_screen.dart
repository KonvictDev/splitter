import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bottom_navigation_main_screen.dart';
import '../home_page.dart';

class PhoneAuthPage extends StatefulWidget {
  @override
  _PhoneAuthPageState createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final ValueNotifier<bool> _isCodeSent = ValueNotifier(false);
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  String _verificationId = "";

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.sms.shouldShowRequestRationale) {
      await Permission.sms.request();
    }
  }

  bool _isPhoneNumberValid(String phoneNumber) => RegExp(r'^[0-9]{10}$').hasMatch(phoneNumber);

  Future<void> _sendOTP() async {
    final phoneNumber = _phoneController.text.trim();
    final name = _nameController.text.trim();


    if (phoneNumber.isEmpty || name.isEmpty || !_isPhoneNumberValid(phoneNumber)) {
      _showError('Enter a valid name and phone number');
      return;
    }

    _isLoading.value = true;

    // Request permissions in parallel to OTP sending
    final permissionFuture = _requestPermissions();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        timeout: Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInAndSaveUser(credential, phoneNumber, name);
        },
        verificationFailed: (e) => _showError(e.message),
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _isCodeSent.value = true;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );

      await permissionFuture; // Ensure permission request completes
    } catch (e) {
      _showError(e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _verifyOTP() async {
    final phoneNumber = _phoneController.text.trim();
    String fullPhoneNumber = '+91$phoneNumber';
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showError('Enter the OTP');
      return;
    }

    _isLoading.value = true;
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );
      await _signInAndSaveUser(credential, fullPhoneNumber, _nameController.text.trim());
    } catch (e) {
      _showError('Invalid OTP or phone verification failed');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _signInAndSaveUser(PhoneAuthCredential credential, String phoneNumber, String name) async {
    final user = (await _auth.signInWithCredential(credential)).user;
    if (user != null) {
      await _firestore.collection('users').doc(phoneNumber).set({
        'pidata': {
          'name': name,
          'phoneNumber': phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavigationMainScreen()));
    }
  }

  void _showError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message ?? 'An error occurred')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Phone Authentication')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Name')),
            TextField(controller: _phoneController, decoration: InputDecoration(labelText: 'Phone Number', prefixText: '+91 '), keyboardType: TextInputType.phone),
            ValueListenableBuilder<bool>(
              valueListenable: _isCodeSent,
              builder: (context, isCodeSent, child) {
                return isCodeSent
                    ? Column(children: [
                  TextField(controller: _otpController, decoration: InputDecoration(labelText: 'Enter OTP')),
                  SizedBox(height: 20),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isLoading,
                    builder: (context, isLoading, child) => ElevatedButton(
                      onPressed: isLoading ? null : _verifyOTP,
                      child: isLoading ? CircularProgressIndicator() : Text('Verify OTP'),
                    ),
                  )
                ])
                    : ValueListenableBuilder<bool>(
                  valueListenable: _isLoading,
                  builder: (context, isLoading, child) => ElevatedButton(
                    onPressed: isLoading ? null : _sendOTP,
                    child: isLoading ? CircularProgressIndicator() : Text('Send OTP'),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
