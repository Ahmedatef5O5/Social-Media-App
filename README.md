<div align="center">

<!-- ╔══════════════════════════════════════════════╗ -->
<!--            SOCIAL MATE — HERO BANNER           -->
<!-- ╚══════════════════════════════════════════════╝ -->
<img src="https://github.com/user-attachments/assets/00deb226-b6fb-4572-b52b-500f54915896" alt="Social Mate Banner" width="100%" style="border-radius:16px;" />

<br/><br/>

<h1 style="
  display:flex;
  align-items:center;
  justify-content:center;
  gap:12px;
  line-height:1;
">
  <img 
    src="https://github.com/user-attachments/assets/a41d174a-a845-40f0-81af-2587eaf0848d" 
    alt="Social Mate Icon" 
    width="25" 
    height="25"
    style="border-radius:10px; display:block;"
  />
  <span style="display:block;">Social Mate</span>
</h1>

<p><strong>A production-grade, AI-powered social platform built with Flutter & Supabase</strong></p>
<p>Feed · Reels · Stories · Real-time Chat · Group & Video Calls · AI Assistant — all in one app</p>

<p>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-FCM-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/LiveKit-Realtime%20Calls-1F2937?style=for-the-badge" />
  <img src="https://img.shields.io/badge/AI-Gemini%20%7C%20Groq%20%7C%20OpenRouter-8B5CF6?style=for-the-badge" />
</p>

<p>
  <img src="https://img.shields.io/badge/Architecture-Feature--First%20Clean%20Arch-purple?style=flat-square" />
  <img src="https://img.shields.io/badge/State%20Management-BLoC%20%2F%20Cubit-blueviolet?style=flat-square" />
  <img src="https://img.shields.io/badge/Offline-Hive%20Cache-orange?style=flat-square" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat-square" />
</p>

</div>

---

## 📖 Overview

**Social Mate** is a comprehensive, cross-platform social networking application delivering a seamless, real-time, and increasingly **AI-augmented** user experience. Built on a clean **Feature-First Architecture** spanning **23 self-contained features**, it brings together a social feed, short-form video (Reels), Stories, 1-on-1 & group messaging, audio/video calling, custom sticker packs, and a full **on-device AI Assistant** — all under a beautifully themed, dynamically switchable UI.

Whether you're a developer exploring production-grade Flutter architecture or a technical reviewer evaluating mobile engineering quality, this project demonstrates a thoughtful, scalable, and genuinely feature-complete approach to building a modern consumer social app.

> **Platform:** Android (primary) · **Framework:** Flutter / Dart · **Backend:** Supabase + Firebase · **Realtime Calls:** LiveKit · **AI:** Gemini / Groq / OpenRouter

---

## 📸 Screenshots

| Authentication | Home Feed | Chat |
|:-:|:-:|:-:|
| <img src="https://github.com/user-attachments/assets/62f6f67d-d592-49fd-9bee-7140047bc6b3" width="220" height="440" alt="Authentication View" style="border-radius:12px;object-fit:cover;" /> | <img src="https://github.com/user-attachments/assets/4a0304d5-f5e1-49ee-a662-f8ebae34650f" width="220" height="440" alt="Home Feed" style="border-radius:12px;object-fit:cover;" /> | <img src="https://github.com/user-attachments/assets/d0076775-8eff-4832-8061-6092e86c738d" width="220" height="440" alt="Chat View" style="border-radius:12px;object-fit:cover;" /> |

| Stories | Video Call | Themes |
|:-:|:-:|:-:|
| <img src="https://github.com/user-attachments/assets/ed7ada97-a913-4d33-bce4-cf41f3e45d7f" width="220" height="440" alt="Stories View" style="border-radius:12px;object-fit:cover;" /> | <img src="https://github.com/user-attachments/assets/56d089cd-acac-4858-ad2e-dad3e886e9fc" width="220" height="440" alt="Video Call" style="border-radius:12px;object-fit:cover;" /> | <img src="https://github.com/user-attachments/assets/c972665e-158e-4831-949b-7fd0593d1b06" width="220" height="440" alt="Themes View" style="border-radius:12px;object-fit:cover;" /> |

> 📌 *Screenshot placeholders reused from the previous README — recommend refreshing with current-build captures for Reels, AI Chat, and Sticker Studio once the visual revamp (Step 2) is complete.*

---

## ✨ Feature Highlights

<details open>
<summary><strong>🤖 AI Assistant & AI Chat</strong> — the platform's newest pillar</summary>

- **Contextual AI Assistant** embedded across the app: autocomplete captions, spell-check, smart reply suggestions, comment suggestions, and chat summarization (short / detailed / by-topic)
- **Standalone AI Chat** — a full conversational assistant with persistent sessions, image attachments, and a typewriter-style streaming reply experience
- **Multi-provider AI Gateway** — switch between **Gemini**, **Groq**, and **OpenRouter** on the fly, with automatic vision-support detection per provider
- **Personalization** — configurable reply tone, reply length, and autocomplete language (Arabic / English / Auto) from a dedicated AI Settings screen
- **Usage Quota Tracking** — transparent, real-time visibility into AI usage limits

</details>

<details open>
<summary><strong>🔐 Authentication & Security</strong></summary>

| Feature | Details |
|---|---|
| Email / Password Sign-up | Real-time password strength evaluation |
| Social Login | One-tap Google & Facebook OAuth integration |
| Session Management | Automatic routing based on auth state, secure token handling |
| **App Lock** | Biometric / device-credential lock gate for the entire app |
| Onboarding Flow | Dedicated splash and onboarding screens for first-time users |

</details>

<details open>
<summary><strong>💬 Real-time Chat & Group Messaging</strong></summary>

- **1-on-1 & Group Chats** — instant delivery powered by Supabase Realtime
- **Unified Attachment System** — one picker sheet for images, videos, files, voice notes, GIFs, and stickers across every chat surface
- **Professional Voice Messages** — chunked recording, audio compression, live waveform visualization, and slide-to-lock recording UX
- **@Mentions** — rich, searchable mention suggestions with styled inline rendering
- **Smart Link Previews** — automatic rich preview cards for links shared in chat
- **Message Forwarding** — forward any message (text, media, voice) across chats and groups
- **Message Reactions** — emoji reactions with a live picker bubble and reaction summaries
- **Starred / Pinned Messages** and a dedicated **Shared Media** browser (images, videos, files, links, voice) per conversation
- **Archived Chats** with a fully separate management view
- **In-chat Search** across conversation history
- **Typing Indicators** & **Delivered/Read Receipts**
- **Presence System** — real-time online/last-seen with granular, user-configurable privacy controls

</details>

<details open>
<summary><strong>👥 Group Chats & Group Calls</strong></summary>

- Full group lifecycle: creation, member management, roles, edit/settings, and system-event timeline (joins, leaves, renames)
- Group-wide mentions, reactions, and shared-media browsing
- **Group Audio/Video Calls** powered by LiveKit, with an incoming/outgoing group call UI and live member-presence tracking

</details>

<details open>
<summary><strong>📞 Audio & Video Calls</strong></summary>

- Powered by **LiveKit** (modern WebRTC SFU) for both 1-on-1 and group calls
- **Full-Screen Incoming Call UI** — works even when the app is closed or backgrounded (via FCM full-screen intents)
- **Picture-in-Picture (PiP)** call overlay so users can keep browsing the app mid-call
- **Foreground Service** keeps calls alive and stable in the background
- Modern calling screen with caller avatar, live duration, glass-morphism controls, and ambient visual effects

</details>

<details open>
<summary><strong>📖 Stories & Status</strong></summary>

- **Text Stories** with colorful gradient backgrounds and a custom text editor
- Full **image and video story** support with tap-to-pause / release-to-resume progress bars
- **Story Reactions** with an animated "reaction fountain" visual effect
- **Story Replies** routed directly into chat
- Story views tracking with a dedicated viewers bottom sheet
- Auto-expiring stories following standard social conventions

</details>

<details open>
<summary><strong>📝 Posts & Home Feed</strong></summary>

- Publish **text, image, or video posts**, or attach files, to a scrollable, realtime home feed
- **Post Themes** — stylized backgrounds for short text posts
- Engage through **Likes/Reactions, Comments, Shares, and Saves**
- **Full-Screen Immersive Viewers** for images and videos
- **Saved Posts** collection view

</details>

<details open>
<summary><strong>🎬 Reels (Short-Form Video)</strong></summary>

- Dedicated vertical, swipeable **Reels feed** with category browsing and channel avatars
- Reels interleaved directly into the **Home Feed** as a horizontal discovery rail
- Full-screen immersive player with actions column, info overlay, and pooled video-controller management for smooth playback
- Reels onboarding flow and a dedicated Reels grid inside global Search

</details>

<details open>
<summary><strong>💭 Comments</strong></summary>

- **Threaded replies** with visual thread connectors
- **Voice comments** with an in-line recorder and player
- Rich attachments, emoji reactions, and **AI-generated comment suggestions**
- Inline and full-sheet comment presentations depending on context

</details>

<details open>
<summary><strong>🖼️ Custom Sticker Studio</strong></summary>

- Users can **create their own sticker packs**, with configurable **public/private** visibility
- Upload quota handling, progress-tracked uploads, and a friend-picker for sharing private packs
- Full sticker pack browser, detail view, and downloads management

</details>

<details open>
<summary><strong>🎞️ GIFs</strong></summary>

- Giphy-powered GIF search and picker, fully integrated into the shared attachment system for chats

</details>

<details open>
<summary><strong>👥 Social Graph & Discovery</strong></summary>

- Friend requests, following, and connection management
- **Audience Picker** — per-post privacy control (public / friends / private / custom)
- **Discover People** — smart suggestions to grow your network
- **Global Search** — unified search across Accounts, Groups, Posts, and Reels, plus a personalized **"For You"** tab

</details>

<details open>
<summary><strong>🔔 Smart Push & In-App Notifications</strong></summary>

- Powered by **Firebase Cloud Messaging (FCM)** + `flutter_local_notifications`
- Instant alerts for new messages (private & group), reactions, comments, and incoming calls
- **Actionable notifications** — reply or decline directly from the notification shade
- Custom notification avatar rendering pipeline
- Dedicated **in-app Notification Center** with filterable categories, separate from push alerts

</details>

<details open>
<summary><strong>📡 Offline-First & Performance</strong></summary>

- **Hive-powered local cache** for media and conversation snapshots, with intelligent **eviction policies** to manage device storage
- **Connectivity Awareness** — a live offline/online banner keeps users informed of network state
- **Cloudinary CDN** integration for optimized media delivery alongside Supabase Storage
- Skeleton/shimmer loading states across nearly every screen for a polished perceived-performance feel

</details>

<details open>
<summary><strong>🎨 UI/UX & Theming</strong></summary>

- **6+ Dynamic Themes** (Ocean, Sunset, Midnight, Emerald, Carbon, and more), each with its own splash screen and app logo variant
- Seamless **Light / Dark mode** switching
- Full **RTL / Bidi text support** for mixed Arabic-English content
- Smooth, engaging animations powered by **Lottie**
- Consistent, cohesive design language across all 23 features

</details>

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter / Dart |
| **State Management** | BLoC / Cubit Pattern |
| **Backend & Database** | Supabase (Auth, PostgreSQL, Storage, Realtime) |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **Local Notifications** | `flutter_local_notifications` |
| **Audio/Video & Group Calls** | LiveKit (WebRTC SFU) |
| **AI Providers** | Gemini · Groq · OpenRouter (multi-provider gateway) |
| **Media CDN** | Cloudinary |
| **Local Persistence / Offline Cache** | Hive |
| **GIF Search** | Giphy API |
| **Biometric Security** | `local_auth` |
| **Background Call Stability** | `flutter_foreground_task` |
| **Routing** | Custom App Router with active-screen tracking |
| **Animations** | Lottie |

---

## 🏗️ Architecture Overview

The project follows a **Feature-First Clean Architecture**, where each feature is a self-contained module. Higher-complexity features (like the AI Assistant) follow explicit clean-architecture layering with entities, repositories, and data sources; the majority of features use a pragmatic Cubit + Service + Model structure for fast iteration without sacrificing separation of concerns.

```
Presentation Layer   →   BLoC / Cubit  →  UI Screens & Widgets
      ↕
Domain Layer         →   Use Cases / Repositories (Interfaces)
      ↕
Data Layer           →   Supabase / Firebase / LiveKit / AI Gateway / Cloudinary
```

State flows unidirectionally through Cubits — UI triggers actions, Cubits process them and emit new states, and widgets reactively rebuild only when necessary.

---

## 📂 Project Structure

```
lib/
├── core/
│   ├── router/             # AppRouter + route definitions
│   ├── services/           # Notifications, FCM, Cloudinary, LiveKit tokens, calls
│   ├── themes/              # ThemeCubit + dynamic theme/splash/logo definitions
│   ├── cache/               # Hive-backed media cache, eviction, snapshots
│   ├── chat_shared/         # Shared chat primitives: conversations, archives, starred, media
│   ├── attachment/          # Unified attachment picker & rendering pipeline
│   ├── audio/                # Voice recorder engine & waveform UI
│   ├── presence/             # Online/last-seen presence system
│   ├── mentions/             # @mention parsing, search & rich text
│   ├── link/                  # Link preview fetching & rendering
│   ├── connectivity/          # Network state monitoring & banner
│   ├── bootstrap/             # App startup orchestration (Firebase/Supabase/Hive)
│   ├── constants/, helpers/, errors/, utilities/, widgets/, toast/, secrets/, supabase/, firebase/, views/
│
├── features/
│   ├── auth/                # Sign up, login, password strength, OAuth, app lock
│   ├── splash/               # Splash screen & onboarding flow
│   ├── home/                  # Feed orchestration
│   ├── posts/                  # Post creation, feed, reactions, comments bridge
│   ├── reels/                   # Short-form vertical video feed
│   ├── stories/                  # Story creation, viewer, reactions, replies
│   ├── comments/                  # Threaded comments, voice comments, AI suggestions
│   ├── reactions/                  # Cross-surface reaction pickers & summaries
│   ├── single_chats/                # 1-on-1 messaging
│   ├── group_chats/                  # Group creation, management, messaging
│   ├── chat_forwarding/                # Cross-chat message forwarding
│   ├── single_calls/                    # 1-on-1 audio/video calls (LiveKit)
│   ├── group_calls/                      # Group audio/video calls (LiveKit)
│   ├── stickers/                          # Custom sticker pack creation & browsing
│   ├── gifs/                               # Giphy GIF search & picker
│   ├── ai_assistant/                        # In-context AI actions (autocomplete, summaries, etc.)
│   ├── ai_chat/                              # Standalone multi-provider AI chat
│   ├── social_graph/                          # Friends, follow, audience/privacy
│   ├── discover/                               # People discovery
│   ├── search/                                  # Global unified search + For You
│   ├── notifications/                            # In-app notification center
│   ├── profile/                                   # User profile, media gallery, social links
│   ├── settings/                                   # Theme, AI, notifications, account, app lock
│   └── about_us/                                    # App/team info screen
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
| Flutter SDK | `^3.7.2` (Dart 3.x) |
| Android SDK | API 21+ (Android 5.0) |
| Xcode (iOS) | 14+ |
| Supabase Project | Active project with Auth, DB, Storage, Realtime enabled |
| Firebase Project | Android app registered, `google-services.json` configured |
| LiveKit Server/Cloud | Project URL + API key/secret for token generation |
| AI Provider Keys | At least one of Gemini / Groq / OpenRouter API keys |
| Cloudinary Account | Cloud name + upload preset for media CDN |
| Giphy API Key | For GIF search |

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/social-mate.git
cd social-mate
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Environment & Secrets

Update `lib/core/secrets/app_secrets.dart` (or your preferred secrets strategy) with:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key

LIVEKIT_URL=wss://your-livekit-project.livekit.cloud
LIVEKIT_API_KEY=your_livekit_api_key
LIVEKIT_API_SECRET=your_livekit_api_secret

CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_upload_preset

GEMINI_API_KEY=your_gemini_key
GROQ_API_KEY=your_groq_key
OPENROUTER_API_KEY=your_openrouter_key

GIPHY_API_KEY=your_giphy_key
```

### 4. Firebase Setup

- Download `google-services.json` from your Firebase Console.
- Place it at: `android/app/google-services.json`
- For iOS: download `GoogleService-Info.plist` and place it at `ios/Runner/GoogleService-Info.plist`

### 5. Supabase Database Setup

> Run your SQL migrations (if provided) or manually create the required tables: `profiles`, `posts`, `reels`, `messages`, `group_chats`, `stories`, `comments`, `reactions`, `sticker_packs`, `notifications`, `friendships`.

Enable **Realtime** on your Supabase tables for live messaging, presence, and feed updates.

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
| **Sends a voice note** | Records audio in-app with live waveform → compressed → uploaded → received in real time |
| **Gets an AI reply suggestion** | Opens a chat → taps the AI assistant icon → picks tone/length → suggestion inserted into the composer |
| **Chats with the AI** | Opens AI Chat → picks a model (Gemini/Llama/OpenRouter) → sends text or an image → gets a streamed reply |
| **Receives a call while offline** | FCM full-screen intent fires → ringtone plays → incoming call UI shown over lock screen |
| **Watches Reels** | Swipes vertically through the Reels feed or taps a Reel from the Home Feed's horizontal rail |
| **Posts a story** | Picks image/video or a text background → uploads → visible to followers for 24h |
| **Creates a sticker pack** | Uploads stickers → sets pack name & privacy → shares with friends or publishes publicly |
| **Switches theme** | Opens Settings → selects Ocean/Midnight/etc. → entire app repaints, including splash & logo |
| **Locks the app** | Enables App Lock in Settings → app requires biometric/device auth on next open |
| **Reacts to a message** | Long-press message → emoji picker → reaction stored & displayed to all participants |

---

## 🗺️ Roadmap

- [ ] **iOS Push Notification Support** — full APNs integration for calling features
- [ ] **End-to-End Encryption (E2EE)** — for private messages
- [ ] **AI-Generated Story Captions** — extend the AI Assistant into Stories
- [ ] **Read Receipts at Scale** — batch-optimized delivery status updates
- [ ] **Web Support** — Flutter Web build with responsive layouts
- [ ] **Full Localization (i18n)** — multi-language support via `flutter_localizations`
- [ ] **Unit & Widget Tests** — expanding coverage across Cubits and widgets

<sub>✅ Previously planned Reels support and in-chat Message Search have since shipped and are documented above.</sub>

---

## 📄 License

This project is intended for educational and portfolio purposes.  
See [LICENSE](LICENSE) for details.

---

<div align="center">

Built with ❤️ using **Flutter** · **Supabase** · **Firebase** · **LiveKit** · **Gemini / Groq / OpenRouter**

</div>
