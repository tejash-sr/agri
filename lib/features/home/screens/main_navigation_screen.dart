import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_provider.dart';
import 'home_screen.dart';
import '../../farm/screens/farm_screen.dart';
import '../../marketplace/screens/marketplace_screen.dart';
import '../../alerts/screens/alerts_screen.dart';
import '../../profile/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const FarmScreen(),
    const MarketplaceScreen(),
    const AlertsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: IndexedStack(
            index: provider.currentNavIndex,
            children: _screens,
          ),
          bottomNavigationBar: _buildBottomNav(context, provider),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context, AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: provider.currentNavIndex == 0,
                onTap: () => provider.setNavIndex(0),
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.agriculture_rounded,
                label: 'Farm',
                isSelected: provider.currentNavIndex == 1,
                onTap: () => provider.setNavIndex(1),
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.store_rounded,
                label: 'Market',
                isSelected: provider.currentNavIndex == 2,
                onTap: () => provider.setNavIndex(2),
              ),
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.notifications_rounded,
                label: 'Alerts',
                isSelected: provider.currentNavIndex == 3,
                onTap: () => provider.setNavIndex(3),
                badge: provider.unreadAlerts,
              ),
              _buildNavItem(
                context: context,
                index: 4,
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: provider.currentNavIndex == 4,
                onTap: () => provider.setNavIndex(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.mediumGrey,
                ),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badge > 9 ? '9+' : badge.toString(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.primaryGreen
                    : AppColors.mediumGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
