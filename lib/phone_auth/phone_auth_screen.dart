import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

import '../Constants/AppConstants.dart';
import '../bottom_navigation_main_screen.dart';

/// Service class to handle Firebase phone authentication and Firestore operations.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Sends an OTP to the given phone number.
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMessage) onError,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: Duration(seconds: 60), // Adjust timeout as needed.
        verificationCompleted: onVerificationCompleted,
        verificationFailed: (e) {
          final errorMsg =
              e.message ?? 'Verification failed. Please try again.';
          onError(errorMsg);
        },
        codeSent: (verificationId, resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          // Optionally handle auto-retrieval timeout.
        },
      );
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s);
      onError(e.toString());
    }
  }

  /// Signs in with the provided OTP.
  Future<User?> signInWithOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: smsCode);
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s);
      rethrow;
    }
  }

  Future<bool> checkUserExists(String phoneNumber) async {
    try {
      final doc = await _firestore.collection('users').doc(phoneNumber).get();
      return doc.exists;
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s);
      return false;
    }
  }

  /// Writes user details to Firestore asynchronously, including the FCM token.
  Future<void> writeUserDetails(String phoneNumber, String name, {String? fcmToken}) async {
    try {
      await _firestore.collection('users').doc(phoneNumber).set({
        'pidata': {
          'name': name,
          'phoneNumber': phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'fcmToken': fcmToken,
          'avatar':''// Save the FCM token
        },
      }, SetOptions(merge: true));
      print("Firestore write completed successfully.");
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s);
      print("Error writing to Firestore: $e");
    }
  }
}

/// A page that handles phone authentication.
class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({Key? key}) : super(key: key);

  @override
  _PhoneAuthPageState createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isOTPSent = false;
  String _verificationId = "";
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Requests SMS permissions.
  Future<void> _requestPermissions() async {
    if (!await Permission.sms.isGranted) {
      await Permission.sms.request();
    }
  }

  /// Retrieves the FCM token.
  Future<String?> _getFCMToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  /// Sends OTP to the entered phone number.
  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    final phoneNumber = '+91${_phoneController.text.trim()}';
    final name = _nameController.text.trim();

    setState(() {
      _isLoading = true;
    });

    await _requestPermissions();

    Stopwatch sendOTPStopwatch = Stopwatch()..start();

    await _authService.sendOTP(
      phoneNumber: phoneNumber,
      onVerificationCompleted: (credential) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auto-verification in progress...')),
        );
        try {
          final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          if (userCredential.user != null) {
            bool userExists = await _authService.checkUserExists(phoneNumber);
            // Retrieve FCM token
            final fcmToken = await _getFCMToken();
            if (!userExists) {
              await _authService.writeUserDetails(phoneNumber, name, fcmToken: fcmToken);
            } else {
              await FirebaseFirestore.instance.collection('users').doc(phoneNumber).update({
                'pidata.fcmToken': fcmToken,
              });
            }
            // Listen for token refresh events.
            FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
              await FirebaseFirestore.instance.collection('users').doc(phoneNumber).update({
                'pidata.fcmToken': newToken,
              });
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => BottomNavigationMainScreen(),
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Authentication failed')),
          );
        }
      },
      onCodeSent: (verificationId) {
        sendOTPStopwatch.stop();
        print("OTP sent in ${sendOTPStopwatch.elapsedMilliseconds} ms");
        setState(() {
          _verificationId = verificationId;
          _isOTPSent = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification code sent. Check your SMS.')),
        );
      },
      onError: (errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  /// Verifies the entered OTP.
  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please enter the OTP.')));
      return;
    }
    final phoneNumber = '+91${_phoneController.text.trim()}';
    final name = _nameController.text.trim();

    setState(() {
      _isLoading = true;
    });

    Stopwatch verifyOTPStopwatch = Stopwatch()..start();

    try {
      final user = await _authService.signInWithOTP(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );
      verifyOTPStopwatch.stop();
      print("SignIn completed in ${verifyOTPStopwatch.elapsedMilliseconds} ms");
      if (user != null) {
        bool userExists = await _authService.checkUserExists(phoneNumber);
        // Retrieve FCM token
        final fcmToken = await _getFCMToken();
        if (!userExists) {
          await _authService.writeUserDetails(phoneNumber, name, fcmToken: fcmToken);
          print("New user details written to Firestore.");
        } else {
          print("User already exists. Updating FCM token.");
          await FirebaseFirestore.instance.collection('users').doc(phoneNumber).update({
            'pidata.fcmToken': fcmToken,
          });
        }
        // Listen for token refresh events.
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          await FirebaseFirestore.instance.collection('users').doc(phoneNumber).update({
            'pidata.fcmToken': newToken,
          });
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BottomNavigationMainScreen(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid OTP or verification failed.')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Builds a reusable text field.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    required String validatorMsg,
    TextInputType keyboardType = TextInputType.text,
    String? regex,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.black),
        contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.black),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return validatorMsg;
        if (regex != null && !RegExp(regex).hasMatch(value.trim())) {
          return validatorMsg;
        }
        return null;
      },
      inputFormatters: maxLength != null
          ? [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength)
      ]
          : null,
    );
  }

  /// Builds a gradient button.
  Widget _buildGradientButton({
    required Key key,
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      key: key,
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        gradient: LinearGradient(
          colors: [AppConstants.primaryColor, AppConstants.primaryGradientColor],
        ),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: onPressed,
        child: _isLoading
            ? CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : Text(
          text,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Builds the OTP input section.
  Widget _buildOTPInputSection() {
    return Column(
      key: ValueKey('verifyOTP'),
      children: [
        TextFormField(
          controller: _otpController,
          decoration: InputDecoration(
            labelText: 'Enter OTP',
            prefixIcon: Icon(Icons.sms_outlined, color: Colors.black),
            contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.black),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.black),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
        ),
        SizedBox(height: 18.0),
        _buildGradientButton(
          key: ValueKey('verifyBtn'),
          text: 'Verify OTP',
          onPressed: _verifyOTP,
        ),
        SizedBox(height: 10.0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Splitzo Login',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.0),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppConstants.primaryColor,
              AppConstants.primaryGradientColor
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80.0),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0)),
                elevation: 12,
                shadowColor: Colors.black54,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Center(
                          child: Image.asset(
                            Theme.of(context).brightness == Brightness.dark
                                ? 'assets/logo/splitzoWhite.png'
                                : 'assets/logo/Splitzo.png',
                            height: 80,
                          ),
                        ),
                        SizedBox(height: 16.0),
                        Text(
                          'Welcome to Splitzo',
                          style: TextStyle(
                            fontSize: 26.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Effortlessly split your expenses with friends',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24.0),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Name',
                          icon: Icons.face,
                          validatorMsg: 'Name cannot be empty',
                          textCapitalization: TextCapitalization.words,
                        ),
                        SizedBox(height: 16.0),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: '10-digit number',
                          icon: Icons.phone_iphone,
                          keyboardType: TextInputType.phone,
                          validatorMsg: 'Enter a valid 10-digit phone number',
                          regex: r'^[0-9]{10}$',
                          maxLength: 10,
                        ),
                        SizedBox(height: 24.0),
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          child: !_isOTPSent
                              ? _buildGradientButton(
                            key: ValueKey('sendOTP'),
                            text: 'Send OTP',
                            onPressed: _sendOTP,
                          )
                              : _buildOTPInputSection(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
