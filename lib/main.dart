import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hala_bakeries_sales/firebase_options.dart';
import 'package:hala_bakeries_sales/core/theming/app_theme.dart';
import 'package:hala_bakeries_sales/core/di/dependency_injection.dart';
import 'package:hala_bakeries_sales/core/cache/shared_pref.dart';
import 'package:hala_bakeries_sales/core/helper/bloc_observer.dart';
import 'package:hala_bakeries_sales/core/routing/app_router.dart';
import 'package:hala_bakeries_sales/core/helper/connectivity_service.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize SharedPreferences
  await SharedPrefHelper.init();

  // Initialize Date Formatting for Arabic
  await initializeDateFormatting('ar', null);
  
  // Setup Dependency Injection
  await setupDependencyInjection();
  
  // Setup BlocObserver for debugging
  Bloc.observer = AppBlocObserver();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'مبيعات مخابز هلا',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.createRouter(),
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'), // Use English locale for Western digits
      supportedLocales: const [
        Locale('en'), // English
        Locale('ar'), // Arabic
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // Force RTL for Arabic
          child: Stack(
            children: [
              child!,
              const ConnectivityBanner(),
            ],
          ),
        );
      },
    );
  }
}

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<InternetStatus>(
      stream: InternetConnection().onStatusChange,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == InternetStatus.disconnected) {
          return Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.red,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'لا يوجد اتصال بالإنترنت - وضع العمل دون اتصال',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(color: Colors.white),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
