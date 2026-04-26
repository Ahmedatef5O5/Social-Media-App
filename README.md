# 📱 Social Media App

A comprehensive, modern social media application built with **Flutter**, delivering a seamless and fast user experience across platforms. The app utilizes **Supabase** as a robust backend for database management, authentication, and real-time updates, alongside cutting-edge push notification and calling capabilities.

---

## ✨ Key Features

### 🔐 Authentication & Security
* Sign up and log in using Email & Password with password strength evaluation.
* Quick social login integration (Google and Facebook).
* Secure session management and automatic user routing based on authentication state.

### 💬 Real-time Chat & Groups
* 1-on-1 private messaging with instant, real-time updates.
* Create and manage group chats effortlessly.
* Support for sending text, images, videos, and voice notes.
* Interact with messages using emoji reactions.
* Real-time typing indicators to see when the other person is typing.

### 📞 Audio & Video Calls
* High-quality voice and video calls (powered by ZEGOCLOUD).
* Incoming call ringtone notifications that work even when the app is closed or in the background (supported by FCM full-screen intents).
* Modern calling UI displaying caller details, call duration, and attractive visual effects.

### 📖 Stories & Status
* Share your daily moments by adding text stories with multiple colorful backgrounds.
* Support for image and video stories.
* Professional story progress bar with tap-to-pause and release-to-resume functionality.

### 📝 Posts & Feeds
* Publish text, image, or video posts on the main home feed.
* Engage with posts through Likes, Comments, Shares, and Saves.
* Modern feed interface featuring a Full-Screen Image Viewer.

### 🔔 Smart Push Notifications
* Fully integrated push notifications powered by **Firebase Cloud Messaging (FCM)** and `flutter_local_notifications`.
* Instant alerts for new private messages, group messages, or incoming calls, with direct reply or decline actions from the notification shade.

### 🟢 Presence System
* Real-time user status tracking (Online / Last Seen).
* Status updates automatically based on app usage and background activity.

### 🎨 UI/UX & Themes
* Modern, eye-catching design supporting **Multiple Dynamic Themes** (Ocean, Sunset, Midnight, Emerald, Carbon, etc.).
* Seamless transition between Light and Dark modes.
* Engaging and smooth animations using the **Lottie** library to elevate user interaction.

---

## 🛠️ Tech Stack & Architecture

* **Framework:** Flutter / Dart
* **State Management:** BLoC / Cubit Pattern
* **Backend & Database:** Supabase (Auth, Postgres DB, Storage, Realtime)
* **Push Notifications:** Firebase Cloud Messaging (FCM)
* **Calls Integration:** ZEGOCLOUD
* **Routing:** Custom App Router with screen activity tracking.

---

## 📂 Project Structure
The app is built on a clean, **Feature-First Architecture** to ensure maintainability and scalability:
```text
lib/
 ├── core/              # Shared elements (Routes, Themes, Constants, Helpers, Notification Services)
 ├── features/          # Independent application features
 │   ├── auth/          # Authentication & Login
 │   ├── calls/         # Audio & Video Calls
 │   ├── chats/         # 1-on-1 Chats
 │   ├── discover/      # Discover new people
 │   ├── group_chat/    # Group Chats
 │   ├── home/          # Main feed and Post creation
 │   ├── profile/       # User Profile management
 │   ├── settings/      # App Settings
 │   ├── splash/        # Splash and Onboarding screens
 │   └── stories/       # User Status / Stories
 └── main.dart          # Application entry point
 
<<<<<<< HEAD
=======

 <!-- pair extraordinaire achievement -->
>>>>>>> 2cb77de172f6ae74c5597ffcdd4db6cd035b3990
