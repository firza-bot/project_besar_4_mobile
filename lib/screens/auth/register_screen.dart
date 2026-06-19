import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/api_service.dart';
import '../dashboard/dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ApiService().register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran berhasil! Akun Anda aktif dan otomatis masuk.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to dashboard directly because registration auto-logs in
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Buat Akun Baru',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Isi data berikut untuk mendaftar',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 36),
                    // Nama
                    CustomTextField(
                      label: 'Nama Lengkap',
                      hint: 'Masukkan nama lengkap',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Nama wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Email
                    CustomTextField(
                      label: 'Email',
                      hint: 'nama@email.com',
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email wajib diisi';
                        if (!v.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Password
                    CustomTextField(
                      label: 'Kata Sandi',
                      hint: 'Minimal 6 karakter',
                      controller: _passwordController,
                      obscureText: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
                        if (v.length < 6) return 'Minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Confirm Password
                    CustomTextField(
                      label: 'Konfirmasi Kata Sandi',
                      hint: 'Ulangi kata sandi',
                      controller: _confirmPasswordController,
                      obscureText: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Konfirmasi kata sandi wajib diisi';
                        if (v != _passwordController.text) return 'Kata sandi tidak cocok';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // Register Button
                    CustomButton(
                      label: 'Daftar',
                      onPressed: _register,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 24),
                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Sudah punya akun? ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
