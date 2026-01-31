import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class DigitalTwinScreen extends StatefulWidget {
  const DigitalTwinScreen({super.key});

  @override
  State<DigitalTwinScreen> createState() => _DigitalTwinScreenState();
}

class _DigitalTwinScreenState extends State<DigitalTwinScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  // Simulation Parameters
  double _waterLevel = 50;
  double _fertilizerLevel = 60;
  double _pestControl = 40;
  String _selectedCrop = 'Rice';
  String _selectedSeason = 'Kharif';
  
  // Simulation Results
  double _predictedYield = 0;
  double _predictedProfit = 0;
  double _riskScore = 0;
  bool _isSimulating = false;
  List<FlSpot> _yieldProjection = [];
  
  final List<String> _crops = ['Rice', 'Wheat', 'Cotton', 'Sugarcane', 'Maize', 'Soybean'];
  final List<String> _seasons = ['Kharif', 'Rabi', 'Zaid'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _runSimulation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _runSimulation() async {
    setState(() => _isSimulating = true);
    _animationController.repeat();
    
    // Simulate Monte Carlo calculation
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Calculate based on inputs
    double baseYield = _selectedCrop == 'Rice' ? 45 : 
                       _selectedCrop == 'Wheat' ? 38 :
                       _selectedCrop == 'Cotton' ? 22 : 35;
    
    double waterEffect = (_waterLevel / 100) * 0.3;
    double fertilizerEffect = (_fertilizerLevel / 100) * 0.25;
    double pestEffect = (_pestControl / 100) * 0.15;
    
    _predictedYield = baseYield * (1 + waterEffect + fertilizerEffect + pestEffect);
    _predictedProfit = _predictedYield * (_selectedCrop == 'Rice' ? 2200 : 
                                          _selectedCrop == 'Wheat' ? 2015 :
                                          _selectedCrop == 'Cotton' ? 6500 : 3500);
    _riskScore = 100 - ((_waterLevel + _fertilizerLevel + _pestControl) / 3);
    
    // Generate yield projection
    _yieldProjection = List.generate(12, (index) {
      double variation = (index < 3) ? 0.5 : (index < 6) ? 0.8 : (index < 9) ? 1.0 : 0.95;
      return FlSpot(index.toDouble(), _predictedYield * variation * (0.9 + (index * 0.02)));
    });
    
    _animationController.stop();
    setState(() => _isSimulating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFarmVisualization(),
                  const SizedBox(height: 20),
                  _buildSimulationControls(),
                  const SizedBox(height: 20),
                  _buildResultsCard(),
                  const SizedBox(height: 20),
                  _buildYieldProjectionChart(),
                  const SizedBox(height: 20),
                  _buildScenarioCards(),
                  const SizedBox(height: 20),
                  _buildOptimizationSuggestions(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _runSimulation,
        backgroundColor: AppColors.primaryGreen,
        icon: _isSimulating 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.play_arrow_rounded),
        label: Text(_isSimulating ? 'Simulating...' : 'Run Simulation'),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.deepForest,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Farm Digital Twin',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.deepForest,
                AppColors.primaryGreen,
                AppColors.oceanTeal,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -30,
                child: Icon(
                  Icons.agriculture,
                  size: 180,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: _showInfoDialog,
        ),
      ],
    );
  }

  Widget _buildFarmVisualization() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.skyBlue.withValues(alpha: 0.3),
            AppColors.primaryGreen.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Grid Lines
          ...List.generate(5, (index) {
            return Positioned(
              left: (index + 1) * (MediaQuery.of(context).size.width - 64) / 6,
              top: 0,
              bottom: 0,
              child: Container(
                width: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            );
          }),
          ...List.generate(4, (index) {
            return Positioned(
              top: (index + 1) * 40,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            );
          }),
          // Farm Elements
          Positioned(
            left: 20,
            top: 20,
            child: _buildFarmElement(Icons.water_drop, 'Water', _waterLevel, AppColors.skyBlue),
          ),
          Positioned(
            right: 20,
            top: 20,
            child: _buildFarmElement(Icons.grass, 'Fertilizer', _fertilizerLevel, AppColors.primaryGreen),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: _buildFarmElement(Icons.bug_report, 'Pest Control', _pestControl, AppColors.harvestOrange),
          ),
          // Center Crop Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.eco,
                    color: AppColors.primaryGreen,
                    size: 36,
                  ),
                  Text(
                    _selectedCrop,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ).animate(
              onPlay: (controller) => controller.repeat(reverse: true),
            ).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.05, 1.05),
              duration: const Duration(seconds: 2),
            ),
          ),
          // Simulation Indicator
          if (_isSimulating)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'Running Monte Carlo Simulation...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildFarmElement(IconData icon, String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.darkGrey,
                ),
              ),
              Text(
                '${value.toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              const Text(
                'Simulation Controls',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Crop Selection
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Crop Type', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCrop,
                          isExpanded: true,
                          items: _crops.map((crop) {
                            return DropdownMenuItem(
                              value: crop,
                              child: Text(crop),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCrop = value!);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Season', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSeason,
                          isExpanded: true,
                          items: _seasons.map((season) {
                            return DropdownMenuItem(
                              value: season,
                              child: Text(season),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedSeason = value!);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Water Slider
          _buildSlider(
            label: 'Water Irrigation',
            value: _waterLevel,
            icon: Icons.water_drop,
            color: AppColors.skyBlue,
            onChanged: (value) => setState(() => _waterLevel = value),
          ),
          const SizedBox(height: 16),
          // Fertilizer Slider
          _buildSlider(
            label: 'Fertilizer Application',
            value: _fertilizerLevel,
            icon: Icons.grass,
            color: AppColors.primaryGreen,
            onChanged: (value) => setState(() => _fertilizerLevel = value),
          ),
          const SizedBox(height: 16),
          // Pest Control Slider
          _buildSlider(
            label: 'Pest Control',
            value: _pestControl,
            icon: Icons.bug_report,
            color: AppColors.harvestOrange,
            onChanged: (value) => setState(() => _pestControl = value),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${value.toInt()}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.2),
            trackHeight: 6,
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Simulation Results',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildResultItem(
                  label: 'Predicted Yield',
                  value: '${_predictedYield.toStringAsFixed(1)} Q/ha',
                  icon: Icons.inventory_2,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildResultItem(
                  label: 'Expected Profit',
                  value: '₹${(_predictedProfit / 1000).toStringAsFixed(1)}K',
                  icon: Icons.currency_rupee,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildResultItem(
                  label: 'Risk Score',
                  value: '${_riskScore.toStringAsFixed(0)}%',
                  icon: Icons.warning_amber,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildResultItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildYieldProjectionChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              const Text(
                'Yield Projection (12 Months)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _yieldProjection.isEmpty
                ? const Center(child: Text('Run simulation to see projection'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 10,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.lightGrey,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}Q',
                                style: const TextStyle(
                                  color: AppColors.darkGrey,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                              if (value.toInt() < months.length) {
                                return Text(
                                  months[value.toInt()],
                                  style: const TextStyle(
                                    color: AppColors.darkGrey,
                                    fontSize: 10,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _yieldProjection,
                          isCurved: true,
                          color: AppColors.primaryGreen,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.2);
  }

  Widget _buildScenarioCards() {
    final scenarios = [
      {
        'title': 'Optimal Scenario',
        'yield': _predictedYield * 1.2,
        'profit': _predictedProfit * 1.3,
        'color': AppColors.success,
        'icon': Icons.trending_up,
      },
      {
        'title': 'Conservative',
        'yield': _predictedYield * 0.9,
        'profit': _predictedProfit * 0.85,
        'color': AppColors.sunYellow,
        'icon': Icons.trending_flat,
      },
      {
        'title': 'Risk Scenario',
        'yield': _predictedYield * 0.7,
        'profit': _predictedProfit * 0.6,
        'color': AppColors.error,
        'icon': Icons.trending_down,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What-If Scenarios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: scenarios.asMap().entries.map((entry) {
            final scenario = entry.value;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: entry.key < 2 ? 8 : 0,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (scenario['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (scenario['color'] as Color).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      scenario['icon'] as IconData,
                      color: scenario['color'] as Color,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scenario['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scenario['color'] as Color,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(scenario['yield'] as double).toStringAsFixed(0)}Q',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '₹${((scenario['profit'] as double) / 1000).toStringAsFixed(0)}K',
                      style: const TextStyle(
                        color: AppColors.darkGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 800 + (entry.key * 100))).scale(begin: const Offset(0.9, 0.9));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOptimizationSuggestions() {
    final suggestions = [
      {
        'title': 'Increase Irrigation',
        'description': 'Adding 10% more water could boost yield by 5%',
        'icon': Icons.water_drop,
        'color': AppColors.skyBlue,
        'impact': '+5% Yield',
      },
      {
        'title': 'Optimize Fertilizer',
        'description': 'Split application for better nutrient uptake',
        'icon': Icons.science,
        'color': AppColors.primaryGreen,
        'impact': '+8% Profit',
      },
      {
        'title': 'Pest Prevention',
        'description': 'Early intervention can reduce 15% crop loss risk',
        'icon': Icons.shield,
        'color': AppColors.harvestOrange,
        'impact': '-15% Risk',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBgGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.sunYellow),
              const SizedBox(width: 8),
              const Text(
                'AI Optimization Suggestions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...suggestions.asMap().entries.map((entry) {
            final suggestion = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: entry.key < 2 ? 12 : 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (suggestion['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      suggestion['icon'] as IconData,
                      color: suggestion['color'] as Color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          suggestion['description'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      suggestion['impact'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 1000 + (entry.key * 100))).slideX(begin: 0.2);
          }),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Digital Twin Technology'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farm Digital Twin uses advanced Monte Carlo simulation to predict outcomes based on your farm conditions.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              '• Adjust sliders to simulate different scenarios\n'
              '• View predicted yield and profit\n'
              '• Get AI-powered optimization suggestions\n'
              '• Compare what-if scenarios',
              style: TextStyle(fontSize: 13, color: AppColors.darkGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
