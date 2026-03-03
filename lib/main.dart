import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'models/registration_data.dart';
import 'providers/contacts_provider.dart';
import 'providers/user_provider.dart';
import 'providers/task_provider.dart';
import 'providers/meeting_provider.dart';
import 'helpers/database_seeder.dart';
import 'services/auth_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registration_step1_screen.dart';

// Global navigator key to access navigation without context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // FIX: CRITICAL - Initialize Flutter bindings BEFORE any async operations
  // This MUST be the very first line to prevent "databaseFactory not initialized" error
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite seeding is not available on web.
  if (!kIsWeb) {
    await DatabaseSeeder.seedDatabase();
  }

  runApp(const ProDialerApp());
}

class ProDialerApp extends StatefulWidget {
  const ProDialerApp({super.key});

  @override
  State<ProDialerApp> createState() => _ProDialerAppState();
}

class _ProDialerAppState extends State<ProDialerApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => MeetingProvider()),
        // Add more providers here as needed
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Pro Dialer',
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (context) => const PhoneInputScreen(),
          '/signup': (context) =>
              PersonalDetailsScreen(registrationData: RegistrationData()),
        },
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1A1A1A),
          primaryColor: const Color(0xFF00BFA5),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00BFA5),
            secondary: Color.fromARGB(255, 25, 233, 174),
            surface: Color(0xFF2A2A2A),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A1A1A),
            elevation: 0,
          ),
        ),
        home: FutureBuilder<String?>(
          future: AuthService.getAuthToken(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF121212),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF10B981)),
                ),
              );
            }
            if (snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data!.isNotEmpty) {
              return const DashboardScreen();
            }
            return PersonalDetailsScreen(registrationData: RegistrationData());
          },
        ),
      ),
    );
  }
}
