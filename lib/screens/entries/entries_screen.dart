import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:io';

import '../../models/entry_model.dart';
import '../../models/store_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/entry_service.dart';
import 'create_entry_screen.dart';
import 'entry_detail_screen.dart';

class EntriesScreen extends StatefulWidget {
  final StoreModel store;
  const EntriesScreen({super.key, required this.store});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  // null = show all statuses
  EntryStatus? _statusFilter;
  bool _mineOnly = false;
  bool _hasEntries = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  bool get _hasActiveFilter => _statusFilter != null || _mineOnly;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EntryModel> _applyFilters(List<EntryModel> all, String currentUid) {
    final query = _searchQuery.trim().toLowerCase();
    return all.where((e) {
      if (query.isNotEmpty) {
        final fullName = '${e.name} ${e.surname}'.toLowerCase();
        if (!fullName.contains(query)) return false;
      }
      if (_mineOnly) return e.createdBy == currentUid;
      if (_statusFilter != null && e.status != _statusFilter) return false;
      return true;
    }).toList();
  }

  void _clearFilters() => setState(() {
        _statusFilter = null;
        _mineOnly = false;
      });

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.store.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: _confirmSignOut,
          ),
        ],
      ),
      floatingActionButton: _hasEntries
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        CreateEntryScreen(storeId: widget.store.id)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New entry'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Search by name or surname…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),
          _FilterBar(
            statusFilter: _statusFilter,
            mineOnly: _mineOnly,
            hasActiveFilter: _hasActiveFilter,
            onStatusChanged: (v) => setState(() => _statusFilter = v),
            onMineOnlyChanged: (v) => setState(() => _mineOnly = v),
            onClearAll: _clearFilters,
          ),
          Expanded(
            child: StreamBuilder<List<EntryModel>>(
              stream: EntryService().getEntriesStream(widget.store.id),
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
                          Text(
                            'Could not load entries',
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check your connection and try again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final all = snapshot.data ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _hasEntries != all.isNotEmpty) {
                    setState(() => _hasEntries = all.isNotEmpty);
                  }
                });

                // No documents in the collection at all
                if (all.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 72, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No entries yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first entry to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateEntryScreen(
                                    storeId: widget.store.id),
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('New entry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filtered = _applyFilters(all, currentUid);

                // Documents exist but none match the active filters
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_list_off,
                              size: 56, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No matching entries',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting or clearing the filters.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear filters'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _EntryCard(
                    entry: filtered[index],
                    isOwn: filtered[index].createdBy == currentUid,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final EntryStatus? statusFilter;
  final bool mineOnly;
  final bool hasActiveFilter;
  final ValueChanged<EntryStatus?> onStatusChanged;
  final ValueChanged<bool> onMineOnlyChanged;
  final VoidCallback onClearAll;

  const _FilterBar({
    required this.statusFilter,
    required this.mineOnly,
    required this.hasActiveFilter,
    required this.onStatusChanged,
    required this.onMineOnlyChanged,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // ── Status chips ────────────────────────────────────────────────
            _StatusChoiceChip(
              label: 'All',
              selected: statusFilter == null,
              onSelected: (_) => onStatusChanged(null),
            ),
            const SizedBox(width: 8),
            _StatusChoiceChip(
              label: 'Pending',
              selected: statusFilter == EntryStatus.pending,
              selectedColor: Colors.orange,
              onSelected: (on) =>
                  onStatusChanged(on ? EntryStatus.pending : null),
            ),
            const SizedBox(width: 8),
            _StatusChoiceChip(
              label: 'Completed',
              selected: statusFilter == EntryStatus.completed,
              selectedColor: Colors.green,
              onSelected: (on) =>
                  onStatusChanged(on ? EntryStatus.completed : null),
            ),

            // ── Divider ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                height: 20,
                child: VerticalDivider(
                  color: Colors.grey.shade300,
                  thickness: 1,
                ),
              ),
            ),

            // ── Mine only ───────────────────────────────────────────────────
            FilterChip(
              label: const Text('My entries'),
              selected: mineOnly,
              onSelected: onMineOnlyChanged,
              avatar: const Icon(Icons.person_outline, size: 16),
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.primary,
              labelStyle: TextStyle(
                fontSize: 13,
                color: mineOnly ? colorScheme.primary : null,
                fontWeight:
                    mineOnly ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: mineOnly
                    ? colorScheme.primary.withAlpha(120)
                    : Colors.grey.shade300,
              ),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
            ),

            // ── Clear button (visible only when a filter is active) ─────────
            if (hasActiveFilter) ...[
              const SizedBox(width: 8),
              ActionChip(
                label: const Text('Clear'),
                avatar: const Icon(Icons.close, size: 14),
                onPressed: onClearAll,
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: Colors.grey.shade300),
                labelStyle:
                    const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? selectedColor;
  final ValueChanged<bool> onSelected;

  const _StatusChoiceChip({
    required this.label,
    required this.selected,
    this.selectedColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: selected ? color.withAlpha(30) : null,
      checkmarkColor: color,
      labelStyle: TextStyle(
        fontSize: 13,
        color: selected ? color : null,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? color.withAlpha(120) : Colors.grey.shade300,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

// ── Entry card ────────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final EntryModel entry;
  final bool isOwn;
  const _EntryCard({required this.entry, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final creatorLabel = isOwn ? 'You' : (entry.createdByEmail ?? entry.createdBy);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOwn
              ? Theme.of(context).colorScheme.primary.withAlpha(80)
              : Colors.grey.shade200,
          width: isOwn ? 1.5 : 1,
        ),
      ),
      color: isOwn ? Theme.of(context).colorScheme.primary.withAlpha(10) : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EntryDetailScreen(entry: entry),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Thumbnail(imageUrl: entry.firstImageUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.name} ${entry.surname}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    if (entry.telephone.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              entry.telephone,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                    ],
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 13,
                            color: isOwn
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            creatorLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: isOwn
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[500],
                              fontWeight:
                                  isOwn ? FontWeight.w600 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusChip(status: entry.status),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Image thumbnail ──────────────────────────────────────────────��──────────────

class _Thumbnail extends StatelessWidget {
  final String? imageUrl;
  const _Thumbnail({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 64,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? (imageUrl!.startsWith('http')
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                    errorBuilder: (context, err, stack) => _placeholder(),
                  )
                : Image.file(File(imageUrl!), fit: BoxFit.cover))
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 28),
    );
  }
}

// ── Status chip (display only) ────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final EntryStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status == EntryStatus.pending;
    final bgColor = isPending ? Colors.orange.shade50 : Colors.green.shade50;
    final borderColor =
        isPending ? Colors.orange.shade200 : Colors.green.shade200;
    final textColor =
        isPending ? Colors.orange.shade700 : Colors.green.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        isPending ? 'Pending' : 'Completed',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
