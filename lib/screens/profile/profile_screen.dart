import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'camera_screen.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String? _photoPath;
  final ImagePicker _picker = ImagePicker();
  bool _isEditing = false;

  final _nameController = TextEditingController(text: 'Firzatullah Ardana');
  final _emailController =
      TextEditingController(text: 'firzatullahardana@gmail.com');
  final _locationController = TextEditingController(text: '');
  final _apiUrlController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const String _keyPhotoPath = 'profile_photo_path';
  static const String _keyName = 'profile_name';
  static const String _keyEmail = 'profile_email';
  static const String _keyLocation = 'profile_location';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _photoPath = prefs.getString(_keyPhotoPath);
      _nameController.text =
          prefs.getString(_keyName) ?? 'Firzatullah Ardana';
      _emailController.text =
          prefs.getString(_keyEmail) ?? 'firzatullahardana@gmail.com';
      _locationController.text = prefs.getString(_keyLocation) ?? '';
      _apiUrlController.text = ApiService().baseUrl;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, _nameController.text);
    await prefs.setString(_keyEmail, _emailController.text);
    await prefs.setString(_keyLocation, _locationController.text);
    if (_photoPath != null) {
      await prefs.setString(_keyPhotoPath, _photoPath!);
    }
    await ApiService().setCustomBaseUrl(_apiUrlController.text.trim());
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (file == null) return; // user membatalkan

      // Salin file ke direktori permanen app
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          'profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(file.path).copy(
        '${appDir.path}/$fileName',
      );

      // Hapus foto profil lama jika ada
      if (_photoPath != null) {
        final oldFile = File(_photoPath!);
        if (await oldFile.exists()) {
          try {
            await oldFile.delete();
          } catch (_) {}
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPhotoPath, savedFile.path);
      setState(() {
        _photoPath = savedFile.path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Foto profil berhasil diperbarui!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses foto: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openInAppCamera() async {
    try {
      final String? photoPath = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const InAppCameraScreen()),
      );

      if (photoPath == null) return;

      // Hapus foto lama jika ada
      if (_photoPath != null) {
        final oldFile = File(_photoPath!);
        if (await oldFile.exists()) {
          try { await oldFile.delete(); } catch (_) {}
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPhotoPath, photoPath);
      setState(() => _photoPath = photoPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Foto profil berhasil diperbarui!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka kamera: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Keluar',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Apakah Anda yakin ingin keluar?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Keluar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Keluar',
            onPressed: _showLogoutDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // ─── Card Personal Information ───────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header card
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                        child: Row(
                          children: [
                            // Expanded agar teks mengambil sisa ruang
                            const Expanded(
                              child: Text(
                                'Personal Information',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Edit Profile / Save Button
                            GestureDetector(
                              onTap: () async {
                                if (_isEditing) {
                                  await _saveData();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                            'Profil berhasil disimpan!'),
                                        backgroundColor: AppColors.success,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(AppRadius.md),
                                        ),
                                      ),
                                    );
                                  }
                                }
                                setState(() => _isEditing = !_isEditing);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: _isEditing
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF3DDAB4),
                                            Color(0xFF58A6FF)
                                          ],
                                        )
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFF7C3AED),
                                            Color(0xFF9F5CF5)
                                          ],
                                        ),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isEditing
                                          ? Icons.check_rounded
                                          : Icons.edit_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _isEditing ? 'Simpan' : 'Edit',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Cancel (X) — hanya muncul saat mode edit
                            if (_isEditing) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() => _isEditing = false);
                                  _loadSavedData();
                                },
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: AppColors.textSecondary,
                                      size: 14),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Avatar + Info baris atas
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar Column
                            Column(
                              children: [
                                // Avatar
                                Stack(
                                  children: [
                                    Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2A1F4E),
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.lg),
                                        border: Border.all(
                                          color: const Color(0xFF7C3AED)
                                              .withValues(alpha: 0.6),
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.lg),
                                        child: _photoPath != null &&
                                                File(_photoPath!).existsSync()
                                            ? Image.file(
                                                File(_photoPath!),
                                                fit: BoxFit.cover,
                                                width: 90,
                                                height: 90,
                                              )
                                            : const Icon(
                                                Icons.person_rounded,
                                                color: Color(0xFF7C3AED),
                                                size: 46,
                                              ),
                                      ),
                                    ),
                                    // Kamera ikon kecil di pojok
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _openInAppCamera(),
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF7C3AED),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Tombol Upload & Kamera
                                Row(
                                  children: [
                                    _buildPhotoButton(
                                      label: 'Upload',
                                      icon: Icons.upload_rounded,
                                      onTap: () =>
                                          _pickImage(ImageSource.gallery),
                                    ),
                                    const SizedBox(width: 6),
                                    _buildPhotoButton(
                                      label: 'Kamera',
                                      icon: Icons.camera_alt_rounded,
                                      color: const Color(0xFF7C3AED),
                                      onTap: () =>
                                          _openInAppCamera(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: AppSpacing.md),
                            // Info Detail
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoField(
                                    icon: Icons.person_outline_rounded,
                                    label: 'FULL NAME',
                                    controller: _nameController,
                                    isEditing: _isEditing,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _buildInfoField(
                                    icon: Icons.badge_outlined,
                                    label: 'ROLE',
                                    staticValue: 'Member',
                                    isEditing: false,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Row email & lokasi
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildInfoField(
                                icon: Icons.email_outlined,
                                label: 'EMAIL ADDRESS',
                                controller: _emailController,
                                isEditing: _isEditing,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _buildInfoField(
                                icon: Icons.location_on_outlined,
                                label: 'LOCATION',
                                controller: _locationController,
                                isEditing: _isEditing,
                                hint: '—',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Footer card: Member since
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Member since 5 Juni 2026',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ─── Card API Server Configuration ────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Konfigurasi Server API',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sesuaikan alamat API backend Django Anda.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoField(
                        icon: Icons.link_rounded,
                        label: 'BASE URL API',
                        controller: _apiUrlController,
                        isEditing: _isEditing,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ─── Tombol Keluar ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showLogoutDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withValues(alpha: 0.15),
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text(
                      'Keluar dari Aplikasi',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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

  Widget _buildPhotoButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color color = const Color(0xFF374151),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color == const Color(0xFF374151)
              ? AppColors.surface
              : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: color == const Color(0xFF374151)
                ? AppColors.border
                : color.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required IconData icon,
    required String label,
    TextEditingController? controller,
    String? staticValue,
    bool isEditing = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        isEditing && controller != null
            ? TextField(
                controller: controller,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  hintText: hint ?? label,
                  hintStyle:
                      const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                  ),
                ),
              )
            : Text(
                controller?.text.isNotEmpty == true
                    ? controller!.text
                    : (staticValue ?? hint ?? '—'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ],
    );
  }
}
