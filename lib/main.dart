import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/index.dart';
import 'providers/index.dart';
import 'theme/app_colors.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const RukitoApp());
}

class RukitoApp extends StatelessWidget {
  const RukitoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Cambiar a ApiService() para usar backend real
    // o MockApiService() para desarrollo sin backend
    final IApiService apiService = MockApiService();

    return MultiProvider(
      providers: [
        Provider<IApiService>.value(value: apiService),
        ChangeNotifierProvider(
          create: (_) => ChamberProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => AlertProvider(apiService: apiService),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Rukito - Monitoreo de Cadena de Frío',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          primaryColor: AppColors.info,
          scaffoldBackgroundColor: AppColors.veryLightGray,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.darkGray,
            elevation: 0,
            centerTitle: true,
          ),
          cardTheme: CardTheme(
            color: AppColors.white,
            elevation: 0.5,
            shadowColor: AppColors.shadowColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
