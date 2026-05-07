import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/store_model.dart';
import '../../providers/auth_provider.dart' show AuthProvider;
import '../../services/store_service.dart';
import '../../widgets/app_snackbar.dart';
import '../entries/entries_screen.dart';

class StoreSelectionScreen extends StatefulWidget {
  const StoreSelectionScreen({super.key});

  @override
  State<StoreSelectionScreen> createState() => _StoreSelectionScreenState();
}

class _StoreSelectionScreenState extends State<StoreSelectionScreen> {
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Store'),
        centerTitle: true,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'edit',
            onPressed: () => setState(() => _editMode = !_editMode),
            icon: Icon(_editMode ? Icons.check : Icons.edit_outlined),
            label: Text(_editMode ? 'Done' : 'Edit'),
            backgroundColor: _editMode
                ? Colors.green
                : Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: _editMode
                ? Colors.white
                : Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => _showCreateStoreDialog(context),
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('New store'),
          ),
        ],
      ),
      body: StreamBuilder<List<StoreModel>>(
        stream: StoreService().getStoresStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_outlined,
                        size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text('Could not load stores'),
                  ],
                ),
              ),
            );
          }

          final stores = snapshot.data ?? [];

          if (stores.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.store_outlined,
                        size: 72, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No stores yet',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first store to get started.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _showCreateStoreDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('New store'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: stores.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _StoreCard(
              store: stores[index],
              editMode: _editMode,
            ),
          );
        },
      ),
    );
  }

  void _showCreateStoreDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => const _StoreNameDialog(),
    );
  }
}

// ── Store card ─────────────────────────────────────────────────────────────────

class _StoreCard extends StatelessWidget {
  final StoreModel store;
  final bool editMode;
  const _StoreCard({required this.store, required this.editMode});

  Future<void> _showRenameDialog(BuildContext context) async {
    showDialog<void>(
      context: context,
      builder: (ctx) => _StoreNameDialog(store: store),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete store'),
        content: Text(
          'Are you sure you want to delete "${store.name}"? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await StoreService().deleteStore(store.id);
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Failed to delete store: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: editMode
            ? null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EntriesScreen(store: store)),
                ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.store_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  store.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (editMode) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Rename',
                  onPressed: () => _showRenameDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(context),
                ),
              ] else
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Create / rename dialog ─────────────────────────────────────────────────────

class _StoreNameDialog extends StatefulWidget {
  final StoreModel? store; // null = create mode
  const _StoreNameDialog({this.store});

  @override
  State<_StoreNameDialog> createState() => _StoreNameDialogState();
}

class _StoreNameDialogState extends State<_StoreNameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  bool get _isEditing => widget.store != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.store?.name ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      if (_isEditing) {
        await StoreService()
            .updateStoreName(widget.store!.id, _controller.text.trim());
      } else {
        final uid = context.read<AuthProvider>().user?.uid ?? '';
        final store = StoreModel(
          id: '',
          name: _controller.text.trim(),
          createdBy: uid,
          createdAt: DateTime.now(),
        );
        await StoreService().addStore(store);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.showError(context,
            _isEditing ? 'Failed to rename store: $e' : 'Failed to create store: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Rename store' : 'New store'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Store name',
            prefixIcon: Icon(Icons.store_outlined),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Name is required.' : null,
          onFieldSubmitted: (_) => _saving ? null : _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(_isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
