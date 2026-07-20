import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../isar_service.dart';
import '../collections/profile_collection.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';

class ProfileRepository {
  final Isar _isar = IsarService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get the local profile for the current user
  Future<ProfileItem?> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return _isar.profileItems.filter().idEqualTo(user.id).findFirst();
  }

  /// Update the profile locally and sync to Supabase
  Future<void> updateProfile({
    String? fullName,
    String? businessName,
    String? avatarUrl,
    String? themeId,
    String? themeMode,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in to update profile');

    ProfileItem? profile = await getCurrentProfile();
    final now = DateTime.now();

    profile ??= ProfileItem()
        ..id = user.id
        ..email = user.email
        ..createdAt = now;

    if (fullName != null) profile.fullName = fullName;
    if (businessName != null) profile.businessName = businessName;
    if (avatarUrl != null) profile.avatarUrl = avatarUrl;
    if (themeId != null) profile.themeId = themeId;
    if (themeMode != null) profile.themeMode = themeMode;

    profile.updatedAt = now;
    profile.syncStatus = 'pendingUpdate';

    // Save locally
    await _isar.writeTxn(() async {
      await _isar.profileItems.put(profile!);
    });

    // Sync to Supabase
    try {
      await _supabase.from('profiles').upsert({
        'id': profile.id,
        if (fullName != null) 'full_name': fullName,
        if (businessName != null) 'business_name': businessName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (themeId != null) 'theme_id': themeId,
        if (themeMode != null) 'theme_mode': themeMode,
        'updated_at': now.toIso8601String(),
      });

      // Update sync status on success
      profile.syncStatus = 'synced';
      await _isar.writeTxn(() async {
        await _isar.profileItems.put(profile!);
      });
    } catch (e) {
      // It's okay if it fails, sync engine will catch it later if we implement queue
      // or we just let it retry next time.
    }
  }

  /// Fetch latest from Supabase and cache locally
  Future<void> fetchAndCacheProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        final profile = ProfileItem()
          ..id = response['id']
          ..fullName = response['full_name']
          ..businessName = response['business_name']
          ..email = response['email']
          ..avatarUrl = response['avatar_url']
          ..themeId = response['theme_id']
          ..themeMode = response['theme_mode']
          ..createdAt = DateTime.parse(response['created_at'])
          ..updatedAt = DateTime.parse(response['updated_at'])
          ..syncStatus = 'synced';

        await _isar.writeTxn(() async {
          await _isar.profileItems.put(profile);
        });
      }
    } catch (e) {
      // Ignore network errors
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final currentProfileProvider = FutureProvider<ProfileItem?>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  final isAuth = ref.watch(isAuthenticatedProvider);
  
  if (!isAuth) return null;
  
  // Try to fetch latest in background
  repo.fetchAndCacheProfile();
  
  // Return local immediately
  return repo.getCurrentProfile();
});
