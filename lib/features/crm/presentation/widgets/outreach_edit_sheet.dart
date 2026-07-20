import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/database/collections/outreach_collection.dart';
import '../../../../services/database/repositories/outreach_repository.dart';
import '../../../../services/database/repositories/campaign_repository.dart';
import '../../../../core/extensions/context_extensions.dart';

const outreachPlatforms = ['LinkedIn', 'Email', 'Instagram', 'WhatsApp', 'Cold Call', 'Door to Door', 'Other'];
const outreachStatuses = ['To Contact', 'Not Replied', 'Replied', 'Meeting Booked', 'Converted', 'Not Interested'];

void showOutreachAddEditSheet(BuildContext context, WidgetRef ref, OutreachItem? editing) {
  final nameCtrl = TextEditingController(text: editing?.name ?? '');
  final companyCtrl = TextEditingController(text: editing?.company ?? '');
  final contactDetailCtrl = TextEditingController(text: editing?.contactDetail ?? '');
  final notesCtrl = TextEditingController(text: editing?.notes ?? '');
  String platform = editing?.platform ?? outreachPlatforms.first;
  String status = editing?.status ?? outreachStatuses.first;
  String priority = editing?.priority ?? 'Medium';
  String? campaignId = editing?.campaignId;
  DateTime? followUpDate = editing?.followUpDate;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  editing == null ? 'Log Outreach' : 'Edit Outreach',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Prospect Name *', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: companyCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Company', prefixIcon: Icon(Icons.business_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactDetailCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Detail', prefixIcon: Icon(Icons.contact_mail_outlined), helperText: 'Phone, Email, Instagram username, Map link, etc.'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: platform,
                  decoration: const InputDecoration(labelText: 'Platform', prefixIcon: Icon(Icons.share_outlined)),
                  items: outreachPlatforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setSheetState(() => platform = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.flag_outlined)),
                  items: outreachStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setSheetState(() => status = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.notes_outlined)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Priority', prefixIcon: Icon(Icons.star_outline)),
                  items: ['Low', 'Medium', 'High'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setSheetState(() => priority = v!),
                ),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, _) {
                    final campaigns = ref.watch(allCampaignsProvider).valueOrNull ?? [];
                    return DropdownButtonFormField<String?>(
                      value: campaignId,
                      decoration: const InputDecoration(labelText: 'Campaign', prefixIcon: Icon(Icons.campaign_outlined)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ...campaigns.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (v) => setSheetState(() => campaignId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(
                    followUpDate != null
                        ? 'Follow-up: ${followUpDate!.day}/${followUpDate!.month}/${followUpDate!.year}'
                        : 'Set Follow-up Date',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: followUpDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setSheetState(() => followUpDate = null),
                        )
                      : null,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: followUpDate ?? DateTime.now().add(const Duration(days: 3)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setSheetState(() => followUpDate = picked);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Consumer(
                    builder: (context, ref, _) => FilledButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) {
                          context.showSnackBar('Prospect name is required', isError: true);
                          return;
                        }
                        final repo = ref.read(outreachRepositoryProvider);
                        if (editing == null) {
                          await repo.create(
                            name: nameCtrl.text.trim(),
                            company: companyCtrl.text.trim().isEmpty ? null : companyCtrl.text.trim(),
                            platform: platform,
                            status: status,
                            contactDetail: contactDetailCtrl.text.trim().isEmpty ? null : contactDetailCtrl.text.trim(),
                            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                            followUpDate: followUpDate,
                            campaignId: campaignId,
                            priority: priority,
                          );
                        } else {
                          editing.name = nameCtrl.text.trim();
                          editing.company = companyCtrl.text.trim().isEmpty ? null : companyCtrl.text.trim();
                          editing.platform = platform;
                          editing.status = status;
                          editing.contactDetail = contactDetailCtrl.text.trim().isEmpty ? null : contactDetailCtrl.text.trim();
                          editing.notes = notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();
                          editing.followUpDate = followUpDate;
                          editing.campaignId = campaignId;
                          editing.priority = priority;
                          await repo.update(editing);
                        }
                        ref.invalidate(allOutreachProvider);
                        ref.invalidate(monthlyOutreachCountProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(editing == null ? 'Log Entry' : 'Save Changes'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
