<div align="center">

# 🎵 Scenery Sync

**AI-Powered Music Recommendation Based on Real-World Scenery**

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Next.js](https://img.shields.io/badge/Next.js-14-000000?logo=next.js&logoColor=white)](https://nextjs.org)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![License](https://img.shields.io/badge/License-Private-red)](#license)

*Snap a photo of your surroundings, let AI analyze the scene, and discover the perfect soundtrack for the moment.*

[Features](#-features) · [Tech Stack](#-tech-stack) · [Getting Started](#-getting-started) · [Architecture](#-architecture) · [Contributing](#-contributing)

</div>

---

## 📖 About

**Scenery Sync** is a cross-platform music ecosystem that combines **AI-powered scenery analysis** with **music streaming**. The platform consists of:

| Component | Technology | Description |
|---|---|---|
| 📱 **Mobile/Desktop App** | Flutter (Dart) | Music streaming app with scenery-based AI recommendations |
| 🖥️ **Admin Web Portal** | Next.js 14 (TypeScript) | Dashboard for Admin (manage users, tracks, system) and Artist (upload & manage music) |

### 🌟 How It Works

1. 📸 **Capture** — Take a photo of your surroundings (sky, beach, forest, city, rain...)
2. 🤖 **Analyze** — Google ML Kit identifies elements in the scene on-device
3. 🎶 **Recommend** — AI curates music from multiple sources matching the atmosphere
4. 🔊 **Enhance** — Ambient sounds blend with music for an immersive experience
5. 🧠 **Learn** — The system adapts recommendations based on your preferences over time

---

## ✨ Features

### Core — Scenery-Based Music Recommendation
- 📷 Real-time camera capture or gallery image selection
- 🏷️ On-device image analysis via **Google ML Kit Image Labeling**
- 🎵 Multi-source music matching (Deezer, Jamendo, Firebase library)
- 🌊 Ambient sound mixing (Pixabay, Freesound) for immersive experience
- 📈 Adaptive learning from user preferences via keyword weighting

### Music Streaming
- 🎧 Stream from **Deezer** (charts, search, radio, genres)
- 🎼 Creative Commons tracks from **Jamendo**
- 🎤 Internal library managed by Artists/Admins (Firebase + Cloudinary)
- 📥 Offline download support with **Hive** local storage
- 📋 Queue management, shuffle, repeat modes

### AI Assistant
- 🤖 **Gemini-powered chatbot** for music discovery and conversation
- 🔍 Find similar songs, explore lyrics meaning
- 🎮 Interactive music quizzes
- 💬 24-hour conversation history with session management

### Player Experience
- 🎨 Audio Visualizer with real-time animations
- 🎛️ Built-in Equalizer
- ⏰ Sleep Timer
- 📝 Lyrics display (plain & synced modes)
- 🏝️ Dynamic Island-style floating mini player

### Personalization & Social
- 📂 Playlist creation and management
- ❤️ Favorites collection
- 🕐 Recently played history
- 👤 Profile customization with avatar upload
- 🌙 Dark / Light theme toggle
- 🌐 Multi-language support (Vietnamese, English)

### Authentication
- 📧 Email/Password
- <img src="https://www.google.com/favicon.ico" width="14"> Google Sign-In
- <img src="https://www.facebook.com/favicon.ico" width="14"> Facebook Login

### Admin Web Portal
- 📊 Dashboard with analytics charts (Recharts)
- 👥 User management (ban/unban, role assignment)
- 🎵 Track management (hide/show, delete)
- 📤 CSV/JSON data export

### Artist Portal
- ⬆️ Upload tracks with metadata (audio, artwork, lyrics via Cloudinary)
- 📈 Personal analytics (play counts, listener stats)
- ✏️ Edit/manage own tracks
- 👤 Artist profile management

---

## 🛠️ Tech Stack

### Mobile/Desktop Client

| Category | Technology |
|---|---|
| Framework | **Flutter** (Dart SDK ^3.8.1) |
| State Management | **Provider** |
| Audio Playback | **just_audio** + **audio_session** |
| Local Storage | **Hive** (downloads) · **SharedPreferences** (settings) |
| Camera & Image | **camera** · **image_picker** · **flutter_image_compress** |
| ML/AI (on-device) | **Google ML Kit** Image Labeling |
| AI Chatbot | **Google Generative AI** (Gemini) |
| Firebase | **firebase_core** · **firebase_auth** · **cloud_firestore** |
| Auth Providers | **google_sign_in** · **flutter_facebook_auth** |
| Networking | **http** · **dio** |
| Localization | **easy_localization** |
| Font | **Plus Jakarta Sans** (Google Fonts) |

### Admin Web Dashboard

| Category | Technology |
|---|---|
| Framework | **Next.js 14** (App Router) |
| UI | **React 18** · **TypeScript** |
| Charts | **Recharts** |
| Backend SDK | **Firebase JS SDK** |
| Hosting | **Netlify** |
| Font | **Inter** (Google Fonts CDN) |

### Backend & External Services

| Service | Purpose |
|---|---|
| **Firebase Auth** | Authentication (Email, Google, Facebook) |
| **Cloud Firestore** | NoSQL database with RBAC security rules |
| **Cloudinary** | Media storage (audio, images, lyrics) |
| **Deezer API** | Music charts, search, radio (public) |
| **Jamendo API** | Creative Commons background music |
| **Pixabay Sound API** | Ambient / environmental sounds |
| **Freesound API** | Ambient / environmental sounds |
| **Google Gemini API** | AI chatbot & music assistant |
| **Google ML Kit** | On-device image labeling |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ^3.8.1
- [Node.js](https://nodejs.org/) >= 18 (for Admin Web)
- [Firebase CLI](https://firebase.google.com/docs/cli) (optional, for rules deployment)
- Android Studio / Xcode (for mobile emulators)

### Clone the Repository

```bash
git clone https://github.com/Quan-2004/Scenery_Sync.git
cd Scenery_Sync
```

### 📱 Running the Flutter App

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Configure environment:**
   - Create `.env.local.json` in the project root with your API keys:
     ```json
     {
       "PIXABAY_API_KEY": "your_pixabay_key",
       "FREESOUND_API_KEY": "your_freesound_key",
       "GEMINI_API_KEY": "your_gemini_key"
     }
     ```

3. **Run the app:**
   ```bash
   flutter run \
     --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
     --dart-define=CLOUDINARY_UPLOAD_PRESET=your_upload_preset
   ```

   > **💡 Tip:** Use the **"scenery_sync (Cloudinary)"** launch configuration in VS Code for quicker setup.

### 🖥️ Running the Admin Web Dashboard

1. **Navigate to the web directory:**
   ```bash
   cd admin-web
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Configure environment:**
   - Create `admin-web/.env.local` with your Firebase Web SDK config.

4. **Start the dev server:**
   ```bash
   npm run dev
   ```
   The dashboard will be available at **http://localhost:3001**

### 🚀 Deploy the Admin Web

The Admin Web is configured for **Netlify** deployment:
- Config file: `admin-web/netlify.toml`
- Auto-deploy via Git integration

---

## 🏗️ Architecture

### Project Structure

```
Scenery_Sync/
├── lib/                          # Flutter source code
│   ├── main.dart                 # Entry point, providers setup
│   ├── config/                   # App configuration
│   ├── models/                   # Data models (Track, Artist, Album, etc.)
│   ├── services/                 # Business logic layer
│   │   ├── firebase_service.dart # Auth + Firestore CRUD
│   │   ├── audio_player_service.dart  # Singleton music player
│   │   ├── gemini_service.dart   # AI chatbot service
│   │   ├── deezer_service.dart   # Deezer API integration
│   │   ├── jamendo_service.dart  # Jamendo API integration
│   │   ├── ambient_sound_service.dart # Pixabay + Freesound
│   │   └── ...
│   ├── screens/                  # UI screens (32+ screens)
│   ├── widgets/                  # Reusable UI components
│   ├── theme/                    # App theming (colors, styles)
│   └── utils/                    # Utility helpers
│
├── admin-web/                    # Next.js 14 Admin Dashboard
│   ├── app/
│   │   ├── login/                # Auth page
│   │   ├── admin/                # Admin portal (dashboard, users, tracks)
│   │   └── artist/               # Artist portal (dashboard, tracks, analytics, profile)
│   ├── lib/                      # Shared logic (Firebase, queries, exports)
│   └── styles/                   # Global CSS
│
├── assets/                       # Images, translations (vi.json, en.json)
├── firestore.rules               # Firestore security rules (RBAC)
└── firebase.json                 # Firebase project configuration
```

### Role-Based Access Control (RBAC)

The system uses **3 roles** stored in Firestore `users/{uid}.role`:

| Role | Permissions |
|---|---|
| **User** | Stream music, manage personal playlists/favorites, use AI chatbot, request Artist upgrade |
| **Artist** | All User permissions + upload/manage own tracks, access Artist Portal |
| **Admin** | Full access — manage all users, tracks, system stats, approve artist requests |

### Core Flow — Scenery → Music

```
📷 Camera/Gallery
    → 🏷️ ML Kit Image Labeling (on-device)
    → 🧮 Weighted keyword processing (aliases + learned preferences)
    → 🔄 Parallel API calls:
        ├── Deezer → matching tracks
        ├── Jamendo → background music
        ├── Firebase → internal library
        └── Pixabay/Freesound → ambient sounds
    → 🎵 Curated results → Auto-play
    → 🧠 Save learned keywords for future improvement
```

---

## 📁 Design Documents

The project includes comprehensive design documentation:

| Type | Files |
|---|---|
| **Use Case Diagrams** | `usecase.drawio`, `Web_usecase.drawio` |
| **Class Diagram** | `class_diagram.drawio` |
| **Data Flow Diagrams** | `dfd_level0.drawio`, `dfd_level1.drawio`, `dfd_level2_part1/2.drawio` |
| **BPMN Process Models** | `bpmn_1_login.drawio` → `bpmn_5_admin_management.drawio` |
| **Sequence Diagrams** | `sd_1_login.html` → `sd_5_admin_management.html` |
| **Document Model** | `DocumentModel_TongQuan/Users/Tracks/Admin.html` |
| **Architecture Diagram** | `architecture_diagram.html` |

> Open `.drawio` files with [draw.io](https://app.diagrams.net/) or the VS Code extension.

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch:
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit** your changes:
   ```bash
   git commit -m "feat: add amazing feature"
   ```
4. **Push** to the branch:
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open** a Pull Request

### Commit Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Description |
|---|---|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation changes |
| `style:` | Code style (formatting, no logic change) |
| `refactor:` | Code refactoring |
| `test:` | Add/update tests |
| `chore:` | Maintenance tasks |

---

## 📄 License

This project is **private** and not open-sourced. All rights reserved.

---

## 👨‍💻 Author

**Quan Pham** — [GitHub](https://github.com/Quan-2004)

---

<div align="center">

**Built with ❤️ using Flutter, Next.js, and Firebase**

</div>
