import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import '../../../core/theme/app_theme.dart';
import '../models/disease_model.dart';

class DiseaseScannerScreen extends StatefulWidget {
  const DiseaseScannerScreen({super.key});

  @override
  State<DiseaseScannerScreen> createState() => _DiseaseScannerScreenState();
}

class _DiseaseScannerScreenState extends State<DiseaseScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isScanning = false;
  DiseaseScanResult? _scanResult;
  String? _selectedImagePath;

  final List<Map<String, dynamic>> _sampleResults = [
    {
      'disease': 'Early Blight',
      'crop': 'Tomato',
      'severity': DiseaseSeverity.moderate,
      'confidence': 0.87,
      'description': 'Early blight is a common fungal disease causing dark spots with concentric rings on leaves. It typically starts on lower, older leaves.',
      'treatments': [
        'Apply copper-based fungicide immediately',
        'Remove and destroy affected leaves',
        'Improve air circulation around plants',
        'Apply neem oil spray as organic alternative',
      ],
      'prevention': [
        'Practice crop rotation (3-year cycle)',
        'Maintain proper plant spacing',
        'Water at base, avoid wetting leaves',
        'Use disease-resistant varieties',
      ],
    },
    {
      'disease': 'Healthy',
      'crop': 'Grape',
      'severity': DiseaseSeverity.healthy,
      'confidence': 0.95,
      'description': 'Your grape leaves appear healthy with no signs of disease. The leaves show good color and structure.',
      'treatments': [],
      'prevention': [
        'Continue regular monitoring',
        'Maintain proper spacing for airflow',
        'Keep irrigation consistent',
        'Apply preventive fungicide before monsoon',
      ],
    },
    {
      'disease': 'Powdery Mildew',
      'crop': 'Wheat',
      'severity': DiseaseSeverity.mild,
      'confidence': 0.82,
      'description': 'Powdery mildew appears as white powdery patches on leaves. Early detection allows for effective treatment.',
      'treatments': [
        'Apply sulfur-based fungicide',
        'Use potassium bicarbonate spray',
        'Remove heavily infected leaves',
        'Improve sunlight exposure',
      ],
      'prevention': [
        'Ensure proper plant spacing',
        'Avoid excess nitrogen fertilizer',
        'Choose resistant varieties',
        'Monitor during humid conditions',
      ],
    },
  ];

  Future<void> _captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _selectedImagePath = image.path);
        await _analyzeImage();
      }
    } catch (e) {
      _showDemoScan();
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _selectedImagePath = image.path);
        await _analyzeImage();
      }
    } catch (e) {
      _showDemoScan();
    }
  }

  void _showDemoScan() async {
    setState(() {
      _isScanning = true;
      _scanResult = null;
    });

    // Simulate AI processing
    await Future.delayed(const Duration(seconds: 2));

    // Get random demo result
    final randomResult = _sampleResults[Random().nextInt(_sampleResults.length)];

    setState(() {
      _isScanning = false;
      _scanResult = DiseaseScanResult(
        id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
        cropName: randomResult['crop'],
        imagePath: '',
        diseaseName: randomResult['disease'],
        confidence: randomResult['confidence'],
        severity: randomResult['severity'],
        description: randomResult['description'],
        treatments: List<String>.from(randomResult['treatments']),
        preventiveMeasures: List<String>.from(randomResult['prevention']),
        scannedAt: DateTime.now(),
      );
    });
  }

  Future<void> _analyzeImage() async {
    _showDemoScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.error,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'AI Disease Scanner',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFFF5722)],
                  ),
                ),
              ),
            ),
          ),
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Scanner Card
                _buildScannerCard(),
                const SizedBox(height: 20),
                
                // Scanning Animation
                if (_isScanning) ...[
                  _buildScanningAnimation(),
                  const SizedBox(height: 20),
                ],
                
                // Results
                if (_scanResult != null) ...[
                  _buildResultCard(),
                  const SizedBox(height: 16),
                  if (_scanResult!.treatments.isNotEmpty)
                    _buildTreatmentCard(),
                  const SizedBox(height: 16),
                  _buildPreventionCard(),
                ],
                
                // Tips Section
                if (_scanResult == null && !_isScanning)
                  _buildTipsSection(),
                
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_enhance,
              size: 60,
              color: AppColors.error,
            ),
          ).animate().scale(duration: const Duration(milliseconds: 600)),
          const SizedBox(height: 20),
          Text(
            'Scan Your Crop',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo of the affected leaf for instant AI-powered disease detection',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.darkGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _captureImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isScanning ? null : _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _isScanning ? null : _showDemoScan,
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Try Demo Scan'),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningAnimation() {
    return Container(
      padding: const EdgeInsets.all(40),
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
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
                ),
              ),
              Icon(
                Icons.eco,
                size: 40,
                color: AppColors.primaryGreen,
              ),
            ],
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: const Duration(seconds: 2)),
          const SizedBox(height: 24),
          Text(
            'Analyzing with AI...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our CNN model is detecting diseases',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _scanResult!;
    final isHealthy = result.severity == DiseaseSeverity.healthy;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(result.severityColor).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(result.severityColor).withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(result.severityColor).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isHealthy ? Icons.check_circle : Icons.warning,
                  color: Color(result.severityColor),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.diseaseName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Color(result.severityColor),
                      ),
                    ),
                    Text(
                      'Detected in ${result.cropName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Confidence Score
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Confidence',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: result.confidence,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(result.severityColor),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(result.severityColor).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(result.confidence * 100).toInt()}%',
                  style: TextStyle(
                    color: Color(result.severityColor),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Severity Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(result.severityColor).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.speed,
                  size: 16,
                  color: Color(result.severityColor),
                ),
                const SizedBox(width: 6),
                Text(
                  'Severity: ${result.severityText}',
                  style: TextStyle(
                    color: Color(result.severityColor),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            result.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildTreatmentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBgOrange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.harvestOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: AppColors.harvestOrange,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Recommended Treatment',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._scanResult!.treatments.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.harvestOrange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 200)).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPreventionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBgGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shield,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Preventive Measures',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._scanResult!.preventiveMeasures.map(
            (measure) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      measure,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 400)).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scanning Tips',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildTipItem(
          Icons.wb_sunny,
          'Good Lighting',
          'Take photos in natural daylight for best results',
          AppColors.sunYellow,
        ),
        _buildTipItem(
          Icons.center_focus_strong,
          'Focus on Affected Area',
          'Capture the diseased portion clearly',
          AppColors.error,
        ),
        _buildTipItem(
          Icons.photo_camera,
          'Multiple Angles',
          'Take photos from different angles for accuracy',
          AppColors.skyBlue,
        ),
        _buildTipItem(
          Icons.eco,
          'Include Healthy Parts',
          'Show both healthy and affected areas',
          AppColors.primaryGreen,
        ),
      ],
    );
  }

  Widget _buildTipItem(IconData icon, String title, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.darkGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
