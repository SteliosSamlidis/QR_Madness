import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart' show AuthProvider, kBypassAuth;
import 'screens/auth/login_screen.dart';
import 'screens/stores/store_selection_screen.dart';


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QRMadness',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      builder: (context, child) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: child!,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Show a neutral splash until Firebase resolves the persisted session.
          if (!auth.initialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (kBypassAuth) return const StoreSelectionScreen();
          return auth.isAuthenticated
              ? const StoreSelectionScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
