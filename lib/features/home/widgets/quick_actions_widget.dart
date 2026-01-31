import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class QuickActionsWidget extends StatelessWidget {
  final VoidCallback onScanDisease;
  final VoidCallback onCropRecommendation;
  final VoidCallback onPriceForecast;
  final VoidCallback onWeather;
  final VoidCallback onDigitalTwin;
  final VoidCallback onFinance;
  final VoidCallback onIrrigation;
  final VoidCallback onSustainability;
  final VoidCallback onLearning;

  const QuickActionsWidget({
    super.key,
    required this.onScanDisease,
    required this.onCropRecommendation,
    required this.onPriceForecast,
    required this.onWeather,
    required this.onDigitalTwin,
    required this.onFinance,
    required this.onIrrigation,
    required this.onSustainability,
    required this.onLearning,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.sunYellow.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.flash_on,
                color: AppColors.harvestOrange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildActionCard(
                context: context,
                icon: Icons.camera_alt_rounded,
                label: 'Scan\nDisease',
                color: AppColors.error,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFFF5722)],
                ),
                onTap: onScanDisease,
              ),
              _buildActionCard(
                context: context,
                icon: Icons.recommend_rounded,
                label: 'Crop\nAdvice',
                color: AppColors.primaryGreen,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                ),
                onTap: onCropRecommendation,
              ),
              _buildActionCard(
                context: context,
                icon: Icons.trending_up_rounded,
                label: 'Price\nForecast',
                color: AppColors.skyBlue,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
                ),
                onTap: onPriceForecast,
              ),
              _buildActionCard(
                context: context,
                icon: Icons.cloud_rounded,
                label: 'Weather\nAlerts',
                color: AppColors.oceanTeal,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
                ),
                onTap: onWeather,
              ),
              _buildActionCard(
                context: context,
                icon: Icons.hub_rounded,
                label: 'Digital\nTwin',
                color: AppColors.harvestOrange,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6F00), Color(0xFFFFA726)],
                ),
                onTap: onDigitalTwin,
              ),
              _buildActionCard(
                context: context,
                icon: Icons.account_balance_wallet_rounded,
                label: 'Farm\nFinance',
                color: const Color(0xFF7B1FA2),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
                ),
                onTap: onFinance,
              ),
              _buildActionCard(
                context: context,
                icon: Icons.water_drop_rounded,
                label: 'Smart\nIrrigation',
                color: const Color(0xFF00BCD4),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00ACC1), Color(0xFF4DD0E1)],
                ),
                onTap: onIrrigation,
              ),
              _buildActionCard(
                context: context,
                icon: Icons.eco_rounded,
                label: 'Carbon\nTracker',
                color: AppColors.deepForest,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                ),
                onTap: onSustainability,
              ),
              _buildActionCard(
                context: context,
                icon: Icons.school_rounded,
                label: 'Learn\nFarming',
                color: const Color(0xFF3F51B5),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3F51B5), Color(0xFF7986CB)],
                ),
                onTap: onLearning,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
