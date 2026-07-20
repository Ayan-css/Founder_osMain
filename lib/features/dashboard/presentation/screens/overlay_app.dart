import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/database/repositories/task_repository.dart';
import '../../../../services/database/repositories/lead_repository.dart';
import '../../../../services/database/repositories/outreach_repository.dart';
import '../../../../services/widget_service.dart';

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getThemePair(AppThemeId.darkProfessional).dark,
      color: Colors.transparent, // Ensures the Android window remains transparent
      home: const Scaffold(
        backgroundColor: Colors.transparent, // Transparent scaffold
        body: QuickAddOverlayScreen(),
      ),
    );
  }
}

class QuickAddOverlayScreen extends ConsumerStatefulWidget {
  const QuickAddOverlayScreen({super.key});

  @override
  ConsumerState<QuickAddOverlayScreen> createState() => _QuickAddOverlayScreenState();
}

class _QuickAddOverlayScreenState extends ConsumerState<QuickAddOverlayScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String _type = 'task'; // task, lead, outreach

  @override
  void initState() {
    super.initState();
    // Parse the deep link initial route if available
    final route = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    if (route.contains('lead')) {
      _type = 'lead';
    } else if (route.contains('outreach')) {
      _type = 'outreach';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      SystemNavigator.pop();
      return;
    }
    setState(() => _isLoading = true);

    try {
      if (_type == 'task') {
        await ref.read(taskRepositoryProvider).create(
          title: text,
          priority: 'Medium',
        );
      } else if (_type == 'lead') {
        await ref.read(leadRepositoryProvider).create(
          name: text,
          leadSource: 'Quick Add',
        );
      } else if (_type == 'outreach') {
        await ref.read(outreachRepositoryProvider).create(
          name: text,
          platform: 'Other',
          status: 'Not Replied',
        );
      }
      
      // Update the widgets immediately
      await WidgetService.syncWidgets();
      
    } catch (e) {
      debugPrint('Error saving in overlay: $e');
    }

    // Close the transparent activity
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    String hint = 'Add a new task...';
    if (_type == 'lead') hint = 'Add a new lead...';
    if (_type == 'outreach') hint = 'Add a new outreach prospect...';

    return GestureDetector(
      onTap: () => SystemNavigator.pop(), // Close on tap outside
      child: Container(
        color: Colors.black54, // Dimming effect over the Android home screen
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {}, // Prevent tap from closing when clicking the dialog itself
          child: Container(
            margin: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: hint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                      icon: Icon(Icons.send_rounded, color: colors.primary),
                      onPressed: _submit,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
