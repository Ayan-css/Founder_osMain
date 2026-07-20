import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../../services/database/repositories/outreach_repository.dart';
import '../../../../services/database/repositories/outreach_activity_repository.dart';
import '../../../../services/database/collections/outreach_collection.dart';
import '../../../../core/extensions/context_extensions.dart';

class OutreachDetailScreen extends ConsumerWidget {
  final String id;
  const OutreachDetailScreen({super.key, required this.id});

  Future<void> _launchUrl(String urlStr) async {
    final uri = Uri.tryParse(urlStr);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _tapToAction(OutreachItem item) {
    if (item.contactDetail == null || item.contactDetail!.isEmpty) return;
    String contact = item.contactDetail!;
    if (item.platform == 'Email' || contact.contains('@')) {
      _launchUrl('mailto:$contact');
    } else if (item.platform == 'Cold Call' || item.platform == 'WhatsApp') {
      // Very basic phone check
      final phone = contact.replaceAll(RegExp(r'[^0-9+]'), '');
      _launchUrl('tel:$phone');
    } else if (contact.startsWith('http')) {
      _launchUrl(contact);
    }
  }

  void _showAddActivitySheet(BuildContext context, WidgetRef ref, String outreachId) {
    final typeCtrl = TextEditingController(text: 'Note');
    final descCtrl = TextEditingController();
    final types = ['Note', 'Email', 'Call', 'LinkedIn', 'Meeting', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log Activity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: typeCtrl.text,
                decoration: const InputDecoration(labelText: 'Type'),
                items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setSheetState(() => typeCtrl.text = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await ref.read(outreachActivityRepositoryProvider).create(
                      outreachItemId: outreachId,
                      type: typeCtrl.text,
                      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Activity'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final outreachItems = ref.watch(allOutreachProvider);

    return outreachItems.when(
      data: (items) {
        final item = items.where((i) => i.id == id).firstOrNull;
        if (item == null) {
          return Scaffold(appBar: AppBar(title: const Text('Details')), body: const Center(child: Text('Not found')));
        }

        final activitiesStream = ref.watch(outreachActivityRepositoryProvider).watchForOutreachItem(id);

        return Scaffold(
          appBar: AppBar(
            title: Text(item.name),
            actions: [
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {
                // To keep it simple, we don't open the edit sheet here, 
                // but we could push an edit route or pop back to main outreach screen.
                context.pop();
              }),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                          if (item.company != null) Text(item.company!, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(item.status, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Info Cards
                _InfoCard(label: 'Platform', value: item.platform),
                _InfoCard(label: 'Priority', value: item.priority),
                if (item.contactDetail != null) Row(
                  children: [
                    Expanded(child: _InfoCard(label: 'Contact', value: item.contactDetail!)),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.open_in_new, size: 20),
                      onPressed: () => _tapToAction(item),
                      tooltip: 'Tap to Action',
                    ),
                  ],
                ),
                if (item.followUpDate != null) _InfoCard(label: 'Follow-up', value: DateFormat.yMMMd().format(item.followUpDate!)),
                if (item.notes != null) ...[
                  const SizedBox(height: 16),
                  Text('Notes', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(item.notes!),
                ],
                
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Interaction Timeline', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Log'),
                      onPressed: () => _showAddActivitySheet(context, ref, id),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Activities
                StreamBuilder(
                  stream: activitiesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('No activities logged yet.', style: TextStyle(fontStyle: FontStyle.italic));
                    
                    final activities = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final act = activities[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(act.type, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(DateFormat('MMM d, h:mm a').format(act.timestamp), style: theme.textTheme.labelSmall),
                                  ],
                                ),
                                if (act.description != null) ...[
                                  const SizedBox(height: 8),
                                  Text(act.description!),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCard({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
