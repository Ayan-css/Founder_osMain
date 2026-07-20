import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/database/repositories/profile_repository.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ref.read(profileRepositoryProvider).getCurrentProfile();
    if (profile != null) {
      if (mounted) {
        setState(() {
          _nameController.text = profile.fullName ?? '';
          _businessNameController.text = profile.businessName ?? '';
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(profileRepositoryProvider).updateProfile(
        fullName: _nameController.text.trim(),
        businessName: _businessNameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeNotifierProvider);
    final themeNotifier = ref.read(themeNotifierProvider.notifier);

    // Filter themes for UI
    final availableThemes = AppThemeId.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Personal Info',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Business / Agency Name',
                    hintText: 'Enter business name',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save Profile'),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'App Theme & Color Scheme',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Theme Mode Switch
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: themeState.themeMode == ThemeMode.dark,
                  onChanged: (bool value) {
                    themeNotifier.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
                const SizedBox(height: 16),
                
                // Theme Selector Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 3,
                  ),
                  itemCount: availableThemes.length,
                  itemBuilder: (context, index) {
                    final theme = availableThemes[index];
                    final isSelected = themeState.themeId == theme;
                    
                    return InkWell(
                      onTap: () => themeNotifier.setTheme(theme),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary 
                                : Colors.grey.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) 
                              : Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          theme.displayName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }
}
