/// API Configuration Constants
class ApiConstants {
  // Base URL - 10.0.2.2 is used for Android Emulator
  static const String baseUrl = 'http://192.168.1.19:3500/api/v1';

  // Auth/User Endpoints
  static const String loginEndpoint = '/user/login';
  static const String userProfileEndpoint = '/user/me';
  static const String submitVerificationEndpoint = '/user/verification/submit';
  static const String verificationStatusEndpoint = '/user/verification/status';

  // Recovery Points Endpoints
  static const String pointsHistoryEndpoint = '/user/me/points/history';
  static const String redemptionsEndpoint = '/user/me/redemptions';
  static const String redeemEndpoint = '/user/me/redeem';


  // Post Endpoints
  static const String createPostEndpoint = '/post/create';
  static const String allPostsEndpoint = '/post';
  static const String myPostsEndpoint = '/post/my-posts';
  static const String postDetailEndpoint = '/post'; // Used as /post/:id
  static const String publicFeedEndpoint = '/post/feed'; // Safe public feed (no images)
  // Post verification questions: /post/:id/questions


  // Matching Endpoints
  static const String searchEndpoint = '/match/find-matches';

  // Contact Request Endpoints
  static const String sendContactRequestEndpoint = '/contact-request/send';
  static const String respondContactRequestEndpoint = '/contact-request'; // /:id/respond
  static const String receivedContactRequestsEndpoint = '/contact-request/received';
  static const String sentContactRequestsEndpoint = '/contact-request/sent';
  static const String checkContactRequestEndpoint = '/contact-request/check'; // /:postId
  static const String pendingContactRequestsEndpoint = '/contact-request/post'; // /:postId/pending

  // Chat Endpoints
  static const String createChatEndpoint = '/chat/create';
  static const String myChatsEndpoint = '/chat/my-chats';
  static const String chatEndpoint = '/chat'; // Used as /chat/:id and /chat/:id/messages

  // Reports
  static const String createReportEndpoint = '/report/create';
  static const String reportsEndpoint = '/report';

  // Notifications
  static const String notificationsEndpoint = '/notification';
  static const String notificationReadAllEndpoint = '/notification/read-all';
  static const String notificationUnreadCountEndpoint = '/notification/unread-count';

  // Health
  static const String healthEndpoint = '/health';

  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
