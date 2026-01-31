import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isListening = false;
  String _recognizedText = '';
  String _selectedLanguage = 'हिंदी';
  
  final List<Map<String, dynamic>> _chatHistory = [
    {
      'type': 'bot',
      'message': 'नमस्ते! मैं आपका कृषि सहायक हूं। आप मुझसे खेती से जुड़ा कोई भी सवाल पूछ सकते हैं।',
      'translation': 'Hello! I am your agricultural assistant. You can ask me any farming-related questions.',
      'time': '10:00 AM',
    },
    {
      'type': 'user',
      'message': 'मेरी धान की फसल में पीले पत्ते दिख रहे हैं',
      'translation': 'Yellow leaves are appearing in my rice crop',
      'time': '10:02 AM',
    },
    {
      'type': 'bot',
      'message': 'धान में पीले पत्ते कई कारणों से हो सकते हैं:\n\n1. नाइट्रोजन की कमी - यूरिया का छिड़काव करें\n2. जिंक की कमी - जिंक सल्फेट 5kg/एकड़ डालें\n3. पानी की कमी - सिंचाई बढ़ाएं\n\nक्या आप फोटो भेज सकते हैं?',
      'translation': 'Yellow leaves in rice can be due to several reasons:\n\n1. Nitrogen deficiency - Apply urea spray\n2. Zinc deficiency - Apply zinc sulfate 5kg/acre\n3. Water shortage - Increase irrigation\n\nCan you send a photo?',
      'time': '10:02 AM',
    },
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {'label': 'Crop Disease', 'icon': Icons.bug_report, 'query': 'मेरी फसल में बीमारी है'},
    {'label': 'Weather', 'icon': Icons.cloud, 'query': 'आज का मौसम कैसा है'},
    {'label': 'Market Price', 'icon': Icons.trending_up, 'query': 'आज का बाजार भाव क्या है'},
    {'label': 'Irrigation', 'icon': Icons.water_drop, 'query': 'सिंचाई कब करनी चाहिए'},
    {'label': 'Fertilizer', 'icon': Icons.science, 'query': 'कौन सी खाद डालनी चाहिए'},
    {'label': 'Govt Scheme', 'icon': Icons.account_balance, 'query': 'सरकारी योजनाएं बताओ'},
  ];

  final List<String> _languages = ['हिंदी', 'English', 'मराठी', 'தமிழ்', 'తెలుగు', 'ਪੰਜਾਬੀ'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _animationController.repeat();
        // Simulate voice recognition
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _isListening) {
            setState(() {
              _isListening = false;
              _recognizedText = 'गेहूं की बुवाई का सही समय क्या है?';
              _animationController.stop();
            });
            _processVoiceInput(_recognizedText);
          }
        });
      } else {
        _animationController.stop();
      }
    });
  }

  void _processVoiceInput(String text) {
    setState(() {
      _chatHistory.add({
        'type': 'user',
        'message': text,
        'translation': 'What is the right time for wheat sowing?',
        'time': '10:05 AM',
      });
    });

    // Simulate bot response
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _chatHistory.add({
            'type': 'bot',
            'message': 'गेहूं की बुवाई का सबसे अच्छा समय अक्टूबर के अंतिम सप्ताह से नवंबर के दूसरे सप्ताह तक है।\n\n📅 उत्तर भारत: 15 अक्टूबर - 15 नवंबर\n📅 मध्य भारत: 1-30 नवंबर\n📅 दक्षिण भारत: 15 नवंबर - 15 दिसंबर\n\nआपके क्षेत्र में तापमान 20-25°C होना चाहिए।',
            'translation': 'The best time for wheat sowing is from the last week of October to the second week of November.\n\n📅 North India: Oct 15 - Nov 15\n📅 Central India: Nov 1-30\n📅 South India: Nov 15 - Dec 15\n\nTemperature in your area should be 20-25°C.',
            'time': '10:05 AM',
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildChatArea(),
          ),
          _buildQuickActions(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepForest,
            AppColors.primaryGreen,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'Krishi Voice Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.language, color: Colors.white),
                onSelected: (value) => setState(() => _selectedLanguage = value),
                itemBuilder: (context) => _languages.map((lang) {
                  return PopupMenuItem(
                    value: lang,
                    child: Row(
                      children: [
                        if (lang == _selectedLanguage)
                          const Icon(Icons.check, color: AppColors.primaryGreen, size: 18),
                        if (lang == _selectedLanguage)
                          const SizedBox(width: 8),
                        Text(lang),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.translate, color: Colors.white.withValues(alpha: 0.9), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Speaking in: $_selectedLanguage',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _chatHistory.length,
      itemBuilder: (context, index) {
        final chat = _chatHistory[index];
        final isBot = chat['type'] == 'bot';
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBot) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isBot ? Colors.white : AppColors.primaryGreen,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isBot ? 4 : 16),
                          bottomRight: Radius.circular(isBot ? 16 : 4),
                        ),
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
                          Text(
                            chat['message'],
                            style: TextStyle(
                              color: isBot ? AppColors.charcoal : Colors.white,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          if (chat['translation'] != null && chat['translation'].isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isBot 
                                    ? AppColors.lightGrey
                                    : Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.translate,
                                    size: 12,
                                    color: isBot ? AppColors.darkGrey : Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      chat['translation'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isBot ? AppColors.darkGrey : Colors.white70,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            chat['time'],
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.darkGrey,
                            ),
                          ),
                          if (isBot) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {},
                              child: Icon(
                                Icons.volume_up,
                                size: 14,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isBot) ...[
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.oceanTeal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 22),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: index * 100)).slideX(
          begin: isBot ? -0.2 : 0.2,
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.flash_on, color: AppColors.sunYellow, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Quick Questions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickActions.length,
              itemBuilder: (context, index) {
                final action = _quickActions[index];
                return GestureDetector(
                  onTap: () => _processVoiceInput(action['query']),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          action['icon'] as IconData,
                          size: 16,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          action['label'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isListening) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ).animate(
                    onPlay: (controller) => controller.repeat(),
                  ).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.5, 1.5),
                    duration: const Duration(milliseconds: 500),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Listening... Speak now',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type your question...',
                      hintStyle: TextStyle(color: AppColors.mediumGrey),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: Icon(Icons.camera_alt, color: AppColors.primaryGreen),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _toggleListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _isListening
                        ? LinearGradient(
                            colors: [AppColors.error, AppColors.harvestOrange],
                          )
                        : AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? AppColors.error : AppColors.primaryGreen)
                            .withValues(alpha: 0.3),
                        blurRadius: _isListening ? 20 : 10,
                        spreadRadius: _isListening ? 5 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 28,
                  ),
                ).animate(
                  target: _isListening ? 1 : 0,
                ).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.keyboard, size: 14, color: AppColors.darkGrey),
              const SizedBox(width: 4),
              Text(
                'Type or tap mic to speak',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.darkGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
