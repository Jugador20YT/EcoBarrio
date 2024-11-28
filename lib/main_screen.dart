import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'calendar_screen.dart';
import 'admin_calendar_screen.dart';
import 'user_calendar_screen.dart';
import 'home_screen.dart';
import 'report_screen.dart';
import 'chat_screen.dart';
import 'camioneros_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final String userRole;

  MainScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isLocked = false; // Nuevo estado para bloquear interacciones

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

  List<Widget> _getScreens() {
    if (widget.userRole == 'admin') {
      return [
        AdminCalendarScreen(), // Pantalla para administradores
        ChatScreen(),
        ReportScreen(),
        Center(child: Text('Perfil (Admin)')),
      ];
    } else if (widget.userRole == 'camionero') {
      return [
        ChatScreen(),
        ReportScreen(),
        CalendarScreen(userRole: widget.userRole), // Calendario para camioneros
        CamionerosScreen(
          userId: userId,
          onLock: _lockNavigation, // Bloquear navegación
        ),
      ];
    } else {
      return [
        HomeScreen(),
        ChatScreen(),
        ReportScreen(),
        UserCalendarScreen(), // Calendario para usuarios
        ProfileScreen(),
      ];
    }
  }

  List<BottomNavigationBarItem> _getBottomNavItems() {
    if (widget.userRole == 'admin') {
      return const [
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: 'Calendario'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reportes'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ];
    } else if (widget.userRole == 'camionero') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reportes'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: 'Calendario'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reportes'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: 'Calendario'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ];
    }
  }

  void _lockNavigation(bool lock) {
    setState(() {
      _isLocked = lock;
    });
  }

  void _onItemTapped(int index) {
    if (!_isLocked) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _logout() async {
    if (!_isLocked) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();
    final navItems = _getBottomNavItems();

    return Scaffold(
      appBar: AppBar(
        title: Text('Eco Barrio'),
        actions: [
          if (!_isLocked)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
            ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
