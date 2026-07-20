#!/bin/bash
echo "Installing Flutter..."
if cd flutter; then
  git pull
  cd ..
else
  git clone https://github.com/flutter/flutter.git -b stable
fi

export PATH="$PATH:`pwd`/flutter/bin"
flutter config --enable-web
flutter pub get

echo "Patching Isar files for Web JS compatibility..."
python3 patch_isar_web.py

echo "Generating .env file for Flutter Web..."
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env

echo "Building Flutter Web..."
flutter build web --release
