import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:women_safety_user/src/providers/auth_provider.dart';

import '../routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  bool _usePassword = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!mounted) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _loading = true);
    try {
      await auth.sendOtp(_phoneCtrl.text.trim());
      setState(() => _otpSent = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP sent successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Send OTP failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (!mounted) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _loading = true);
    try {
      await auth.verifyOtp(_phoneCtrl.text.trim(), _otpCtrl.text.trim());
      if (!mounted) return;
      final route = auth.user?['role'] == 'parent' ? Routes.parentHome : Routes.userHome;
      Navigator.pushReplacementNamed(context, route);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verify failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loginWithPassword() async {
    if (!mounted) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _loading = true);
    try {
      await auth.login(_phoneCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      final route = auth.user?['role'] == 'parent' ? Routes.parentHome : Routes.userHome;
      Navigator.pushReplacementNamed(context, route);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink.shade400,
              Colors.pink.shade300,
              Colors.white,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.08),
                  
                  // Welcome Section
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.security,
                          size: 40,
                          color: Colors.pink.shade400,
                        ),
                      ).animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        'Welcome Back!',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Sign in to continue your safety journey',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ).animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),
                    ],
                  ),
                  
                  SizedBox(height: size.height * 0.06),
                  
                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Login Method Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _usePassword = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: !_usePassword ? Colors.pink.shade400 : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'OTP Login',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: !_usePassword ? Colors.white : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _usePassword = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _usePassword ? Colors.pink.shade400 : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Password',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: _usePassword ? Colors.white : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate()
                          .fadeIn(delay: 600.ms, duration: 600.ms),
                        
                        const SizedBox(height: 24),
                        
                        // Phone Input
                        Text(
                          'Phone Number',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.poppins(),
                            decoration: InputDecoration(
                              hintText: '+919876543210',
                              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                              prefixIcon: Icon(Icons.phone, color: Colors.pink.shade400),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ).animate()
                          .fadeIn(delay: 800.ms, duration: 600.ms)
                          .slideX(begin: -0.2, end: 0),
                        
                        const SizedBox(height: 20),
                        
                        // Conditional Input Fields
                        if (_usePassword) ...[
                          Text(
                            'Password',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: _passwordCtrl,
                              obscureText: true,
                              style: GoogleFonts.poppins(),
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                                prefixIcon: Icon(Icons.lock, color: Colors.pink.shade400),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ).animate()
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: -0.2, end: 0),
                        ] else if (_otpSent) ...[
                          Text(
                            'Enter OTP',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: _otpCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.poppins(),
                              decoration: InputDecoration(
                                hintText: '123456',
                                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                                prefixIcon: Icon(Icons.security, color: Colors.pink.shade400),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ).animate()
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: -0.2, end: 0),
                        ],
                        
                        const SizedBox(height: 32),
                        
                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : () {
                              if (_usePassword) {
                                _loginWithPassword();
                              } else if (_otpSent) {
                                _verifyOtp();
                              } else {
                                _sendOtp();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink.shade400,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _usePassword 
                                        ? 'Login' 
                                        : _otpSent 
                                            ? 'Verify OTP' 
                                            : 'Send OTP',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ).animate()
                          .fadeIn(delay: 1000.ms, duration: 600.ms)
                          .slideY(begin: 0.3, end: 0),
                        
                        const SizedBox(height: 24),
                        
                        // Register Link
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(context, Routes.register),
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: GoogleFonts.poppins(
                                      color: Colors.pink.shade400,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate()
                          .fadeIn(delay: 1200.ms, duration: 600.ms),
                      ],
                    ),
                  ).animate()
                    .fadeIn(delay: 600.ms, duration: 800.ms)
                    .slideY(begin: 0.3, end: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}