import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/app_snackbar.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthProvider>().user!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: UserService().getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load users: ${snapshot.error}'),
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _UserTile(
              user: users[i],
              isSelf: users[i].uid == currentUid,
            ),
          );
        },
      ),
    );
  }
}

class _UserTile extends StatefulWidget {
  final UserModel user;
  final bool isSelf;
  const _UserTile({required this.user, required this.isSelf});

  @override
  State<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<_UserTile> {
  bool _updating = false;

  Future<void> _toggleRole() async {
    final newRole =
        widget.user.isAdmin ? UserRole.employee : UserRole.admin;
    final label = newRole == UserRole.admin ? 'administrator' : 'employee';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change role'),
        content: Text(
          'Make "${widget.user.email}" a${newRole == UserRole.admin ? 'n' : ''} $label?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Make $label'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _updating = true);
    try {
      await UserService().updateRole(widget.user.uid, newRole);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Failed to update role: $e');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user.isAdmin;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isAdmin
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.grey.shade100,
              child: Icon(
                isAdmin
                    ? Icons.admin_panel_settings_outlined
                    : Icons.person_outlined,
                color: isAdmin
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.user.email,
                      style:
                          const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    isAdmin ? 'Administrator' : 'Employee',
                    style: TextStyle(
                      fontSize: 12,
                      color: isAdmin
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isSelf)
              Text('(you)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]))
            else if (_updating)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              TextButton(
                onPressed: _toggleRole,
                child: Text(isAdmin ? 'Make employee' : 'Make admin',
                    style: TextStyle(
                        color: isAdmin ? Colors.orange : null)),
              ),
          ],
        ),
      ),
    );
  }
}
