import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/network/api_client.dart';
import 'core/services/auth_service.dart';
import 'core/utils/app_messenger.dart';
import 'data/datasources/post_remote_data_source.dart';
import 'data/datasources/user_remote_data_source.dart';
import 'data/repositories/post_repository_impl.dart';
import 'domain/usecases/get_all_posts.dart';
import 'domain/usecases/search_by_image.dart';
import 'presentation/providers/post_provider.dart';
import 'presentation/providers/search_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize dependencies
    final apiClient = ApiClient(
      client: http.Client(),
      tokenProvider: AuthService.instance.getIdToken,
    );
    final postRemoteDataSource = PostRemoteDataSourceImpl(apiClient: apiClient);
    final postRepository = PostRepositoryImpl(
      remoteDataSource: postRemoteDataSource,
    );

    return MultiProvider(
      providers: [
        // User Provider — loads /user/me after login
        ChangeNotifierProvider(
          create: (_) => UserProvider(
            remoteDataSource: UserRemoteDataSourceImpl(apiClient: apiClient),
          ),
        ),
        // Post Provider
        ChangeNotifierProvider(
          create: (_) => PostProvider(
            getAllPostsUseCase: GetAllPostsUseCase(postRepository),
          ),
        ),
        // Search Provider
        ChangeNotifierProvider(
          create: (_) => SearchProvider(
            searchByImageUseCase: SearchByImageUseCase(postRepository),
          ),
        ),
        // Notification Provider
        ChangeNotifierProvider(
          create: (_) => NotificationProvider()..init(),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: AppMessenger.navigatorKey,
        scaffoldMessengerKey: AppMessenger.messengerKey,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
