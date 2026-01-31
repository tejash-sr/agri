import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';
import '../../../providers/app_provider.dart';
import '../../disease_scanner/screens/disease_scanner_screen.dart';
import '../../crop_recommendation/screens/crop_recommendation_screen.dart';
import '../../price_forecast/screens/price_forecast_screen.dart';
import '../../weather/screens/weather_screen.dart';
import '../../digital_twin/screens/digital_twin_screen.dart';
import '../../finance/screens/finance_screen.dart';
import '../../irrigation/screens/irrigation_screen.dart';
import '../../sustainability/screens/sustainability_screen.dart';
import '../../learning/screens/learning_screen.dart';
import '../widgets/weather_widget.dart';
import '../widgets/crop_health_widget.dart';
import '../widgets/quick_actions_widget.dart';
import '../widgets/price_summary_widget.dart';
import '../widgets/alerts_preview_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final showTitle = _scrollController.offset > 80;
    if (showTitle != _showTitle) {
      setState(() => _showTitle = showTitle);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              provider.refreshData();
            },
            color: AppColors.primaryGreen,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 140,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.white,
                  surfaceTintColor: AppColors.white,
                  title: AnimatedOpacity(
                    opacity: _showTitle ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      'AgriSense Pro',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () {
                        // Voice assistant
                        _showVoiceAssistant(context);
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: AppColors.primaryGreen,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeader(context, provider),
                  ),
                ),
                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Weather Widget
                      WeatherWidget(weather: provider.currentWeather)
                          .animate()
                          .fadeIn(duration: const Duration(milliseconds: 400))
                          .slideX(begin: -0.1, end: 0),
                      const SizedBox(height: 16),
                      
                      // Crop Health Widget
                      CropHealthWidget(
                        healthScore: provider.overallCropHealth,
                        farm: provider.currentFarm,
                      )
                          .animate()
                          .fadeIn(
                            duration: const Duration(milliseconds: 400),
                            delay: const Duration(milliseconds: 100),
                          )
                          .slideX(begin: 0.1, end: 0),
                      const SizedBox(height: 16),
                      
                      // Quick Actions
                      QuickActionsWidget(
                        onScanDisease: () => _navigateTo(context, const DiseaseScannerScreen()),
                        onCropRecommendation: () => _navigateTo(context, const CropRecommendationScreen()),
                        onPriceForecast: () => _navigateTo(context, const PriceForecastScreen()),
                        onWeather: () => _navigateTo(context, const WeatherScreen()),
                        onDigitalTwin: () => _navigateTo(context, const DigitalTwinScreen()),
                        onFinance: () => _navigateTo(context, const FinanceScreen()),
                        onIrrigation: () => _navigateTo(context, const IrrigationScreen()),
                        onSustainability: () => _navigateTo(context, const SustainabilityScreen()),
                        onLearning: () => _navigateTo(context, const LearningScreen()),
                      )
                          .animate()
                          .fadeIn(
                            duration: const Duration(milliseconds: 400),
                            delay: const Duration(milliseconds: 200),
                          ),
                      const SizedBox(height: 16),
                      
                      // Price Summary
                      PriceSummaryWidget(priceData: provider.priceData)
                          .animate()
                          .fadeIn(
                            duration: const Duration(milliseconds: 400),
                            delay: const Duration(milliseconds: 300),
                          )
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 16),
                      
                      // Alerts Preview
                      AlertsPreviewWidget(alerts: provider.alerts)
                          .animate()
                          .fadeIn(
                            duration: const Duration(milliseconds: 400),
                            delay: const Duration(milliseconds: 400),
                          )
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 24),
                      
                      // AI Features Grid
                      _buildAIFeaturesSection(context),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateTo(context, const DiseaseScannerScreen()),
            backgroundColor: AppColors.primaryGreen,
            icon: const Icon(Icons.camera_alt_rounded, color: AppColors.white),
            label: const Text(
              'Scan Crop',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 600))
              .scale(delay: const Duration(milliseconds: 600)),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider provider) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          // User Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                provider.userName.isNotEmpty
                    ? provider.userName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User Info
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  provider.userName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      provider.userLocation,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning! ☀️';
    } else if (hour < 17) {
      return 'Good Afternoon! 🌤️';
    } else {
      return 'Good Evening! 🌙';
    }
  }

  Widget _buildAIFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'AI-Powered Features',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            FeatureCard(
              icon: Icons.satellite_alt,
              title: 'Satellite Monitoring',
              description: 'NDVI-based crop health from space',
              color: AppColors.skyBlue,
              onTap: () => _showComingSoon(context, 'Satellite Monitoring'),
            ),
            FeatureCard(
              icon: Icons.science,
              title: 'Soil Analysis',
              description: 'AI-powered soil health insights',
              color: AppColors.soilBrown,
              onTap: () => _showComingSoon(context, 'Soil Analysis'),
            ),
            FeatureCard(
              icon: Icons.pest_control,
              title: 'Pest Prediction',
              description: 'Early pest outbreak warnings',
              color: AppColors.error,
              onTap: () => _showComingSoon(context, 'Pest Prediction'),
            ),
            FeatureCard(
              icon: Icons.analytics,
              title: 'Yield Prediction',
              description: 'AI-based harvest estimates',
              color: AppColors.oceanTeal,
              onTap: () => _showComingSoon(context, 'Yield Prediction'),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showVoiceAssistant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mediumGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: AppColors.white,
                size: 40,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: const Duration(milliseconds: 800),
                )
                .then()
                .scale(
                  begin: const Offset(1.1, 1.1),
                  end: const Offset(1, 1),
                  duration: const Duration(milliseconds: 800),
                ),
            const SizedBox(height: 24),
            Text(
              'Voice Assistant',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me anything about your farm',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('What\'s the weather today?'),
                _buildSuggestionChip('Best time to sell grapes?'),
                _buildSuggestionChip('Check crop health'),
                _buildSuggestionChip('Market prices'),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Supports Hindi, Tamil, Telugu, and more',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.darkGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paleGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.rocket_launch, color: AppColors.white, size: 20),
            const SizedBox(width: 12),
            Text('$feature - Coming Soon in Premium!'),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
