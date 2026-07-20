# App Icon

Place your app icon PNG file here with the name:

```
app_icon.png
```

## Requirements

- **Format:** PNG (with transparency if desired)
- **Size:** 1024×1024 pixels (recommended)
- **Name:** Must be `app_icon.png` (matches `pubspec.yaml` config)

## How to Generate Icons

After placing your PNG:

```bash
flutter pub run flutter_launcher_icons
```

This will auto-generate all required icon sizes for both Android and iOS.
