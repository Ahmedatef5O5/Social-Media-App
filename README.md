<div align="center">

<h1>📱 Social Media App</h1>

<p><strong>A production-grade, full-featured social media platform built with Flutter & Supabase</strong></p>

<p>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-FCM-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/ZEGOCLOUD-Calls-blue?style=for-the-badge" />
</p>

<p>
  <img src="https://img.shields.io/badge/Architecture-Feature--First-purple?style=flat-square" />
  <img src="https://img.shields.io/badge/State%20Management-BLoC%20%2F%20Cubit-blueviolet?style=flat-square" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat-square" />
</p>

</div>

---

## 📖 Overview

**Social Media App** is a comprehensive, cross-platform social networking application that delivers a seamless, real-time user experience. Built on a clean **Feature-First Architecture**, it brings together messaging, audio/video calling, stories, a social feed, and smart notifications — all under a beautifully themed, highly customizable UI.

Whether you're a developer exploring production-grade Flutter architecture or a technical reviewer evaluating mobile engineering quality, this project demonstrates a thoughtful, scalable approach to building complex consumer applications.

> **Platform:** Android (primary) · **Framework:** Flutter / Dart · **Backend:** Supabase + Firebase

---

## 📸 Screenshots

> _Add screenshots by placing images under `assets/screenshots/` and updating the paths below._

| Authentication | Home Feed | Chat |
|:-:|:-:|:-:|
| ![Auth](assets/screenshots/auth.png) | ![Feed](assets/screenshots/feed.png) | ![Chat](assets/screenshots/chat.png) |

| Stories | Video Call | Themes |
|:-:|:-:|:-:|
| ![Stories](assets/screenshots/stories.png) | ![Calls](assets/screenshots/calls.png) | ![Themes](assets/screenshots/themes.png) |

<details>
<summary>📽️ <strong>How to add demo videos / GIFs</strong></summary>

1. Record a screen demo (tools: [scrcpy](https://github.com/Genymobile/scrcpy), Android Studio screen recorder, or iOS simulator).
2. Convert to GIF using [ezgif.com](https://ezgif.com) or `ffmpeg`:
   ```bash
   ffmpeg -i demo.mp4 -vf "fps=10,scale=320:-1" demo.gif
   ```
3. Place the `.gif` under `assets/demos/` and embed it:
   ```markdown
   ![Feature Demo](assets/demos/chat_demo.gif)
   ```

</details>

---

## ✨ Feature Highlights

### 🔐 Authentication & Security

| Feature | Details |
|---|---|
| Email / Password Sign-up | Includes real-time password strength evaluation |
| Social Login | One-tap Google & Facebook OAuth integration |
| Session Management | Automatic routing based on auth state, secure token handling |
| Onboarding Flow | Dedicated splash and onboarding screens for first-time users |

---

### 💬 Real-time Chat & Group Messaging

- **1-on-1 Private Chats** — instant delivery powered by Supabase Realtime
- **Group Chats** — create, manage, and participate in multi-user conversations
- **Rich Media Messaging** — send text, images, videos, and voice notes
- **Emoji Reactions** — react to any message with expressive emojis
- **Typing Indicators** — live "someone is typing…" presence feedback
- **Message Status** — delivered & read receipts

---

### 📞 Audio & Video Calls

- **High-Quality Calls** powered by **ZEGOCLOUD** SDK
- **Full-Screen Incoming Call UI** — works even when the app is closed or backgrounded (via FCM full-screen intents)
- **Ringtone Notifications** — audible incoming call alerts with Accept / Decline actions
- **Modern Calling Screen** — displays caller avatar, live call duration, and visual effects

---

### 📖 Stories & Status

- Post **text stories** with a variety of colorful gradient backgrounds
- Full support for **image and video stories**
- **Progress bar** with tap-to-pause and release-to-resume UX
- Auto-expiring stories following standard social media conventions

---

### 📝 Posts & Home Feed

- Publish **text, image, or video posts** to a scrollable home feed
- Engage through **Likes, Comments, Shares, and Saves**
- **Full-Screen Image Viewer** for an immersive media experience
- Post creation flow with media picker integration

---

### 🔔 Smart Push Notifications

- Powered by **Firebase Cloud Messaging (FCM)** + `flutter_local_notifications`
- Instant alerts for:
  - New private messages
  - New group messages
  - Incoming audio / video calls
- **Actionable notifications** — reply or decline directly from the notification shade without opening the app

---

### 🟢 Presence System

- Real-time **Online / Last Seen** status for all users
- Automatic status updates based on app foreground/background state
- Seamlessly integrated into chat list and chat headers

---

### 🎨 UI/UX & Theming

- **6+ Dynamic Themes**: Ocean, Sunset, Midnight, Emerald, Carbon, and more
- Seamless **Light / Dark mode** switching
- Smooth, engaging animations powered by the **Lottie** library
- Consistent design language across all features

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter / Dart |
| **State Management** | BLoC / Cubit Pattern |
| **Backend & Database** | Supabase (Auth, PostgreSQL, Storage, Realtime) |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **Local Notifications** | `flutter_local_notifications` |
| **Audio/Video Calls** | ZEGOCLOUD SDK |
| **Routing** | Custom App Router with active screen tracking |
| **Animations** | Lottie |

---

## 🏗️ Architecture Overview

The project follows a **Feature-First Clean Architecture**, where each feature is a self-contained module with its own data, domain, and presentation layers. This ensures high cohesion, low coupling, and straightforward testability.

```
Presentation Layer   →   BLoC / Cubit  →  UI Screens & Widgets
      ↕
Domain Layer         →   Use Cases / Repositories (Interfaces)
      ↕
Data Layer           →   Supabase / Firebase / ZEGOCLOUD Services
```

State flows unidirectionally through Cubits — UI emits events, Cubits process them and emit new states, and widgets reactively rebuild only when necessary.

---

## 📂 Project Structure

```
lib/
├── core/
│   ├── router/             # AppRouter + route definitions
│   ├── services/           # NotificationService, ActiveScreenTracker
│   ├── themes/             # ThemeCubit + dynamic theme definitions
│   ├── constants/          # App-wide constants
│   └── helpers/            # Utility functions & extensions
│
├── features/
│   ├── auth/               # Sign up, login, password strength, OAuth
│   ├── calls/              # Audio & video call UI, signaling, ZEGOCLOUD
│   ├── chats/              # 1-on-1 messaging, media, reactions, presence
│   ├── group_chat/         # Group creation, management, messaging
│   ├── discover/           # User search and discovery
│   ├── home/               # Feed, post creation, likes/comments/shares
│   ├── profile/            # User profile, follow system, media gallery
│   ├── settings/           # Theme, notifications, account settings
│   ├── splash/             # Splash screen & onboarding flow
│   └── stories/            # Story creation, viewer, progress bar
│
└── main.dart               # App entry point, Firebase & Supabase init
```

Each feature follows an internal structure of:
```
feature/
├── cubit/        # State management (Cubit + State classes)
├── model/        # Data models
├── services/     # Feature-specific service layer
├── screens/      # Full-page UI screens
└── widgets/      # Reusable UI components
```

---

## ⚙️ Requirements

| Requirement | Version |
|---|---|
| Flutter SDK | `>=3.0.0` |
| Dart SDK | `>=3.0.0` |
| Android SDK | API 21+ (Android 5.0) |
| Xcode (iOS) | 14+ |
| Supabase Project | Active project with Auth, DB, Storage, Realtime enabled |
| Firebase Project | Android app registered, `google-services.json` configured |
| ZEGOCLOUD Account | App ID and App Sign from ZEGOCLOUD Console |

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/social-media-app.git
cd social-media-app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Environment Variables

Create a `.env` file in the project root (or update `lib/core/secrets/app_secrets.dart`):

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
ZEGOCLOUD_APP_ID=your_zegocloud_app_id
ZEGOCLOUD_APP_SIGN=your_zegocloud_app_sign
```

### 4. Firebase Setup

- Download `google-services.json` from your Firebase Console.
- Place it at: `android/app/google-services.json`
- For iOS: download `GoogleService-Info.plist` and place it at `ios/Runner/GoogleService-Info.plist`

### 5. Supabase Database Setup

> Run the SQL migrations found in `supabase/migrations/` (if provided) or manually create the required tables: `profiles`, `posts`, `messages`, `group_chats`, `stories`, `calls`, `reactions`.

Enable **Realtime** on your Supabase tables for live messaging features.

### 6. Run the App

```bash
# Debug mode
flutter run

# Release build (Android)
flutter build apk --release

# Release build (iOS)
flutter build ios --release
```

---

## 🔑 Key User Scenarios

| Scenario | How It Works |
|---|---|
| **New user registers** | Enters email/password → password strength evaluated → profile created in Supabase |
| **Sends a voice note** | Records audio in-app → uploads to Supabase Storage → received in real time |
| **Receives a call while offline** | FCM full-screen intent fires → ringtone plays → incoming call UI shown over lock screen |
| **Posts a story** | Picks image/video or selects text background → uploads → visible to followers for 24h |
| **Switches theme** | Opens Settings → selects Ocean/Midnight/etc. → entire app repaints via ThemeCubit |
| **Reacts to a message** | Long-press message → emoji picker → reaction stored & displayed to all participants |

---

## 🗺️ Roadmap

- [ ] **iOS Push Notification Support** — full APNs integration for calling features
- [ ] **End-to-End Encryption (E2EE)** — for private messages
- [ ] **Post Reels / Short Videos** — vertical video feed feature
- [ ] **Explore / Trending Feed** — algorithm-based content discovery
- [ ] **Message Search** — full-text search across chat history
- [ ] **Read Receipts at Scale** — batch-optimized delivery status updates
- [ ] **Web Support** — Flutter Web build with responsive layouts
- [ ] **Localization (i18n)** — multi-language support via `flutter_localizations`
- [ ] **Unit & Widget Tests** — expanding coverage across Cubits and widgets

---

## 📄 License

This project is intended for educational and portfolio purposes.  
See [LICENSE](LICENSE) for details.

---

<div align="center">

Built with ❤️ using **Flutter** · **Supabase** · **Firebase** · **ZEGOCLOUD**

</div>
