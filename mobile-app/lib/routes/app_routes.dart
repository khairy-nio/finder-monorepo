import 'package:flutter/material.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/welcome_screen.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/signup_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/search_screen.dart';
import '../presentation/screens/profile_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/forgot_password_screen.dart';
import '../presentation/screens/verification_screen.dart';
import '../presentation/screens/notifications_screen.dart';
import '../presentation/screens/chat_screen.dart';
import '../presentation/screens/messages_screen.dart';
import '../presentation/screens/create_post_screen.dart';
import '../presentation/screens/ai_matching_results_screen.dart';
import '../presentation/screens/post_detail_screen.dart';
import '../presentation/screens/filter_screen.dart';
import '../presentation/screens/report_problem_screen.dart';
import '../presentation/screens/edit_profile_screen.dart';
import '../presentation/screens/change_password_screen.dart';
import '../presentation/screens/my_posts_screen.dart';
import '../presentation/screens/email_verification_screen.dart';
import '../presentation/screens/kyc_verification_screen.dart';
import '../presentation/screens/privacy_policy_screen.dart';
import '../presentation/screens/support_screen.dart';
import '../presentation/screens/support_request_detail_screen.dart';
import '../presentation/screens/moderation_status_screen.dart';
import '../presentation/screens/post_protected_preview_screen.dart';
import '../presentation/screens/post_verification_questions_screen.dart';
import '../presentation/screens/rewards_catalog_screen.dart';


/// App Routes Configuration
class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String moderationStatus = '/moderation-status';
  static const String home = '/home';
  static const String search = '/search';
  static const String createPost = '/create-post';
  static const String postDetail = '/post-detail';
  static const String profile = '/profile';
  static const String settingsRoute = '/settings';
  static const String chat = '/chat';
  static const String messages = '/messages';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String verification = '/verification';
  static const String notifications = '/notifications';
  static const String aiMatchingResults = '/ai-matching-results';
  static const String filter = '/filter';
  static const String reportProblem = '/report-problem';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String myPosts = '/my-posts';
  static const String emailVerification = '/email-verification';
  static const String kycVerification = '/kyc-verification';
  static const String privacyPolicy = '/privacy-policy';
  static const String support = '/support';
  static const String supportRequestDetail = '/support-request-detail';
  // Secure feed routes
  static const String postProtectedPreview = '/post-protected-preview';
  static const String postVerificationQuestions = '/post-questions';
  static const String rewardsCatalog = '/rewards-catalog';



  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      case moderationStatus:
        final status = settings.arguments as String? ?? 'suspended';
        return MaterialPageRoute(
          builder: (_) => ModerationStatusScreen(status: status),
        );

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());

      case createPost:
        return MaterialPageRoute(
          builder: (_) => const CreatePostScreen(),
          settings: settings,
        );

      case postDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('No post data provided')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => PostDetailScreen(postData: args),
        );

      case aiMatchingResults:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AIMatchingResultsScreen(postData: args),
        );

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      case changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());

      case myPosts:
        return MaterialPageRoute(builder: (_) => const MyPostsScreen());

      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case messages:
        return MaterialPageRoute(builder: (_) => const MessagesScreen());

      case chat:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: args?['chatId'] as String?,
            userName: args?['userName'] as String?,
            userId: args?['userId'] as String?,
            isOnline: args?['isOnline'] as bool?,
            postTitle: args?['postTitle'] as String?,
            postImage: args?['postImage'] as String?,
            postStatus: args?['postStatus'] as String?,
            postId: args?['postId'] as String?,
            userAvatar: args?['userAvatar'] as String?,
          ),
        );

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case verification:
        return MaterialPageRoute(builder: (_) => const VerificationScreen());

      case emailVerification:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: args?['email'] as String? ?? 'user@example.com',
          ),
        );

      case kycVerification:
        return MaterialPageRoute(builder: (_) => const KycVerificationScreen());

      case privacyPolicy:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PrivacyPolicyScreen(
            isFromOnboarding: args?['isFromOnboarding'] ?? false,
          ),
        );

      case support:
        return MaterialPageRoute(builder: (_) => const SupportScreen());

      case supportRequestDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('No ticket data provided')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => SupportRequestDetailScreen(ticketData: args),
        );

      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case filter:
        return MaterialPageRoute(builder: (_) => const FilterScreen());

      case reportProblem:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ReportProblemScreen(
            reportType: args?['reportType'] ?? (args?['reportedUserId'] != null ? 'user' : 'general_support'),
            targetId: args?['targetId'] ?? args?['reportedUserId'],
            targetName: args?['targetName'] ?? args?['reportedUserName'],
          ),
        );

      case postProtectedPreview:
        final args = settings.arguments as Map<String, dynamic>?;
        final feedPost = args?['post'];
        if (feedPost == null) {
          return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('No post data'))));
        }
        return MaterialPageRoute(builder: (_) => PostProtectedPreviewScreen(post: feedPost));

      case postVerificationQuestions:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PostVerificationQuestionsScreen(
            postId: args?['postId'] as String? ?? '',
            postTitle: args?['postTitle'] as String? ?? 'Post',
          ),
        );

      case '/rewards-catalog':
        return MaterialPageRoute(
          builder: (_) => const RewardsCatalogScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );

    }
  }
}
