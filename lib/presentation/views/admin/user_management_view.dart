import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/app_user.dart';
import '../../viewmodels/auth_viewmodel.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  String? _updatingUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().getUsers();
    });
  }

  Future<void> _changeRole(AppUser user, String newRole) async {
    if (user.role == newRole) return;
    
    setState(() => _updatingUserId = user.id);
    
    final auth = context.read<AuthViewModel>();
    final ok = await auth.changeUserRole(user.id, newRole);
    
    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rol de ${user.name} actualizado a $newRole'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Error al cambiar el rol'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() => _updatingUserId = null);
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.amber.shade700;
      case 'repartidor': return Colors.deepOrange;
      default: return Colors.blue.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final users = authViewModel.users;
    final isLoading = authViewModel.loading && users.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          IconButton(
            onPressed: () => authViewModel.getUsers(),
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => authViewModel.getUsers(),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: users.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isUpdating = _updatingUserId == user.id;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: user.isAdmin ? Colors.amber : Colors.blueGrey.shade100,
                      backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                      child: user.avatarUrl == null 
                          ? Text(user.name[0].toUpperCase(), style: TextStyle(color: user.isAdmin ? Colors.white : Colors.blueGrey)) 
                          : null,
                    ),
                    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        const SizedBox(height: 6),
                        // Hacemos el badge del rol clicable para que sea más fácil de usar
                        GestureDetector(
                          onTap: user.role == 'admin' ? null : () => _showRolePicker(context, user),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getRoleColor(user.role).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _getRoleColor(user.role).withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user.role.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10, 
                                    color: _getRoleColor(user.role), 
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5
                                  ),
                                ),
                                if (user.role != 'admin') ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit, size: 10, color: _getRoleColor(user.role)),
                                ]
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: isUpdating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : user.role == 'admin'
                            ? const Icon(Icons.security, color: Colors.amber)
                            : IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _showRolePicker(context, user),
                              ),
                  );
                },
              ),
            ),
    );
  }

  void _showRolePicker(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cambiar rol de ${user.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Cliente'),
              selected: user.role == 'cliente',
              trailing: user.role == 'cliente' ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                Navigator.pop(context);
                _changeRole(user, 'cliente');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delivery_dining_outlined),
              title: const Text('Repartidor'),
              selected: user.role == 'repartidor',
              trailing: user.role == 'repartidor' ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                Navigator.pop(context);
                _changeRole(user, 'repartidor');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
