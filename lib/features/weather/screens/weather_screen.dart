import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  int _selectedDayIndex = 0;

  final List<Map<String, dynamic>> _weeklyForecast = [
    {
      'day': 'Today',
      'date': 'Jan 31',
      'temp': 28,
      'tempMin': 18,
      'tempMax': 32,
      'condition': 'Sunny',
      'icon': Icons.wb_sunny,
      'humidity': 65,
      'wind': 12,
      'rainfall': 0,
      'uvIndex': 8,
      'pressure': 1013,
      'visibility': 10,
      'hourly': [22, 23, 25, 28, 30, 32, 31, 29, 27, 25, 23, 21],
    },
    {
      'day': 'Sat',
      'date': 'Feb 1',
      'temp': 26,
      'tempMin': 17,
      'tempMax': 30,
      'condition': 'Partly Cloudy',
      'icon': Icons.cloud,
      'humidity': 70,
      'wind': 15,
      'rainfall': 5,
      'uvIndex': 6,
      'pressure': 1010,
      'visibility': 8,
      'hourly': [20, 21, 23, 26, 28, 30, 29, 27, 25, 23, 21, 19],
    },
    {
      'day': 'Sun',
      'date': 'Feb 2',
      'temp': 24,
      'tempMin': 16,
      'tempMax': 28,
      'condition': 'Rainy',
      'icon': Icons.water_drop,
      'humidity': 85,
      'wind': 20,
      'rainfall': 25,
      'uvIndex': 3,
      'pressure': 1005,
      'visibility': 5,
      'hourly': [18, 19, 20, 22, 24, 26, 25, 24, 22, 20, 18, 17],
    },
    {
      'day': 'Mon',
      'date': 'Feb 3',
      'temp': 22,
      'tempMin': 15,
      'tempMax': 26,
      'condition': 'Thunderstorm',
      'icon': Icons.thunderstorm,
      'humidity': 90,
      'wind': 30,
      'rainfall': 45,
      'uvIndex': 2,
      'pressure': 1002,
      'visibility': 3,
      'hourly': [17, 18, 19, 20, 22, 24, 23, 22, 20, 19, 17, 16],
    },
    {
      'day': 'Tue',
      'date': 'Feb 4',
      'temp': 25,
      'tempMin': 16,
      'tempMax': 29,
      'condition': 'Cloudy',
      'icon': Icons.cloud_queue,
      'humidity': 75,
      'wind': 18,
      'rainfall': 10,
      'uvIndex': 4,
      'pressure': 1008,
      'visibility': 7,
      'hourly': [19, 20, 22, 24, 26, 28, 27, 26, 24, 22, 20, 18],
    },
    {
      'day': 'Wed',
      'date': 'Feb 5',
      'temp': 27,
      'tempMin': 17,
      'tempMax': 31,
      'condition': 'Sunny',
      'icon': Icons.wb_sunny,
      'humidity': 60,
      'wind': 10,
      'rainfall': 0,
      'uvIndex': 7,
      'pressure': 1012,
      'visibility': 10,
      'hourly': [20, 21, 24, 27, 29, 31, 30, 28, 26, 24, 22, 20],
    },
    {
      'day': 'Thu',
      'date': 'Feb 6',
      'temp': 29,
      'tempMin': 19,
      'tempMax': 33,
      'condition': 'Hot',
      'icon': Icons.wb_sunny,
      'humidity': 55,
      'wind': 8,
      'rainfall': 0,
      'uvIndex': 9,
      'pressure': 1015,
      'visibility': 10,
      'hourly': [22, 24, 26, 29, 31, 33, 32, 30, 28, 26, 24, 22],
    },
  ];

  final List<Map<String, dynamic>> _climateRisks = [
    {
      'risk': 'Heat Stress',
      'level': 'High',
      'color': AppColors.error,
      'description': 'High temperatures expected in 4-5 days',
      'recommendation': 'Increase irrigation frequency, provide shade for sensitive crops',
    },
    {
      'risk': 'Heavy Rainfall',
      'level': 'Medium',
      'color': AppColors.warning,
      'description': 'Thunderstorms predicted for Sunday-Monday',
      'recommendation': 'Ensure proper drainage, delay fertilizer application',
    },
    {
      'risk': 'Wind Damage',
      'level': 'Low',
      'color': AppColors.success,
      'description': 'Moderate winds expected',
      'recommendation': 'No immediate action required',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selectedDay = _weeklyForecast[_selectedDayIndex];
    
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          _buildWeatherAppBar(selectedDay),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWeeklyForecast(),
                  const SizedBox(height: 20),
                  _buildHourlyChart(selectedDay),
                  const SizedBox(height: 20),
                  _buildWeatherDetails(selectedDay),
                  const SizedBox(height: 20),
                  _buildClimateRisks(),
                  const SizedBox(height: 20),
                  _buildFarmingAdvisory(selectedDay),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAppBar(Map<String, dynamic> weather) {
    Color bgColor;
    List<Color> gradientColors;
    
    switch (weather['condition']) {
      case 'Rainy':
      case 'Thunderstorm':
        bgColor = const Color(0xFF546E7A);
        gradientColors = [const Color(0xFF546E7A), const Color(0xFF37474F)];
        break;
      case 'Cloudy':
      case 'Partly Cloudy':
        bgColor = const Color(0xFF78909C);
        gradientColors = [const Color(0xFF78909C), const Color(0xFF607D8B)];
        break;
      default:
        bgColor = AppColors.skyBlue;
        gradientColors = [AppColors.skyBlue, const Color(0xFF0277BD)];
    }

    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: bgColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.location_on, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        'Pune, Maharashtra',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${weather['temp']}°',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 72,
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                          Text(
                            weather['condition'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'H:${weather['tempMax']}° L:${weather['tempMin']}°',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        weather['icon'],
                        color: Colors.white,
                        size: 100,
                      ).animate(
                        onPlay: (controller) => controller.repeat(),
                      ).shimmer(
                        duration: const Duration(seconds: 3),
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyForecast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '7-Day Forecast',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _weeklyForecast.length,
            itemBuilder: (context, index) {
              final day = _weeklyForecast[index];
              final isSelected = index == _selectedDayIndex;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedDayIndex = index),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryGreen : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primaryGreen.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day['day'],
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.darkGrey,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        day['icon'],
                        color: isSelected ? Colors.white : AppColors.skyBlue,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${day['temp']}°',
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.charcoal,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (day['rainfall'] > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.water_drop,
                              size: 10,
                              color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.skyBlue,
                            ),
                            Text(
                              '${day['rainfall']}mm',
                              style: TextStyle(
                                fontSize: 9,
                                color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.darkGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).slideX(begin: 0.2),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyChart(Map<String, dynamic> weather) {
    final hourlyData = weather['hourly'] as List<int>;
    
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
              Icon(Icons.access_time, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              const Text(
                'Hourly Temperature',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
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
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}°',
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
                        final hours = ['6a', '8a', '10a', '12p', '2p', '4p', '6p', '8p', '10p', '12a', '2a', '4a'];
                        if (value.toInt() < hours.length) {
                          return Text(
                            hours[value.toInt()],
                            style: const TextStyle(
                              color: AppColors.darkGrey,
                              fontSize: 9,
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
                    spots: hourlyData.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: AppColors.harvestOrange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.harvestOrange.withValues(alpha: 0.3),
                          AppColors.harvestOrange.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }

  Widget _buildWeatherDetails(Map<String, dynamic> weather) {
    final details = [
      {'icon': Icons.water_drop, 'label': 'Humidity', 'value': '${weather['humidity']}%', 'color': AppColors.skyBlue},
      {'icon': Icons.air, 'label': 'Wind', 'value': '${weather['wind']} km/h', 'color': AppColors.oceanTeal},
      {'icon': Icons.wb_sunny, 'label': 'UV Index', 'value': '${weather['uvIndex']}', 'color': AppColors.sunYellow},
      {'icon': Icons.compress, 'label': 'Pressure', 'value': '${weather['pressure']} hPa', 'color': AppColors.primaryGreen},
      {'icon': Icons.visibility, 'label': 'Visibility', 'value': '${weather['visibility']} km', 'color': AppColors.darkGrey},
      {'icon': Icons.umbrella, 'label': 'Rainfall', 'value': '${weather['rainfall']} mm', 'color': AppColors.info},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: details.length,
      itemBuilder: (context, index) {
        final detail = details[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                detail['icon'] as IconData,
                color: detail['color'] as Color,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                detail['value'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                detail['label'] as String,
                style: const TextStyle(
                  color: AppColors.darkGrey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 400 + (index * 50))).scale(begin: const Offset(0.9, 0.9));
      },
    );
  }

  Widget _buildClimateRisks() {
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
              Icon(Icons.warning_amber, color: AppColors.warning),
              const SizedBox(width: 8),
              const Text(
                'Climate Risk Assessment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._climateRisks.asMap().entries.map((entry) {
            final risk = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: entry.key < _climateRisks.length - 1 ? 12 : 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (risk['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (risk['color'] as Color).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: risk['color'] as Color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          risk['level'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        risk['risk'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    risk['description'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 14, color: AppColors.primaryGreen),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          risk['recommendation'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 600 + (entry.key * 100))).slideX(begin: 0.2);
          }),
        ],
      ),
    );
  }

  Widget _buildFarmingAdvisory(Map<String, dynamic> weather) {
    final advisories = <Map<String, dynamic>>[];
    
    if (weather['rainfall'] > 20) {
      advisories.add({
        'title': 'Delay Irrigation',
        'description': 'Heavy rainfall expected. Save water resources.',
        'icon': Icons.do_not_disturb_on,
        'priority': 'High',
      });
      advisories.add({
        'title': 'Check Drainage',
        'description': 'Ensure field drainage is clear to prevent waterlogging.',
        'icon': Icons.water_damage,
        'priority': 'High',
      });
    }
    
    if (weather['temp'] > 30) {
      advisories.add({
        'title': 'Irrigate Early Morning',
        'description': 'Avoid midday irrigation to reduce water loss.',
        'icon': Icons.schedule,
        'priority': 'Medium',
      });
    }
    
    if (weather['wind'] > 20) {
      advisories.add({
        'title': 'Delay Spraying',
        'description': 'High winds may cause pesticide drift.',
        'icon': Icons.do_not_disturb,
        'priority': 'Medium',
      });
    }
    
    if (advisories.isEmpty) {
      advisories.add({
        'title': 'Good Conditions',
        'description': 'Weather is favorable for most farming activities.',
        'icon': Icons.check_circle,
        'priority': 'Info',
      });
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.1),
            AppColors.oceanTeal.withValues(alpha: 0.1),
          ],
        ),
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
              Icon(Icons.agriculture, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              const Text(
                'Farming Advisory',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...advisories.asMap().entries.map((entry) {
            final advisory = entry.value;
            Color priorityColor;
            switch (advisory['priority']) {
              case 'High':
                priorityColor = AppColors.error;
                break;
              case 'Medium':
                priorityColor = AppColors.warning;
                break;
              default:
                priorityColor = AppColors.success;
            }
            
            return Container(
              margin: EdgeInsets.only(bottom: entry.key < advisories.length - 1 ? 12 : 0),
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
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      advisory['icon'] as IconData,
                      color: priorityColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              advisory['title'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: priorityColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                advisory['priority'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          advisory['description'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 800 + (entry.key * 100))).slideX(begin: 0.2);
          }),
        ],
      ),
    );
  }
}
