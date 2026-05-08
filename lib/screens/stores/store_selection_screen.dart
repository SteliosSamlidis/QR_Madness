import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/store_model.dart';
import '../../providers/auth_provider.dart' show AuthProvider;
import '../../services/store_service.dart';
import '../../widgets/app_snackbar.dart';
import '../entries/entries_screen.dart';
import '../users/users_screen.dart';

class StoreSelectionScreen extends StatefulWidget {
  const StoreSelectionScreen({super.key});

  @override
  State<StoreSelectionScreen> createState() => _StoreSelectionScreenState();
}

class _StoreSelectionScreenState extends State<StoreSelectionScreen> {
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Store'),
        centerTitle: true,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.people_outline),
              tooltip: 'Manage users',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsersScreen()),
              ),
            ),
        ],
      ),
      floatingActionButton: isAdmin
          ? Column(
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
            )
          : null,
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

  Future<void> _openStore(BuildContext context) async {
    if (store.hasPin) {
      final unlocked = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _PinEntryDialog(store: store),
      );
      if (unlocked != true || !context.mounted) return;
    }
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EntriesScreen(store: store)),
      );
    }
  }

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
        onTap: (!editMode) ? () => _openStore(context) : null,
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
                  tooltip: 'Edit',
                  onPressed: () => _showRenameDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(context),
                ),
              ] else ...[
                if (store.hasPin)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.lock_outline,
                        size: 16, color: Colors.grey[400]),
                  ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── PIN entry dialog (shown when opening a protected store) ────────────────────

class _PinEntryDialog extends StatefulWidget {
  final StoreModel store;
  const _PinEntryDialog({required this.store});

  @override
  State<_PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<_PinEntryDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _wrongPin = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (_wrongPin) setState(() => _wrongPin = false);
    setState(() {}); // redraw boxes
    if (_controller.text.length == 4) _verify();
  }

  void _verify() {
    if (_controller.text == widget.store.pin) {
      Navigator.pop(context, true);
    } else {
      setState(() => _wrongPin = true);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      title: Text('"${widget.store.name}"',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter PIN to open this store',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _focusNode.requestFocus(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _controller.text.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  width: 46,
                  height: 54,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _wrongPin
                          ? Colors.red
                          : filled
                              ? primary
                              : Colors.grey.shade300,
                      width: filled || _wrongPin ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: filled
                        ? primary.withAlpha(20)
                        : null,
                  ),
                  child: filled
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _wrongPin ? Colors.red : primary,
                            ),
                          ),
                        )
                      : null,
                );
              }),
            ),
          ),
          // Hidden field that receives keyboard input
          Offstage(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
            ),
          ),
          if (_wrongPin) ...[
            const SizedBox(height: 14),
            const Text('Incorrect PIN. Try again.',
                style: TextStyle(color: Colors.red, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
      ],
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
  late final TextEditingController _nameController;
  late final TextEditingController _pinController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _showPin = false;

  bool get _isEditing => widget.store != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store?.name ?? '');
    _pinController = TextEditingController(text: widget.store?.pin ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final pin = _pinController.text.trim();

    // Warn if no PIN set
    if (pin.isEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No PIN set'),
          content: const Text(
            'Without a PIN, anyone with access to the app can open this store.\n\n'
            'Do you want to continue without a PIN?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Add PIN'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue without PIN'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    setState(() => _saving = true);

    try {
      final pinValue = pin.isEmpty ? null : pin;
      if (_isEditing) {
        await StoreService().updateStore(
            widget.store!.id, _nameController.text.trim(), pinValue);
      } else {
        final uid = context.read<AuthProvider>().user?.uid ?? '';
        final store = StoreModel(
          id: '',
          name: _nameController.text.trim(),
          pin: pinValue,
          createdBy: uid,
          createdAt: DateTime.now(),
        );
        await StoreService().addStore(store);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.showError(
          context,
          _isEditing ? 'Failed to update store: $e' : 'Failed to create store: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit store' : 'New store'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _pinController,
              obscureText: !_showPin,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: 'PIN (optional)',
                hintText: 'Leave empty for no protection',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                      _showPin ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showPin = !_showPin),
                ),
              ),
              validator: (v) {
                if (v != null && v.isNotEmpty && v.length != 4) {
                  return 'PIN must be exactly 4 digits.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _saving ? null : _submit(),
            ),
          ],
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
