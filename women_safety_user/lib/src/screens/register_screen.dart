import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:women_safety_user/src/providers/auth_provider.dart' show AuthProvider;

import '../routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;
  String _selectedRole = 'user';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!mounted) return;
    
    // Validation
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('Please enter your name');
      return;
    }
    
    if (_phoneCtrl.text.trim().isEmpty) {
      _showError('Please enter your phone number');
      return;
    }
    
    if (_passCtrl.text.isEmpty) {
      _showError('Please enter a password');
      return;
    }
    
    if (_passCtrl.text != _confirmPassCtrl.text) {
      _showError('Passwords do not match');
      return;
    }
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _loading = true);
    
    try {
      await auth.register(
        _nameCtrl.text.trim(),
        _phoneCtrl.text.trim(),
        _passCtrl.text,
        _selectedRole,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registration successful!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      final route = auth.user?['role'] == 'parent' ? Routes.parentHome : Routes.userHome;
      Navigator.pushReplacementNamed(context, route);
    } catch (e) {
      if (!mounted) return;
      _showError('Registration failed: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              Colors.purple.shade400,
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
                  SizedBox(height: size.height * 0.05),
                  
                  // Header Section
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
                          Icons.person_add,
                          size: 40,
                          color: Colors.purple.shade400,
                        ),
                      ).animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        'Create Account',
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
                        'Join our safety community today',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ).animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),
                    ],
                  ),
                  
                  SizedBox(height: size.height * 0.04),
                  
                  // Registration Form Card
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
                        // Role Selection
                        Text(
                          'I am a',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedRole = 'user'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'user' ? Colors.purple.shade400 : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          color: _selectedRole == 'user' ? Colors.white : Colors.grey.shade600,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'User',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: _selectedRole == 'user' ? Colors.white : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedRole = 'parent'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'parent' ? Colors.purple.shade400 : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.family_restroom,
                                          color: _selectedRole == 'parent' ? Colors.white : Colors.grey.shade600,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Guardian',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: _selectedRole == 'parent' ? Colors.white : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate()
                          .fadeIn(delay: 600.ms, duration: 600.ms),
                        
                        const SizedBox(height: 24),
                        
                        // Name Input
                        _buildInputField(
                          label: 'Full Name',
                          controller: _nameCtrl,
                          icon: Icons.person,
                          hint: 'Enter your full name',
                          delay: 700,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Phone Input
                        _buildInputField(
                          label: 'Phone Number',
                          controller: _phoneCtrl,
                          icon: Icons.phone,
                          hint: '+919876543210',
                          keyboardType: TextInputType.phone,
                          delay: 800,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Password Input
                        _buildInputField(
                          label: 'Password',
                          controller: _passCtrl,
                          icon: Icons.lock,
                          hint: 'Create a strong password',
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          delay: 900,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Confirm Password Input
                        _buildInputField(
                          label: 'Confirm Password',
                          controller: _confirmPassCtrl,
                          icon: Icons.lock_outline,
                          hint: 'Confirm your password',
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          delay: 1000,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade400,
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
                                    'Create Account',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ).animate()
                          .fadeIn(delay: 1100.ms, duration: 600.ms)
                          .slideY(begin: 0.3, end: 0),
                        
                        const SizedBox(height: 24),
                        
                        // Login Link
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, Routes.login),
                            child: RichText(
                              text: TextSpan(
                                text: "Already have an account? ",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign In',
                                    style: GoogleFonts.poppins(
                                      color: Colors.purple.shade400,
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    required int delay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
              prefixIcon: Icon(icon, color: Colors.purple.shade400),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    ).animate()
      .fadeIn(delay: Duration(milliseconds: delay), duration: 600.ms)
      .slideX(begin: -0.2, end: 0);
  }
}