import 'package:flutter/material.dart';
import 'package:energy_app/views/home.dart';
import 'package:energy_app/views/temperature.dart';
import 'package:energy_app/views/profile.dart';
import '../views/energy.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({Key? key}) : super(key: key);

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomePage(),
    const EnergyPage(),
    const TemperaturePage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.white,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedItemColor: const Color(0xFF1976D2),
            unselectedItemColor: Colors.grey[500],
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              height: 1.5,
            ),
            type: BottomNavigationBarType.fixed,
            items: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_filled,
                label: 'Accueil',
                isSelected: _selectedIndex == 0,
              ),
              _buildNavItem(
                icon: Icons.bolt_outlined,
                activeIcon: Icons.bolt,
                label: 'Énergie',
                isSelected: _selectedIndex == 1,
              ),
              _buildNavItem(
                icon: Icons.thermostat_outlined,
                activeIcon: Icons.thermostat,
                label: 'Température',
                isSelected: _selectedIndex == 2,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
                isSelected: _selectedIndex == 3,
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? const Color(0xFF1976D2).withOpacity(0.2)
              : Colors.transparent,
        ),
        child: Icon(isSelected ? activeIcon : icon, size: 24),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1976D2).withOpacity(0.2),
        ),
        child: Icon(activeIcon, size: 24),
      ),
      label: label,
    );
  }
}