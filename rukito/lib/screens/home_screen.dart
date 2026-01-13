import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../providers/index.dart';
import '../widgets/frozen_background.dart';
import 'views/dashboard_view.dart';
import 'views/alerts_view.dart';
import 'views/historical_view.dart';
import 'views/reports_view.dart';
import 'user_profile_screen.dart';

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
      body: Row(
        children: [
          // Sidebar de navegación Premium
          Container(
            width: 80, 
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // Azul Medianoche (Más oscuro y elegante)
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(5, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // 1. Navegación (Arriba - Ocupa espacio proporcional)
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60.0),
                    child: Consumer<AlertProvider>(
                      builder: (context, alertProvider, _) {
                        return NavigationRail(
                          selectedIndex: _currentIndex,
                          onDestinationSelected: (int index) {
                            setState(() => _currentIndex = index);
                          },
                          backgroundColor: Colors.transparent,
                          indicatorColor: AppColors.info,
                          useIndicator: true,
                          
                          selectedIconTheme: const IconThemeData(color: Colors.white, size: 34),
                          unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.4), size: 28),
                          selectedLabelTextStyle: const TextStyle(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                          unselectedLabelTextStyle: TextStyle(
                            color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w500),
                          
                          labelType: NavigationRailLabelType.all,
                          groupAlignment: -1.0, 
                          
                          destinations: _views.asMap().entries.map((entry) {
                            final view = entry.value;
                            Widget icon = Icon(view['icon']);
                            Widget selectedIcon = Icon(view['icon']);
                            
                            if (view['title'] == 'Alertas' && alertProvider.unreadCount > 0) {
                              icon = Badge(label: Text('${alertProvider.unreadCount}'), backgroundColor: AppColors.critical, child: icon);
                              selectedIcon = Badge(label: Text('${alertProvider.unreadCount}'), backgroundColor: AppColors.critical, child: selectedIcon);
                            }

                            return NavigationRailDestination(
                              icon: Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: icon),
                              selectedIcon: Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: selectedIcon),
                              label: Text(view['title']),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),

                // 2. Branding Vertical "Grabado" (Espacio central proporcional)
                Expanded(
                  flex: 4,
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: 3, 
                      child: Text(
                        'RUKITO',
                        style: TextStyle(
                          color: const Color(0xFF1E293B),
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 16.0,
                          shadows: [
                            Shadow(offset: const Offset(1.0, 1.0), blurRadius: 1.0, color: Colors.white.withOpacity(0.1)),
                            const Shadow(offset: Offset(-2.0, -2.0), blurRadius: 4.0, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Perfil (Abajo)


                // 3. Perfil (Abajo)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: IconButton(
                    icon: const Icon(Icons.account_circle_outlined, color: Colors.white70),
                    iconSize: 32,
                    tooltip: 'Perfil de Usuario',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Contenido principal CON FONDO
          Expanded(
            child: FrozenBackground(
              child: SafeArea( // Protege contra bordes de ventana/notch
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0), // Más padding para que respire
                    child: _views[_currentIndex]['widget'],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
