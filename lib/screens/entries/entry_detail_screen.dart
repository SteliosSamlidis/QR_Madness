import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/entry_model.dart';
import '../../services/entry_service.dart';
import '../../widgets/app_snackbar.dart';
import 'create_entry_screen.dart';

class EntryDetailScreen extends StatefulWidget {
  final EntryModel entry;
  const EntryDetailScreen({super.key, required this.entry});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  final _service = EntryService();
  bool _updating = false;
  late EntryModel _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  // ── Delete ───────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry'),
        content: Text(
          'Are you sure you want to delete the entry for '
          '"${_entry.name} ${_entry.surname}"? This cannot be undone.',
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

    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteEntry(_entry.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Failed to delete entry: $e');
    }
  }

  // ── Photo stage toggle ───────────────────────────────────────────────────────

  Future<void> _togglePhotoDone(int index) async {
    if (_updating) return;
    setState(() => _updating = true);

    try {
      final updatedPhotos = List<EntryPhoto>.from(_entry.photos);
      updatedPhotos[index] =
          updatedPhotos[index].copyWith(done: !updatedPhotos[index].done);

      final allDone = updatedPhotos.every((p) => p.done);
      final newStatus =
          allDone ? EntryStatus.completed : EntryStatus.pending;

      final updatedEntry =
          _entry.copyWith(photos: updatedPhotos, status: newStatus);

      await _service.updateEntry(_entry.id, updatedEntry);

      if (mounted) {
        setState(() => _entry = updatedEntry);
        if (allDone) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Failed to update: $e');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_entry.name} ${_entry.surname}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit entry',
            onPressed: () => Navigator.push<EntryModel>(
              context,
              MaterialPageRoute(
                  builder: (_) => CreateEntryScreen(entry: _entry)),
            ).then((updated) {
              if (updated != null) setState(() => _entry = updated);
            }),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete entry',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._buildPhotoStages(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Patient',
                    value: '${_entry.name} ${_entry.surname}',
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.numbers_outlined,
                    label: 'Prescription number',
                    value: _entry.prescriptionNumber,
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.schedule_outlined,
                    label: 'Created',
                    value: _formatDate(_entry.createdAt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Photo stages ─────────────────────────────────────────────────────────────

  List<Widget> _buildPhotoStages() {
    if (_entry.photos.isEmpty) {
      return [
        Container(
          width: double.infinity,
          height: 280,
          color: Colors.grey.shade100,
          child: Icon(Icons.image_outlined,
              size: 80, color: Colors.grey.shade300),
        ),
      ];
    }

    return _entry.photos.asMap().entries.map((e) {
      final index = e.key;
      final photo = e.value;
      final label = _entry.photos.length > 1 ? 'Photo ${index + 1}' : null;

      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo label for multi-photo entries
            if (label != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
              ),

            // Zoomable photo
            InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: _buildPhotoImage(photo.url),
            ),

            // Description + stage toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: photo.description.isNotEmpty
                        ? Text(
                            photo.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 12),
                  _StageChip(
                    done: photo.done,
                    updating: _updating,
                    onTap: () => _togglePhotoDone(index),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildPhotoImage(String url) {
    if (!url.startsWith('http')) {
      return Image.file(File(url),
          width: double.infinity, fit: BoxFit.contain);
    }
    return Image.network(
      url,
      width: double.infinity,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : SizedBox(
              height: 280,
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
      errorBuilder: (context, err, stack) => Container(
        height: 280,
        color: Colors.grey.shade100,
        child: Icon(Icons.broken_image_outlined,
            size: 80, color: Colors.grey.shade300),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Stage chip ────────────────────────────────────────────────────────────────

class _StageChip extends StatelessWidget {
  final bool done;
  final bool updating;
  final VoidCallback onTap;

  const _StageChip(
      {required this.done, required this.updating, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = done ? Colors.green : Colors.orange;

    return GestureDetector(
      onTap: updating ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: updating
              ? Colors.grey.shade100
              : color.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: updating ? Colors.grey.shade300 : color.withAlpha(120),
          ),
        ),
        child: updating
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.grey.shade400),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 15,
                    color: color.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    done ? 'Done' : 'Not done',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color.shade700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}
