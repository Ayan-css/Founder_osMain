# Production Deployment Guide

## Right Craft Media OS

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio or Android SDK
- Java 17+
- A Supabase project

---

## 1. Environment Setup

Create `.env` file in project root (DO NOT commit this):

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

---

## 2. Supabase Setup

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Run the schema from `supabase/schema.sql` in the SQL editor
3. Enable Email auth, Magic Link, and Google Sign-In under Authentication > Providers
4. Create storage buckets: `attachments`, `brand-assets`, `receipts`

---

## 3. Build APK (Debug)

```bash
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

---

## 4. Build APK (Release)

```bash
# Generate keystore (first time only)
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Create android/key.properties
echo "storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=/path/to/key.jks" > android/key.properties

# Build release APK
flutter build apk --release --target-platform android-arm64

# Build split APKs (smaller downloads)
flutter build apk --release --split-per-abi
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## 5. Build App Bundle (AAB) for Play Store

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## 6. Android Configuration

### app/build.gradle

```groovy
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.rightcraftmedia.os"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

## 7. App Icons

Using `flutter_launcher_icons` in pubspec.yaml:

```yaml
flutter_launcher_icons:
  android: true
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#0F0F14"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

Run: `flutter pub run flutter_launcher_icons`

---

## 8. Splash Screen

Using `flutter_native_splash`:

```yaml
flutter_native_splash:
  color: "#0F0F14"
  image: "assets/splash/splash_logo.png"
  android: true
```

Run: `flutter pub run flutter_native_splash:create`

---

## 9. ProGuard Rules

Create `android/app/proguard-rules.pro`:

```
-keep class io.flutter.** { *; }
-keep class io.isar.** { *; }
-dontwarn io.isar.**
```

---

## 10. Performance Optimization

- **Tree shaking**: Enabled by default in release builds
- **Code minification**: `minifyEnabled true` in build.gradle
- **Lazy loading**: Isar collections are loaded on demand
- **Image caching**: Use `cached_network_image` for remote images
- **Pagination**: Implement pagination for large lists

---

## 11. Pre-launch Checklist

- [ ] Remove all debug logs (`print()`, `debugPrint()`)
- [ ] Test on multiple Android versions (21-34)
- [ ] Test on phone AND tablet
- [ ] Test offline mode thoroughly
- [ ] Verify all CRUD operations
- [ ] Check dark/light mode on all screens
- [ ] Verify sync engine with Supabase
- [ ] Run `flutter analyze` for lint checks
- [ ] Run `flutter test` for unit tests
- [ ] Generate app icons and splash screen
- [ ] Set correct version in pubspec.yaml
- [ ] Configure signing for release build
