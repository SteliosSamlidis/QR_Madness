import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/entry_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/entry_service.dart';
import '../../services/image_service.dart';
import '../../widgets/app_snackbar.dart';

// ── Internal draft model ───────────────────────────────────────────────────────

class _PhotoDraft {
  final File? file;
  final String? existingUrl;
  final TextEditingController descController;

  _PhotoDraft({this.file, this.existingUrl, String description = ''})
      : descController = TextEditingController(text: description);

  void dispose() => descController.dispose();

  bool get hasImage => file != null || (existingUrl?.isNotEmpty ?? false);
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class CreateEntryScreen extends StatefulWidget {
  final EntryModel? entry;
  final String? storeId;
  const CreateEntryScreen({super.key, this.entry, this.storeId});

  @override
  State<CreateEntryScreen> createState() => _CreateEntryScreenState();
}

class _CreateEntryScreenState extends State<CreateEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _telephoneController;

  final _imageService = ImageService();
  final _entryService = EntryService();

  late final List<_PhotoDraft> _photos;
  bool _saving = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _nameController = TextEditingController(text: e?.name ?? '');
    _surnameController = TextEditingController(text: e?.surname ?? '');
    _telephoneController =
        TextEditingController(text: e?.telephone ?? '');

    // Pre-populate photos from existing entry.
    _photos = e != null
        ? e.photos
            .map((p) =>
                _PhotoDraft(existingUrl: p.url, description: p.description))
            .toList()
        : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _telephoneController.dispose();
    for (final p in _photos) {
      p.dispose();
    }
    super.dispose();
  }

  // ── Photo picking ────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final file = source == ImageSource.camera
        ? await _imageService.pickFromCamera()
        : await _imageService.pickFromGallery();
    if (file != null) {
      setState(() => _photos.add(_PhotoDraft(file: file)));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeDraft(int index) {
    final draft = _photos[index];
    setState(() => _photos.removeAt(index));
    draft.dispose();
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_photos.isEmpty) {
      AppSnackBar.showError(context, 'Please add at least one photo.');
      return;
    }

    setState(() => _saving = true);

    try {
      final currentUser = context.read<AuthProvider>().user!;

      // Upload any new files; keep existing URLs as-is.
      // In bypass-auth mode, store the local file path to skip Firebase Storage.
      final uploadedPhotos = <EntryPhoto>[];
      for (final draft in _photos) {
        if (draft.file != null) {
          final url = kBypassAuth
              ? draft.file!.path
              : await _imageService.uploadEntryImage(
                  draft.file!, currentUser.uid);
          uploadedPhotos.add(EntryPhoto(
              url: url, description: draft.descController.text.trim()));
        } else if (draft.existingUrl != null) {
          uploadedPhotos.add(EntryPhoto(
              url: draft.existingUrl!,
              description: draft.descController.text.trim()));
        }
      }

      final entry = EntryModel(
        id: widget.entry?.id ?? '',
        storeId: widget.entry?.storeId ?? widget.storeId ?? '',
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        telephone: _telephoneController.text.trim(),
        photos: uploadedPhotos,
        status: widget.entry?.status ?? EntryStatus.pending,
        createdBy: widget.entry?.createdBy ?? currentUser.uid,
        createdByEmail: widget.entry?.createdByEmail ?? currentUser.email,
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await _entryService.updateEntry(entry.id, entry);
      } else {
        await _entryService.addEntry(entry);
      }

      if (mounted) {
        Navigator.pop(context, _isEditing ? entry : null);
        if (!_isEditing) {
          AppSnackBar.showSuccess(context, 'Entry saved successfully.');
        }
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Failed to save entry: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit entry' : 'New entry'),
            centerTitle: true,
            leading: TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            leadingWidth: 72,
            actions: [
              TextButton(
                onPressed: _saving ? null : _save,
                child: const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Photos section ─────────────────────────────────────────
                  ..._photos.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PhotoCard(
                          draft: e.value,
                          onRemove: _saving ? null : () => _removeDraft(e.key),
                          enabled: !_saving,
                        ),
                      )),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _showImageSourceSheet,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Add photo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Text fields ────────────────────────────────────────────
                  _buildField(
                    controller: _nameController,
                    label: 'Name',
                    icon: Icons.person_outlined,
                    action: TextInputAction.next,
                    validator: _requiredValidator('Name'),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _surnameController,
                    label: 'Surname',
                    icon: Icons.person_outlined,
                    action: TextInputAction.next,
                    validator: _requiredValidator('Surname'),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _telephoneController,
                    label: 'Telephone (optional)',
                    icon: Icons.phone_outlined,
                    action: TextInputAction.done,
                    keyboardType: TextInputType.phone,
                    onFieldSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Text(
                      _isEditing ? 'Save changes' : 'Save entry',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_saving)
          const ModalBarrier(dismissible: false, color: Colors.black26),
        if (_saving)
          Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_isEditing ? 'Saving changes…' : 'Saving entry…'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputAction action,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: action,
      textCapitalization: TextCapitalization.words,
      keyboardType: keyboardType,
      enabled: !_saving,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: validator,
    );
  }

  FormFieldValidator<String> _requiredValidator(String fieldName) => (v) {
        if (v == null || v.trim().isEmpty) return '$fieldName is required.';
        return null;
      };
}

// ── Photo card ─────────────────────────────────────────────────────────────────

class _PhotoCard extends StatelessWidget {
  final _PhotoDraft draft;
  final VoidCallback? onRemove;
  final bool enabled;

  const _PhotoCard(
      {required this.draft, required this.onRemove, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: draft.file != null
                    ? Image.file(draft.file!, fit: BoxFit.cover)
                    : Image.network(draft.existingUrl!, fit: BoxFit.cover),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: TextField(
              controller: draft.descController,
              enabled: enabled,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Description (e.g. drug name)',
                prefixIcon: Icon(Icons.label_outline),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
