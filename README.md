# DevMirror by Redrope

<div align="center">
  <img src="assets/logo.png" alt="DevMirror Logo" width="120" />
  <h3>Local Dev Server on Your Phone with Zero Friction</h3>
  <p>Auto-discover running local development servers across Wi-Fi and stream them straight to your mobile device in 1-tap.</p>
  
  [![Website](https://img.shields.io/badge/Website-devmirror.red--rope.in-00FF66?style=flat-square)](https://devmirror.red-rope.in/)
  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
  [![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square&logo=android)](https://www.android.com/)
  [![Organization](https://img.shields.io/badge/Developed%20By-Redrope-black?style=flat-square)](https://devmirror.red-rope.in/)
</div>

---

## ⚡ Overview

**DevMirror** eliminates the tedious hassle of finding PC IPv4 addresses, checking port numbers, and manually typing IP addresses into your mobile browser every time you test responsive web designs.

Whether you're developing on **Vite, Next.js, Live Server, Flask, Django, Angular, or React**, DevMirror automatically scans every local network your phone is on, checks server reachability, extracts page titles, and launches your site inside Chrome Custom Tabs with full developer fidelity.

---

## 📥 Download

- **Android APK**: download the latest build from [devmirror.red-rope.in](https://devmirror.red-rope.in/).
- **Build from source**: see **Building & Running the Project** below.

---

## ✨ Features

- 📡 **Live Subnet Auto-Discovery**: Automatically discovers servers running on common web development ports (`3000`, `5173`, `5500`, `8000`, `8080`, `4200`, etc.) on every network your phone is connected to — Wi-Fi, Ethernet, hotspot, and USB tethering — scanning Wi-Fi first.
- 🖥️ **Live Scan Log**: Watch discovery happen in a terminal-style log as probed hosts, open ports, and page titles stream in.
- ⚡ **1-Tap Launch**: Launches directly using native Chrome Custom Tabs / In-App browser for top performance and full mobile browser compatibility.
- 🔌 **USB ADB Reverse Support**: Test with ultra-low latency over USB cable (`adb reverse tcp:<port> tcp:<port>`) without even needing Wi-Fi.
- 🎯 **Automatic HTML Title Fetching**: Automatically labels detected servers with the live HTML `<title>` of your project.
- 💾 **Connection History & Storage**: Easily save and manage recent connections with quick-reconnect and swipe-to-delete.
- 🌗 **Dark & Light Mode**: Clean, developer-tailored UI with custom mono typography and fluid theme switching.

---

## 🚀 How to Connect

### 1. Wireless (Same Wi-Fi) — *Recommended*
1. Connect both your phone and PC to the same Wi-Fi network.
2. Start your dev server with host-binding enabled:
   - **Vite**: `npx vite --host`
   - **Next.js**: `npm run dev -- -H 0.0.0.0`
   - **Live Server (VS Code)**: Click *"Go Live"* (binds automatically)
   - **Django / Python**: `python manage.py runserver 0.0.0.0:8000`
3. Open **DevMirror** on your phone — your dev server will appear under **LIVE SERVERS** automatically!

> 💡 Sharing your phone's hotspot or USB tethering with your PC works too: DevMirror scans every network the phone is on.

### 2. USB Cable (ADB Reverse)
1. Connect your phone to your PC via USB and enable USB Debugging.
2. In your PC terminal, forward the port:
   ```bash
   adb reverse tcp:5173 tcp:5173  # For Vite
   adb reverse tcp:3000 tcp:3000  # For Next.js
   adb reverse tcp:5500 tcp:5500  # For Live Server
   ```
3. In DevMirror, enter IP `127.0.0.1` and your port, then tap **Connect**.

### 3. Manual IP Lookup
1. Find your PC IPv4 address (`ipconfig` on Windows or `ifconfig` / `ip a` on macOS/Linux).
2. Enter your PC's IP and port into DevMirror's manual connect bar.

---

## 🛠️ Building & Running the Project

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) with Dart 3.12.2 or higher (developed on Flutter 3.44)
- Android SDK / Android Studio
- Java 17

### Installation
```bash
# Clone the repository
git clone https://github.com/VikramDevadiga/DevMirror.git
cd DevMirror

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### Building Release APK & AAB
```bash
# Build standalone Android APK
flutter build apk --release

# Build Android App Bundle (for Google Play)
flutter build appbundle --release
```

---

## 📦 Project Structure

```text
lib/
├── main.dart                           # App initialization & theme management
├── models/
│   └── server_connection.dart          # Server connection data models
├── screens/
│   ├── connect_screen.dart             # Main dashboard & live auto-discovery
│   ├── help_screen.dart                # Connection guides & instructions
│   └── webview_screen.dart             # Fallback in-app webview
├── services/
│   ├── browser_service.dart            # Chrome Custom Tabs & URL launcher
│   ├── connection_storage_service.dart # SharedPreferences persistent storage
│   ├── network_discovery_service.dart  # Multi-subnet port scanning engine
│   ├── reachability_service.dart       # HTTP socket ping & reachability checks
│   └── terminal_parser.dart            # Parses IPs & ports from terminal output
├── theme/
│   └── app_theme.dart                  # Custom design system & color schemes
└── widgets/
    └── scan_terminal.dart              # Terminal-style live scan log
```

---

## 📬 Contact & Support

Developed by **Redrope**.

- 🌐 **Website**: [devmirror.red-rope.in](https://devmirror.red-rope.in/)
- 📧 **Feedback & Inquiries**: `redropecompany@gmail.com`

---

<div align="center">
  <sub>Built with ❤️ by Redrope for developers everywhere.</sub>
</div>
