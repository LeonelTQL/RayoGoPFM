import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../themes/esquema_color.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/app_bottom_nav.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  void _showEditPhoneDialog(BuildContext context, String currentPhone) {
    final controller = TextEditingController(text: currentPhone);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EsquemaColor.surface,
        title: const Text('Actualizar Teléfono', style: TextStyle(color: EsquemaColor.textPrimary, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            style: const TextStyle(color: EsquemaColor.textPrimary),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              labelText: 'Número de teléfono',
              labelStyle: const TextStyle(color: EsquemaColor.textSecondary),
              hintText: 'Ej: 0991234567',
              hintStyle: const TextStyle(color: EsquemaColor.muted),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: EsquemaColor.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: EsquemaColor.primary),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().length != 10) {
                return 'El teléfono debe tener exactamente 10 dígitos.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: EsquemaColor.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EsquemaColor.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size(100, 40),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final authVm = context.read<AuthViewModel>();
              final success = await authVm.updatePhone(controller.text.trim());
              if (!context.mounted) return;
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Teléfono actualizado correctamente.'),
                    backgroundColor: EsquemaColor.success,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(authVm.error ?? 'Error al actualizar.'),
                    backgroundColor: EsquemaColor.danger,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
  void _showChangePasswordDialog(BuildContext context) {
    final user = context.read<AuthViewModel>().user;
    if (user == null) return;

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final authVm = context.watch<AuthViewModel>();
            return AlertDialog(
              backgroundColor: EsquemaColor.surface,
              title: Text(
                user.hasPassword ? 'Cambiar Contraseña' : 'Establecer Contraseña',
                style: const TextStyle(color: EsquemaColor.textPrimary, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user.hasPassword) ...[
                        TextFormField(
                          controller: currentPasswordController,
                          obscureText: obscureCurrent,
                          style: const TextStyle(color: EsquemaColor.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Contraseña actual',
                            labelStyle: const TextStyle(color: EsquemaColor.textSecondary),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: EsquemaColor.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: EsquemaColor.primary),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: EsquemaColor.muted,
                              ),
                              onPressed: () => setState(() => obscureCurrent = !obscureCurrent),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'La contraseña actual es obligatoria.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        style: const TextStyle(color: EsquemaColor.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          labelStyle: const TextStyle(color: EsquemaColor.textSecondary),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: EsquemaColor.line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: EsquemaColor.primary),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: EsquemaColor.muted,
                            ),
                            onPressed: () => setState(() => obscureNew = !obscureNew),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La nueva contraseña es obligatoria.';
                          }
                          if (value.length < 6) {
                            return 'Debe tener al menos 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        style: const TextStyle(color: EsquemaColor.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Confirmar nueva contraseña',
                          labelStyle: const TextStyle(color: EsquemaColor.textSecondary),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: EsquemaColor.line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: EsquemaColor.primary),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: EsquemaColor.muted,
                            ),
                            onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor confirma tu contraseña.';
                          }
                          if (value != newPasswordController.text) {
                            return 'Las contraseñas no coinciden.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: authVm.loading ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: EsquemaColor.muted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EsquemaColor.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(100, 40),
                  ),
                  onPressed: authVm.loading
                      ? null
                      : () async {
                    if (!formKey.currentState!.validate()) return;
                    final success = await authVm.changePassword(
                      currentPassword: user.hasPassword ? currentPasswordController.text : null,
                      newPassword: newPasswordController.text,
                    );
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contraseña actualizada correctamente.'),
                          backgroundColor: EsquemaColor.success,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(authVm.error ?? 'Error al actualizar contraseña.'),
                          backgroundColor: EsquemaColor.danger,
                        ),
                      );
                    }
                  },
                  child: authVm.loading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EsquemaColor.surface,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: EsquemaColor.danger, size: 28),
            SizedBox(width: 10),
            Text('¿Eliminar cuenta?', style: TextStyle(color: EsquemaColor.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          '¡Cuidado! Esta acción es definitiva e irreversible. Se borrarán permanentemente todos tus datos personales, direcciones e historial de pedidos del sistema.\n\n¿Realmente deseas continuar?',
          style: TextStyle(color: EsquemaColor.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: EsquemaColor.muted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EsquemaColor.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final authVm = context.read<AuthViewModel>();
              final success = await authVm.deleteAccount();
              if (!context.mounted) return;
              if (success) {
                Navigator.pop(context); // Close dialog
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (_) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tu cuenta ha sido eliminada del sistema.'),
                    backgroundColor: EsquemaColor.success,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(authVm.error ?? 'Error al eliminar cuenta.'),
                    backgroundColor: EsquemaColor.danger,
                  ),
                );
              }
            },
            child: const Text('Eliminar permanentemente', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    final canPop = Navigator.canPop(context);
    return Scaffold(
      appBar: canPop
          ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: EsquemaColor.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mi Perfil',
          style: TextStyle(color: EsquemaColor.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      )
          : null,
      bottomNavigationBar: user?.isClient == true ? const AppBottomNav(currentIndex: 3) : null,

      body: SafeArea(
        child: user == null
            ? const Center(child: Text('Sin sesión'))
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                children: [
                  // Encabezado de perfil elegante
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: EsquemaColor.primary.withOpacity(0.1),
                          child: const Icon(
                            Icons.person,
                            size: 56,
                            color: EsquemaColor.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            color: EsquemaColor.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: EsquemaColor.muted,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  
                  // Tarjeta de información de la cuenta
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: EsquemaColor.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: EsquemaColor.line, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información de la cuenta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: EsquemaColor.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _ProfileInfoRow(
                          icon: Icons.person_outline,
                          label: 'Nombre completo',
                          value: user.name,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(color: EsquemaColor.line, height: 1),
                        ),
                        _ProfileInfoRow(
                          icon: Icons.email_outlined,
                          label: 'Correo electrónico',
                          value: user.email,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(color: EsquemaColor.line, height: 1),
                        ),
                        _ProfileInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Teléfono',
                          value: user.phone.isNotEmpty ? user.phone : 'No registrado (Toca para agregar)',
                          onTap: () => _showEditPhoneDialog(context, user.phone),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(color: EsquemaColor.line, height: 1),
                        ),
                        _ProfileInfoRow(
                          icon: Icons.lock_outline,
                          label: 'Contraseña',
                          value: user.hasPassword ? '********' : 'Sin contraseña establecida (Toca para crear)',
                          onTap: () => _showChangePasswordDialog(context),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(color: EsquemaColor.line, height: 1),
                        ),
                        _ProfileInfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Rol de usuario',
                          value: _formatRole(user.role),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  
                  // Botón de Cerrar Sesión
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EsquemaColor.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        await context.read<AuthViewModel>().logout();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.login,
                            (_) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout, size: 22),
                      label: const Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  
                  // Botón de Eliminar Cuenta (Acción Disruptiva)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EsquemaColor.danger,
                        side: const BorderSide(color: EsquemaColor.danger, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _showDeleteAccountDialog(context),
                      icon: const Icon(Icons.delete_forever, size: 22),
                      label: const Text(
                        'Eliminar mi cuenta',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'cliente':
        return 'Cliente';
      case 'repartidor':
        return 'Repartidor';
      default:
        return role;
    }
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: EsquemaColor.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: EsquemaColor.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: EsquemaColor.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: EsquemaColor.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          const Icon(Icons.edit_outlined, size: 20, color: EsquemaColor.primary),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      );
    }
    return content;
  }
}
