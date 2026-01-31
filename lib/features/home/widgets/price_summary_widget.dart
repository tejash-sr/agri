import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../price_forecast/models/price_model.dart';

class PriceSummaryWidget extends StatelessWidget {
  final List<CropPrice> priceData;

  const PriceSummaryWidget({super.key, required this.priceData});

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
                      color: AppColors.sunYellow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: AppColors.harvestOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Market Prices',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.paleGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Live',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (priceData.isEmpty)
            _buildEmptyState()
          else
            ...priceData.map((price) => _buildPriceItem(context, price)),
        ],
      ),
    );
  }

  Widget _buildPriceItem(BuildContext context, CropPrice price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Crop Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getCropColor(price.cropName).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getCropEmoji(price.cropName),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Crop Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price.cropName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  price.marketName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.darkGrey,
                  ),
                ),
              ],
            ),
          ),
          // Price Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${AppConstants.currencySymbol}${price.currentPrice.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    price.isIncreasing
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: price.isIncreasing
                        ? AppColors.success
                        : AppColors.error,
                    size: 14,
                  ),
                  Text(
                    '${price.changePercent.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: price.isIncreasing
                          ? AppColors.success
                          : AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.trending_up,
            size: 48,
            color: AppColors.mediumGrey,
          ),
          const SizedBox(height: 12),
          Text(
            'No price data available',
            style: TextStyle(color: AppColors.darkGrey),
          ),
        ],
      ),
    );
  }

  String _getCropEmoji(String cropName) {
    final name = cropName.toLowerCase();
    if (name.contains('grape')) return '🍇';
    if (name.contains('onion')) return '🧅';
    if (name.contains('tomato')) return '🍅';
    if (name.contains('rice')) return '🌾';
    if (name.contains('wheat')) return '🌾';
    if (name.contains('cotton')) return '☁️';
    if (name.contains('mango')) return '🥭';
    if (name.contains('banana')) return '🍌';
    if (name.contains('potato')) return '🥔';
    if (name.contains('apple')) return '🍎';
    return '🌱';
  }

  Color _getCropColor(String cropName) {
    final name = cropName.toLowerCase();
    if (name.contains('grape')) return const Color(0xFF7B1FA2);
    if (name.contains('onion')) return const Color(0xFFE91E63);
    if (name.contains('tomato')) return AppColors.error;
    if (name.contains('rice') || name.contains('wheat')) return AppColors.sunYellow;
    if (name.contains('cotton')) return AppColors.skyBlue;
    return AppColors.primaryGreen;
  }
}
