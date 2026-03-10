import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_content.dart';
import 'vault_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    // Initialize API service with base URL
    // For iOS Simulator: http://localhost:8000
    // For Android Emulator: http://10.0.2.2:8000
    // For Physical Device: http://YOUR_COMPUTER_IP:8000
    _apiService = ApiService(baseUrl: 'http://localhost:8000');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final screens = [
      const HomeContent(),
      VaultScreen(apiService: _apiService),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Vault',
          ),
        ],
      ),
    );
  }
}
