import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../providers/index.dart';
import '../theme/app_colors.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initializeControllers(UserProfile user) {
    if (!_isInitialized) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber;
      _isInitialized = true;
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = context.read<UserProvider>();
      final currentUser = userProvider.user!;
      
      final updatedUser = currentUser.copyWith(
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
      );

      final success = await userProvider.updateProfile(updatedUser);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado correctamente'),
              backgroundColor: AppColors.normal,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${userProvider.error}'),
              backgroundColor: AppColors.critical,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color indigoColor = Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F8),
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: indigoColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (userProvider.isLoading && userProvider.user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = userProvider.user;
          if (user == null) {
            return const Center(child: Text('No se pudo cargar el perfil'));
          }

          _initializeControllers(user);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Avatar Section
                  _buildAvatarHeader(user, indigoColor),
                  
                  const SizedBox(height: 32),

                  // Form Section
                  _buildFormCard(indigoColor, userProvider.isSaving),

                  const SizedBox(height: 40),

                  // Save Button
                  _buildSaveButton(indigoColor, userProvider.isSaving),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarHeader(UserProfile user, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.2), width: 4),
                image: const DecorationImage(
                  image: AssetImage('assets/images/bello.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.camera_alt_rounded, size: 20, color: color),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
        ),
        Text(
          user.role.toUpperCase(),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color.withOpacity(0.6), letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildFormCard(Color color, bool isSaving) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Nombre Completo',
            icon: Icons.person_outline_rounded,
            enabled: !isSaving,
            validator: (val) => val!.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _emailController,
            label: 'Correo Electrónico (Notificaciones)',
            icon: Icons.email_outlined,
            enabled: !isSaving,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val!.isEmpty) return 'Campo requerido';
              if (!val.contains('@')) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _phoneController,
            label: 'Teléfono (Alertas SMS)',
            icon: Icons.phone_android_rounded,
            enabled: !isSaving,
            keyboardType: TextInputType.phone,
            validator: (val) => val!.isEmpty ? 'Campo requerido' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1A237E)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(Color color, bool isSaving) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Guardar Cambivos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
