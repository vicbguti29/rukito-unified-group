import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../providers/index.dart';
import 'views/dashboard_view.dart';
import 'views/alerts_view.dart';
import 'views/historical_view.dart';
import 'views/reports_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _views = [
    {
      'title': 'Dashboard',
      'icon': Icons.dashboard_rounded,
      'widget': const DashboardView(),
    },
    {
      'title': 'Alertas',
      'icon': Icons.warning_rounded,
      'widget': const AlertsView(),
    },
    {
      'title': 'Histórico',
      'icon': Icons.history_rounded,
      'widget': const HistoricalView(),
    },
    {
      'title': 'Reportes',
      'icon': Icons.assessment_rounded,
      'widget': const ReportsView(),
    },
  ];

  @override
  void initState() {
    super.initState();
    // Cargar datos al iniciar
    _loadInitialData();
  }

  void _loadInitialData() {
    Future.microtask(() {
      final chamberProvider = context.read<ChamberProvider>();
      final alertProvider = context.read<AlertProvider>();

      chamberProvider.loadChambers();
      alertProvider.loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rukito',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        actions: [
          Consumer<AlertProvider>(
            builder: (context, alertProvider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded),
                    onPressed: () {
                      setState(() => _currentIndex = 1);
                    },
                  ),
                  if (alertProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.critical,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          alertProvider.unreadCount.toString(),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar de navegación
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              setState(() => _currentIndex = index);
            },
            backgroundColor: AppColors.darkGray,
            selectedIconTheme: const IconThemeData(
              color: AppColors.white,
              size: 28,
            ),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
            ),
            unselectedIconTheme: const IconThemeData(
              color: AppColors.mediumGray,
              size: 24,
            ),
            destinations: _views
                .map(
                  (view) => NavigationRailDestination(
                    icon: Icon(view['icon']),
                    selectedIcon: Icon(view['icon']),
                    label: Text(view['title']),
                  ),
                )
                .toList(),
          ),
          // Contenido principal
          Expanded(
            child: Container(
              color: AppColors.veryLightGray,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _views[_currentIndex]['widget'],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
