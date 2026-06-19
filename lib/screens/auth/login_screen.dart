import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../dashboard/dashboard_screen.dart';
import '../../services/api_service.dart';

enum AuthFormType { none, login, register }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  AuthFormType _formType = AuthFormType.none;
  bool _isLoading = false;

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _bgAnimController;
  late AnimationController _popupAnimController;
  late Animation<double> _popupScaleAnim;
  late Animation<double> _popupFadeAnim;

  late AnimationController _welcomeAnimController;
  late Animation<double> _welcomeFadeAnim;
  late Animation<Offset> _welcomeSlideAnim;

  // Persistent team member photos
  final List<String?> _teamPhotos = List.filled(5, null);

  @override
  void initState() {
    super.initState();
    // Background glowing circles float animation
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    // Popup card scale/fade transitions
    _popupAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _popupScaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _popupAnimController, curve: Curves.easeOutBack),
    );
    _popupFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _popupAnimController, curve: Curves.easeOut),
    );

    // Welcome elements entrance animation
    _welcomeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _welcomeFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeAnimController, curve: Curves.easeOut),
    );
    _welcomeSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _welcomeAnimController, curve: Curves.easeOut));

    _welcomeAnimController.forward();
    _loadTeamPhotos();
  }

  Future<void> _loadTeamPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int i = 0; i < 5; i++) {
        _teamPhotos[i] = prefs.getString('team_member_photo_$i');
      }
    });
  }

  Future<void> _pickTeamMemberPhoto(int index) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (file == null) return;

      // Save file permanently
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'team_member_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(file.path).copy('${appDir.path}/$fileName');

      // Update state and save
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('team_member_photo_$index', savedFile.path);

      setState(() {
        _teamPhotos[index] = savedFile.path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto anggota tim berhasil diperbarui!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah foto: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _popupAnimController.dispose();
    _welcomeAnimController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showForm(AuthFormType type) {
    setState(() {
      _formType = type;
    });
    _popupAnimController.forward();
  }

  void _hideForm() {
    _popupAnimController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _formType = AuthFormType.none;
        });
      }
    });
  }

  void _switchTo(AuthFormType type) {
    _popupAnimController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _formType = type;
        });
        _popupAnimController.forward();
      }
    });
  }

  void _login() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ApiService().login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
          transitionsBuilder: (context, anim, secondaryAnim, child) {
            return FadeTransition(opacity: anim, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
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

  void _register() async {
    if (!_registerFormKey.currentState!.validate()) return;

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

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
          transitionsBuilder: (context, anim, secondaryAnim, child) {
            return FadeTransition(opacity: anim, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF060913),
      body: Stack(
        children: [
          // 1. Animated Glow Blobs (Lively Ambient Lighting)
          AnimatedBuilder(
            animation: _bgAnimController,
            builder: (context, child) {
              final val = _bgAnimController.value;
              return Stack(
                children: [
                  Positioned(
                    top: -100 + (val * 120),
                    left: -120 + (val * 80),
                    child: Container(
                      width: 340,
                      height: 340,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
                            blurRadius: 120,
                            spreadRadius: 60,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 200 + (val * 100),
                    right: -100 + (val * 120),
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF3DDAB4).withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3DDAB4).withValues(alpha: 0.15),
                            blurRadius: 100,
                            spreadRadius: 50,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Scrollable Welcome + About Us + Team sections
          SafeArea(
            child: FadeTransition(
              opacity: _welcomeFadeAnim,
              child: SlideTransition(
                position: _welcomeSlideAnim,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Section 1: Hero Landing Screen (Height bounded)
                      SizedBox(
                        height: (screenHeight - 80).clamp(0.0, double.infinity),
                        child: Column(
                          children: [
                            // Top Mini Navigation Bar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        color: Color(0xFFC084FC),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'IC Pipeline',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _showForm(AuthFormType.login),
                                    icon: const Icon(Icons.login_rounded, size: 16, color: AppColors.primary),
                                    label: const Text(
                                      'Masuk',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(flex: 2),
                            
                            // Floating Glassmorphic Logo Card "Intelligence Creation"
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(AppRadius.xl),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                                            blurRadius: 15,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome_rounded,
                                        color: Color(0xFFC084FC),
                                        size: 36,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'INTELLIGENCE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 3.0,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ShaderMask(
                                      shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                                      child: const Text(
                                        'CREATION',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 6.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const Spacer(flex: 3),
                            
                            // Scroll indicator
                            const Icon(
                              Icons.keyboard_double_arrow_down_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Geser ke bawah untuk Tentang Kami',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                            const Spacer(flex: 1),
                            
                            // Welcome Bottom Panel Sheet
                            Container(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 24, AppSpacing.lg, 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B0E17).withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, -5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'AI Pipeline Manager',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Kelola dan awasi pipeline data AI Anda dengan mudah, cepat, dan terintegrasi.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomButton(
                                          label: 'Masuk',
                                          isOutlined: true,
                                          onPressed: () => _showForm(AuthFormType.login),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: CustomButton(
                                          label: 'Daftar',
                                          onPressed: () => _showForm(AuthFormType.register),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Section 2: Tentang Kami
                      _buildTentangKamiSection(),
                      
                      const SizedBox(height: 32),
                      
                      // Section 3: Tim Kami
                      _buildTimKamiSection(),
                      
                      const SizedBox(height: 64),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Form Popup Overlay (Blur backdrop + Animated Center Card)
          if (_formType != AuthFormType.none)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _popupFadeAnim,
                builder: (context, child) {
                  return Opacity(
                    opacity: _popupFadeAnim.value,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 8.0 * _popupFadeAnim.value,
                          sigmaY: 8.0 * _popupFadeAnim.value,
                        ),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          alignment: Alignment.center,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: ScaleTransition(
                              scale: _popupScaleAnim,
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: _buildPopupForm(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTentangKamiSection() {
    final List<Map<String, dynamic>> points = [
      {
        'num': '1. AI Technology',
        'desc': 'Platform dengan teknologi AI terbaru untuk pengelolaan data dan model.',
        'icon': Icons.psychology_rounded,
      },
      {
        'num': '2. Keamanan Data',
        'desc': 'Data dan model AI dilindungi dengan sistem keamanan terbaik.',
        'icon': Icons.shield_rounded,
      },
      {
        'num': '3. Responsive',
        'desc': 'Tampilan menyesuaikan di desktop, tablet, dan smartphone.',
        'icon': Icons.devices_rounded,
      },
      {
        'num': '4. Update Berkala',
        'desc': 'Konten dan fitur diupdate secara berkala.',
        'icon': Icons.update_rounded,
      },
      {
        'num': '5. Pencarian Cerdas',
        'desc': 'Sistem pencarian advanced untuk menemukan data.',
        'icon': Icons.search_rounded,
      },
      {
        'num': '6. Kolaborasi Tim',
        'desc': 'Fitur kolaborasi untuk bekerja bersama tim.',
        'icon': Icons.groups_rounded,
      },
      {
        'num': '7. User-Friendly',
        'desc': 'Antarmuka yang intuitif dan mudah digunakan.',
        'icon': Icons.forum_rounded,
      },
      {
        'num': '8. Support 24/7',
        'desc': 'Tim support siap membantu kapan saja.',
        'icon': Icons.headset_mic_rounded,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const Text(
            'Tentang Kami',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '8 Poin Tentang Intelligence Creation',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          
          // Grid layout of 8 items
          Column(
            children: List.generate((points.length / 2).ceil(), (rowIndex) {
              final firstIndex = rowIndex * 2;
              final secondIndex = firstIndex + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(child: _buildPointCard(points[firstIndex])),
                    const SizedBox(width: 12),
                    Expanded(
                      child: secondIndex < points.length
                          ? _buildPointCard(points[secondIndex])
                          : const SizedBox(),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPointCard(Map<String, dynamic> point) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(point['icon'] as IconData, color: const Color(0xFFC084FC), size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            point['num'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            point['desc'] as String,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimKamiSection() {
    final List<Map<String, String>> members = [
      {'name': 'Firzatullah Tri Ardana', 'role': 'Project Leader'},
      {'name': 'Ratu Rahma Alya Darajati', 'role': 'Designer'},
      {'name': 'Garda Yuda Wijaksana', 'role': 'Backend Developer'},
      {'name': 'Ahmad Ibnu Bahtuta', 'role': 'Frontend Developer'},
      {'name': 'Turke', 'role': 'Quality Assurance'},
    ];

    return Column(
      children: [
        const Text(
          'Tim Kami',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Anggota Kelompok',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 10),
        ShaderMask(
          shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
          child: const Text(
            'Intelligence Creation Team',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 14, color: AppColors.primary.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            const Text(
              'Klik foto untuk mengupload gambar anggota tim',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Horizontal scrolling list of team member cards
        SizedBox(
          height: 185,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isHighlighted = index == 3; // Ahmad Ibnu Bahtuta highlighted in screenshot
              return Container(
                width: 145,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isHighlighted 
                        ? const Color(0xFF7C3AED).withValues(alpha: 0.6) 
                        : AppColors.border,
                    width: isHighlighted ? 1.5 : 0.5,
                  ),
                  boxShadow: isHighlighted ? [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ] : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar with upload capability
                    GestureDetector(
                      onTap: () => _pickTeamMemberPhoto(index),
                      child: Stack(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                              border: Border.all(color: Colors.white24, width: 1.5),
                            ),
                            child: ClipOval(
                              child: _teamPhotos[index] != null &&
                                      File(_teamPhotos[index]!).existsSync()
                                  ? Image.file(
                                      File(_teamPhotos[index]!),
                                      fit: BoxFit.cover,
                                      width: 64,
                                      height: 64,
                                    )
                                  : const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF7C3AED),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Name
                    Text(
                      member['name']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Role
                    Text(
                      member['role']!,
                      style: const TextStyle(
                        color: Color(0xFF3DDAB4),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopupForm() {
    final isLogin = _formType == AuthFormType.login;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF131826).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Popup Header: Form Title & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isLogin ? 'Selamat Datang' : 'Buat Akun Baru',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              GestureDetector(
                onTap: _hideForm,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isLogin
                ? 'Masuk ke akun Anda untuk melanjutkan'
                : 'Isi data berikut untuk mendaftar',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),

          // Forms
          isLogin ? _buildLoginForm() : _buildRegisterForm(),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
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
          const SizedBox(height: 18),
          CustomTextField(
            label: 'Kata Sandi',
            hint: 'Masukkan kata sandi',
            controller: _passwordController,
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
              if (v.length < 6) return 'Minimal 6 karakter';
              return null;
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Lupa kata sandi?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          CustomButton(
            label: 'Masuk',
            onPressed: _login,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Belum punya akun? ',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              GestureDetector(
                onTap: () => _switchTo(AuthFormType.register),
                child: const Text(
                  'Daftar',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        children: [
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 24),
          CustomButton(
            label: 'Daftar',
            onPressed: _register,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Sudah punya akun? ',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              GestureDetector(
                onTap: () => _switchTo(AuthFormType.login),
                child: const Text(
                  'Masuk',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
