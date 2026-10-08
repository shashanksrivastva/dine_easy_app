import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'package:dine_easy_app/theme/app_colors.dart';

class OtpScreen extends StatefulWidget {
  final String mobileNumber;
  final String verificationId;
  final int? resendToken;

  const OtpScreen({
    super.key,
    required this.mobileNumber,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();

  bool isLoading = false;
  bool isResending = false;
  late String currentVerificationId;
  int? currentResendToken;

  @override
  void initState() {
    super.initState();
    currentVerificationId = widget.verificationId;
    currentResendToken = widget.resendToken;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      _showMessage('Please enter a valid 6-digit OTP');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: currentVerificationId,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(userName: 'Guest'),
        ),
      );
    } on FirebaseAuthException catch (exception) {
      _showMessage(_errorMessage(exception));
    } catch (_) {
      _showMessage('Unable to verify OTP. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> resendOtp() async {
    setState(() {
      isResending = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.mobileNumber,
        forceResendingToken: currentResendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DashboardScreen(userName: 'Guest'),
            ),
          );
        },
        verificationFailed: (FirebaseAuthException exception) {
          _showMessage(_errorMessage(exception));
        },
        codeSent: (String verificationId, int? resendToken) {
          currentVerificationId = verificationId;
          currentResendToken = resendToken;
          _showMessage('OTP sent successfully.');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          currentVerificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (exception) {
      _showMessage(_errorMessage(exception));
    } catch (_) {
      _showMessage('Unable to resend OTP. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isResending = false;
        });
      }
    }
  }

  String _errorMessage(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-verification-code':
        return 'The OTP you entered is incorrect';
      case 'session-expired':
        return 'The verification code has expired. Please resend OTP.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return exception.message ?? 'Verification failed';
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 25),

              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.lightCream,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primaryOrange,
                  size: 30,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Verify your number',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'We have sent a 6-digit verification code to',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.greyText,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                widget.mobileNumber,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),

              const SizedBox(height: 35),

              const Text(
                'Enter OTP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  enabled: !isLoading && !isResending,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 10,
                  ),
                  decoration: const InputDecoration(
                    hintText: '• • • • • •',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      letterSpacing: 4,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading || isResending ? null : verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    disabledBackgroundColor:
                        AppColors.primaryOrange.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Verify & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 25),

              Center(
                child: TextButton(
                  onPressed: isLoading || isResending ? null : resendOtp,
                  child: Text(
                    isResending ? 'Sending OTP...' : 'Resend OTP',
                    style: const TextStyle(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Your information is secure',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
