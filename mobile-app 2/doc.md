# Lost & Found App — Missing Features & Remaining Work
*Last Updated: 2026-05-06*

This document outlines all features, screens, and API connections that are currently **missing, incomplete, or broken** in the application. It serves as the master checklist to reach full 100% production readiness.

---

## 🔴 Priority 1: Broken UI Workflows (No Backend Blockers)
These features have backend endpoints available but the Flutter app is either not calling them correctly or using mock logic.

### 1. Filtered Search Not Working
- **Location:** `FilterScreen` & `PostProvider`
- **Issue:** The filter screen collects preferences (Lost/Found, Category, Country, City) but when the user taps "Apply", it just closes the screen. The filters are never passed back to the Home Screen feed.
- **Action Required:**
  - Update `PostRemoteDataSource` to accept optional query parameters (`post_type`, `category`, `country`, `city`).
  - Update `PostProvider.loadPosts()` to accept and hold these filters.
  - Wire the Filter screen's Apply button to trigger the filtered API call.

### 2. Preview Post "Publish" Button Disconnected
- **Location:** `PreviewPostScreen`
- **Issue:** The "Publish Post" button at the end of the post-creation preview only shows a fake success dialog. It does not actually submit the post to the backend.
- **Action Required:** Call `AIMatchingRemoteDataSource.createPostWithMatching()` when the button is pressed, and correctly route to the AI Matching Results screen on success.

### 3. Redundant Password Reset Screen
- **Location:** `NewPasswordScreen`
- **Issue:** The app currently has a screen to type a new password after a forgot-password request. However, Firebase Auth handles password resets natively via email links.
- **Action Required:** Either remove `NewPasswordScreen` entirely and rely on Firebase's built-in web page reset, or implement Firebase Dynamic Links to deep-link the user back into the app with an `oobCode` to securely use this screen.

---

## 🟡 Priority 2: Missing Core Features (Requires Backend Updates)
These are major application features that are entirely missing. They cannot be built in Flutter until the Node.js backend team creates the required endpoints.

### 4. Notifications System
- **Location:** `NotificationsScreen`
- **Issue:** The screen currently relies 100% on hardcoded mock data.
- **Blocker:** The backend does not have a Notification service yet.
- **Action Required (Backend):** Create `GET /notification/my-notifications`, `POST /notification/:id/read`, and `POST /notification/read-all`.
- **Action Required (Frontend):** Build a `NotificationRemoteDataSource` and wire the screen to it.

### 5. Support Ticketing System
- **Location:** `SupportScreen`
- **Issue:** The "My Requests" list shows fake hardcoded tickets after a 2-second delay. The "Live Chat" and "Email Support" buttons do nothing.
- **Blocker:** The backend does not have support ticket endpoints.
- **Action Required (Backend):** Create `GET /support/my-tickets`, `POST /support/create-ticket`, and `GET /support/:id`.
- **Action Required (Frontend):** Wire the list to the new endpoints and build a form for submitting a new ticket.

### 6. Contact Request & Permission Flow
- **Location:** Chat Initiation
- **Issue:** Currently, any user can instantly start a chat with anyone else. The intended design requires a "Contact Request" permission system (send request -> accept/reject -> chat created).
- **Blocker:** The frontend screens do not exist for this flow.
- **Action Required (Backend):** Ensure endpoints like `POST /contact-request/send`, `POST /contact-request/:id/respond`, and `GET /contact-request/pending` exist and are stable.
- **Action Required (Frontend):** Build `ContactRequestsScreen` for users to view incoming messages, and update the "Message" button to send a request instead of jumping straight into a chat.

### 7. Real-Time Chat & Push Notifications
- **Location:** `ChatScreen` & Global App
- **Issue:** Messages only load when the screen is opened. You have to manually refresh to see new replies. No push notifications are delivered when the app is closed.
- **Blocker:** Backend needs FCM integration and WebSockets.
- **Action Required (Backend):** Add a `POST /user/fcm-token` endpoint, and integrate Socket.io or Firebase Cloud Messaging for real-time delivery.
- **Action Required (Frontend):** 
  - Add `firebase_messaging` package.
  - Implement a WebSocket listener or a 5-second polling timer in `ChatScreen` as a temporary fix.

---

## ⚪ Priority 3: Polish & Minor Tweaks
These are small quality-of-life updates that make the app feel complete.

### 8. Google Sign-In Integration
- **Location:** `LoginScreen` & `SignupScreen`
- **Issue:** The Google button shows a "Coming Soon" snackbar.
- **Action Required:** Add the `google_sign_in` package, map the Google credential to Firebase Auth, and then sync the resulting user to the PostgreSQL backend (`POST /user/login`). Requires generating and adding SHA-1 fingerprints in the Firebase Console.

### 9. Active Filter Indicator Badge
- **Location:** `HomeScreen`
- **Issue:** There is no visual indication when search filters are actively applied to the feed.
- **Action Required:** Add a small blue dot badge to the AppBar filter icon when `PostProvider` has active filter parameters. (Depends on fixing Issue #1 first).

---

## 📋 Recommended Action Plan for Next Session:
1. **Frontend Only:** Wire the `FilterScreen` logic to the `PostProvider`.
2. **Frontend Only:** Fix the `PreviewPostScreen` publish button to make real API calls.
3. **Frontend Only:** Evaluate the Firebase deep-link requirement for `NewPasswordScreen`.
4. **Backend Required:** Request the backend team to prioritize the `Notifications` and `Support Tickets` endpoints so the mock data can be stripped out.
