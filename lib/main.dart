import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'common/constants/app_strings.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/providers/app_theme_provider.dart';
import 'presentation/providers/app_language_provider.dart';
import 'presentation/theme/app_theme.dart';

import 'data/services/device_info_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
  
  // Deferred Initialization: Pindahkan eksekusi berat non-UI ke background task
  // setelah frame pertama berhasil di-render agar startup instan.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.microtask(() async {
      await DeviceInfoService.initialize();
    });
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(languageProvider);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      home: const SplashPage(),
    );
  }
}
