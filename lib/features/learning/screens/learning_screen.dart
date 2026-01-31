import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _courses = [
    {
      'title': 'Modern Rice Cultivation',
      'description': 'Learn advanced techniques for higher yield',
      'duration': '2h 30m',
      'lessons': 12,
      'progress': 0.65,
      'image': 'rice',
      'rating': 4.8,
      'enrolled': 1250,
      'instructor': 'Dr. Sharma',
      'category': 'Crops',
      'level': 'Intermediate',
    },
    {
      'title': 'Organic Farming Basics',
      'description': 'Complete guide to organic certification',
      'duration': '3h 15m',
      'lessons': 18,
      'progress': 0.0,
      'image': 'organic',
      'rating': 4.9,
      'enrolled': 2340,
      'instructor': 'Prof. Patel',
      'category': 'Organic',
      'level': 'Beginner',
    },
    {
      'title': 'Pest & Disease Management',
      'description': 'Identify and treat common crop diseases',
      'duration': '1h 45m',
      'lessons': 8,
      'progress': 1.0,
      'image': 'pest',
      'rating': 4.7,
      'enrolled': 890,
      'instructor': 'Dr. Kumar',
      'category': 'Protection',
      'level': 'Advanced',
    },
    {
      'title': 'Smart Irrigation Techniques',
      'description': 'Water conservation and drip irrigation',
      'duration': '2h 00m',
      'lessons': 10,
      'progress': 0.30,
      'image': 'irrigation',
      'rating': 4.6,
      'enrolled': 1560,
      'instructor': 'Eng. Singh',
      'category': 'Technology',
      'level': 'Intermediate',
    },
  ];

  final List<Map<String, dynamic>> _dailyTips = [
    {
      'title': 'Best Time to Irrigate',
      'content': 'Early morning (6-8 AM) irrigation reduces water loss by 40% compared to midday.',
      'icon': Icons.water_drop,
      'color': AppColors.skyBlue,
    },
    {
      'title': 'Soil pH Check',
      'content': 'Test soil pH monthly during growing season. Most crops prefer pH 6.0-7.0.',
      'icon': Icons.science,
      'color': AppColors.primaryGreen,
    },
    {
      'title': 'Weather Alert',
      'content': 'Rain expected in 3 days. Delay fertilizer application to prevent runoff.',
      'icon': Icons.cloud,
      'color': AppColors.oceanTeal,
    },
  ];

  final List<Map<String, dynamic>> _articles = [
    {
      'title': 'Climate-Smart Agriculture: Adapting to Changing Weather',
      'author': 'Agricultural Research Institute',
      'readTime': '8 min',
      'category': 'Climate',
      'date': 'Today',
    },
    {
      'title': 'Maximizing Profit with MSP: A Complete Guide',
      'author': 'Ministry of Agriculture',
      'readTime': '5 min',
      'category': 'Finance',
      'date': 'Yesterday',
    },
    {
      'title': 'Natural Pest Control Methods That Actually Work',
      'author': 'ICAR Research',
      'readTime': '6 min',
      'category': 'Organic',
      'date': '2 days ago',
    },
  ];

  final List<String> _categories = ['All', 'Crops', 'Organic', 'Protection', 'Technology', 'Finance'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  _buildDailyTip(),
                  const SizedBox(height: 20),
                  _buildLearningProgress(),
                  const SizedBox(height: 20),
                  _buildCategoryFilter(),
                  const SizedBox(height: 16),
                  _buildCoursesList(),
                  const SizedBox(height: 20),
                  _buildQuickLessons(),
                  const SizedBox(height: 20),
                  _buildArticlesSection(),
                  const SizedBox(height: 20),
                  _buildExpertAdvice(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.sunYellow,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmark_outline, color: AppColors.charcoal),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.charcoal),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Learning Hub',
          style: TextStyle(
            color: AppColors.charcoal,
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
                AppColors.sunYellow,
                AppColors.harvestOrange.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: 20,
                child: Icon(
                  Icons.school,
                  size: 150,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyTip() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.oceanTeal,
          ],
        ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text(
                "Today's Farming Tip",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text(
                  'More Tips',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Nitrogen Application Timing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Apply nitrogen fertilizer in 3 split doses: 50% at transplanting, 25% at tillering, and 25% at panicle initiation for optimal rice yield.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTipTag('Rice'),
              const SizedBox(width: 8),
              _buildTipTag('Fertilizer'),
              const SizedBox(width: 8),
              _buildTipTag('Yield+'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildTipTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLearningProgress() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Learning Journey',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sunYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department, color: AppColors.sunYellow, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '7 Day Streak!',
                      style: TextStyle(
                        color: AppColors.harvestOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildProgressStat('Courses', '4', 'In Progress', AppColors.primaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressStat('Completed', '12', 'Courses', AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressStat('Hours', '28', 'Learned', AppColors.skyBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressStat('Badges', '8', 'Earned', AppColors.sunYellow),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2);
  }

  Widget _buildProgressStat(String label, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: AppColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primaryGreen : AppColors.mediumGrey,
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.charcoal,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoursesList() {
    final filteredCourses = _selectedCategory == 'All'
        ? _courses
        : _courses.where((c) => c['category'] == _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Courses for You',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(filteredCourses.length, (index) {
          final course = filteredCourses[index];
          return _buildCourseCard(course, index);
        }),
      ],
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course, int index) {
    Color statusColor;
    String statusText;
    if (course['progress'] == 1.0) {
      statusColor = AppColors.success;
      statusText = 'Completed';
    } else if (course['progress'] > 0) {
      statusColor = AppColors.primaryGreen;
      statusText = '${(course['progress'] * 100).toInt()}% Complete';
    } else {
      statusColor = AppColors.skyBlue;
      statusText = 'Start Learning';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGreen.withValues(alpha: 0.8),
                  AppColors.oceanTeal.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 20,
                  top: 20,
                  child: Icon(
                    Icons.eco,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          course['level'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        course['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course['description'],
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppColors.darkGrey),
                    const SizedBox(width: 4),
                    Text(
                      course['instructor'],
                      style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: AppColors.darkGrey),
                    const SizedBox(width: 4),
                    Text(
                      course['duration'],
                      style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.play_lesson, size: 16, color: AppColors.darkGrey),
                    const SizedBox(width: 4),
                    Text(
                      '${course['lessons']} lessons',
                      style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (course['progress'] > 0) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: course['progress'],
                      backgroundColor: AppColors.lightGrey,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: AppColors.sunYellow),
                        const SizedBox(width: 4),
                        Text(
                          '${course['rating']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${course['enrolled']} enrolled)',
                          style: TextStyle(
                            color: AppColors.darkGrey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 300 + (index * 100))).slideY(begin: 0.2);
  }

  Widget _buildQuickLessons() {
    final quickLessons = [
      {'title': 'Seed Selection', 'duration': '5 min', 'icon': Icons.grain},
      {'title': 'Soil Testing', 'duration': '7 min', 'icon': Icons.science},
      {'title': 'Composting', 'duration': '6 min', 'icon': Icons.recycling},
      {'title': 'Crop Rotation', 'duration': '8 min', 'icon': Icons.loop},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Lessons (5-10 min)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: quickLessons.length,
            itemBuilder: (context, index) {
              final lesson = quickLessons[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.sunYellow.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            lesson['icon'] as IconData,
                            color: AppColors.sunYellow,
                            size: 18,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.play_circle_fill, color: AppColors.primaryGreen),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      lesson['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      lesson['duration'] as String,
                      style: TextStyle(
                        color: AppColors.darkGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 500 + (index * 100))).slideX(begin: 0.2);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArticlesSection() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.article, color: AppColors.primaryGreen),
                  const SizedBox(width: 8),
                  const Text(
                    'Latest Articles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(_articles.length, (index) {
            final article = _articles[index];
            return Container(
              margin: EdgeInsets.only(bottom: index < _articles.length - 1 ? 12 : 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.article,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              article['readTime'],
                              style: TextStyle(
                                color: AppColors.darkGrey,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.mediumGrey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              article['date'],
                              style: TextStyle(
                                color: AppColors.darkGrey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.mediumGrey),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 600 + (index * 100))).slideX(begin: 0.2);
          }),
        ],
      ),
    );
  }

  Widget _buildExpertAdvice() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.soilBrown.withValues(alpha: 0.1),
            AppColors.sunYellow.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.soilBrown.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.support_agent, color: AppColors.soilBrown),
              const SizedBox(width: 8),
              const Text(
                'Ask an Expert',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Get personalized advice from agricultural experts for your specific farming challenges.',
            style: TextStyle(
              color: AppColors.darkGrey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.soilBrown,
                    side: BorderSide(color: AppColors.soilBrown),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.video_call),
                  label: const Text('Video Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.soilBrown,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
