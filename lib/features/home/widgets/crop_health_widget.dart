import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../farm/models/farm_model.dart';

class CropHealthWidget extends StatelessWidget {
  final double healthScore;
  final Farm? farm;

  const CropHealthWidget({
    super.key,
    required this.healthScore,
    this.farm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.eco,
                      color: AppColors.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crop Health',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        farm?.name ?? 'Your Farm',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _buildHealthBadge(context),
            ],
          ),
          const SizedBox(height: 20),
          // Health Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Health Score',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.darkGrey,
                    ),
                  ),
                  Text(
                    '${(healthScore * 100).toInt()}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getHealthColor(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: healthScore,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getHealthColor(),
                            _getHealthColor().withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: _getHealthColor().withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Crop Stats
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.grass,
                  'Active Crops',
                  '${farm?.crops.length ?? 3}',
                  AppColors.primaryGreen,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.lightGrey,
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.landscape,
                  'Farm Area',
                  '${farm?.totalArea ?? 25.5} ${farm?.areaUnit ?? 'Acres'}',
                  AppColors.soilBrown,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.lightGrey,
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.water_drop,
                  'Soil Moisture',
                  '${((farm?.soilMoisture ?? 0.65) * 100).toInt()}%',
                  AppColors.skyBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Active Crops
          if (farm?.crops.isNotEmpty ?? false)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: farm!.crops.map((crop) => _buildCropChip(crop)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildHealthBadge(BuildContext context) {
    String status;
    Color color;
    IconData icon;

    if (healthScore >= 0.8) {
      status = 'Excellent';
      color = AppColors.success;
      icon = Icons.check_circle;
    } else if (healthScore >= 0.6) {
      status = 'Good';
      color = AppColors.lightGreen;
      icon = Icons.thumb_up;
    } else if (healthScore >= 0.4) {
      status = 'Fair';
      color = AppColors.warning;
      icon = Icons.info;
    } else {
      status = 'Needs Attention';
      color = AppColors.error;
      icon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.darkGrey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCropChip(String crop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.paleGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_florist,
            color: AppColors.primaryGreen,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            crop,
            style: const TextStyle(
              color: AppColors.primaryGreen,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor() {
    if (healthScore >= 0.8) return AppColors.success;
    if (healthScore >= 0.6) return AppColors.lightGreen;
    if (healthScore >= 0.4) return AppColors.warning;
    return AppColors.error;
  }
}
