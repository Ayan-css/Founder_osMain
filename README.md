# FounderOS 🚀

Welcome to **FounderOS**, the ultimate all-in-one operating system designed specifically for founders, agency owners, and entrepreneurs. Built from the ground up to replace fragmented toolchains, FounderOS gives you complete control over your CRM, finances, daily focus, and cold outreach—all in one beautifully designed, lightning-fast application.

![FounderOS](https://img.shields.io/badge/Status-Active-success.svg) ![Flutter](https://img.shields.io/badge/Built_with-Flutter-02569B?logo=flutter) ![Supabase](https://img.shields.io/badge/Powered_by-Supabase-3ECF8E?logo=supabase)

---

## ✨ Features

- **📊 Advanced CRM & Outreach Engine:** Track prospects, manage sales pipelines with a visual Kanban board, log interaction timelines, and manage follow-ups.
- **💸 Finance & Invoicing:** Generate professional PDF invoices, track revenue across multiple currencies, and manage transactions seamlessly.
- **🎯 Focus & Deep Work:** Integrated Pomodoro timers and deep work tracking to ensure you hit your daily productivity targets.
- **📓 Journal & Knowledge Base:** Document your founder journey, track mental models, and build a second brain.
- **🔔 Intelligent Notifications:** Local and system-level push notifications to ensure you never miss a critical follow-up or meeting.

## 🛠 Tech Stack

- **Frontend:** [Flutter](https://flutter.dev/) (Cross-platform: Android, iOS, Web, macOS, Windows, Linux)
- **Local Database:** [Isar](https://isar.dev/) (Blazing fast local-first NoSQL database)
- **Cloud Backend:** [Supabase](https://supabase.com/) (PostgreSQL cloud sync & realtime backend)
- **State Management:** [Riverpod](https://riverpod.dev/)

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable)
- [Supabase Account](https://supabase.com) (for cloud sync)

### 1. Clone the repository
```bash
git clone https://github.com/Ayan-css/Founder_osMain.git
cd Founder_osMain
```

### 2. Configure Environment Variables
Create a `.env` file in the root directory (this file is git-ignored for security):
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run the App
To run the app locally on your machine or emulator:
```bash
flutter run
```

---

## 🌐 Web Deployment (Vercel)

FounderOS includes a custom `build.sh` script to handle WebAssembly (Wasm) and JavaScript compilation limitations related to the local Isar database. 

To deploy to Vercel via GitHub:
1. Connect your repository to Vercel.
2. Under **Build and Output Settings**, override the Build Command to: `./build.sh`
3. Set the Output Directory to: `build/web`
4. Deploy!

---

## 🤝 Contributing

FounderOS is built to scale. If you're a developer looking to add features or fix bugs, please submit a pull request or open an issue!

## 📄 License
This project is proprietary and confidential.

---
*Built with ❤️ for founders who want to build the future.*
