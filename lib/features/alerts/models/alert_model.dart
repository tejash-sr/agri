enum AlertType {
  weather,
  disease,
  price,
  irrigation,
  harvest,
  payment,
  marketplace,
  system,
  government,
}

enum AlertSeverity {
  info,
  warning,
  high,
  critical,
}

class FarmAlert {
  final String id;
  final AlertType type;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isRead;
  final bool actionRequired;
  final String? actionUrl;
  final String? actionText;
  final Map<String, dynamic>? metadata;

  FarmAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    required this.isRead,
    required this.actionRequired,
    this.actionUrl,
    this.actionText,
    this.metadata,
  });

  factory FarmAlert.fromJson(Map<String, dynamic> json) {
    return FarmAlert(
      id: json['id'] ?? '',
      type: AlertType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AlertType.system,
      ),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.info,
      ),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      actionRequired: json['actionRequired'] ?? false,
      actionUrl: json['actionUrl'],
      actionText: json['actionText'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'actionRequired': actionRequired,
      'actionUrl': actionUrl,
      'actionText': actionText,
      'metadata': metadata,
    };
  }

  FarmAlert copyWith({
    String? id,
    AlertType? type,
    String? title,
    String? message,
    AlertSeverity? severity,
    DateTime? timestamp,
    bool? isRead,
    bool? actionRequired,
    String? actionUrl,
    String? actionText,
    Map<String, dynamic>? metadata,
  }) {
    return FarmAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionRequired: actionRequired ?? this.actionRequired,
      actionUrl: actionUrl ?? this.actionUrl,
      actionText: actionText ?? this.actionText,
      metadata: metadata ?? this.metadata,
    );
  }

  String get typeText {
    switch (type) {
      case AlertType.weather:
        return 'Weather Alert';
      case AlertType.disease:
        return 'Disease Alert';
      case AlertType.price:
        return 'Price Alert';
      case AlertType.irrigation:
        return 'Irrigation';
      case AlertType.harvest:
        return 'Harvest';
      case AlertType.payment:
        return 'Payment';
      case AlertType.marketplace:
        return 'Marketplace';
      case AlertType.system:
        return 'System';
      case AlertType.government:
        return 'Government';
    }
  }

  int get typeIconCode {
    switch (type) {
      case AlertType.weather:
        return 0xE0BF; // Icons.cloud
      case AlertType.disease:
        return 0xE3FC; // Icons.bug_report
      case AlertType.price:
        return 0xE8A4; // Icons.trending_up
      case AlertType.irrigation:
        return 0xE42D; // Icons.water_drop
      case AlertType.harvest:
        return 0xE872; // Icons.agriculture
      case AlertType.payment:
        return 0xE8A1; // Icons.payment
      case AlertType.marketplace:
        return 0xE8CC; // Icons.store
      case AlertType.system:
        return 0xE8B8; // Icons.settings
      case AlertType.government:
        return 0xE064; // Icons.account_balance
    }
  }

  int get typeColor {
    switch (type) {
      case AlertType.weather:
        return 0xFF0288D1;
      case AlertType.disease:
        return 0xFFE53935;
      case AlertType.price:
        return 0xFF4CAF50;
      case AlertType.irrigation:
        return 0xFF00BCD4;
      case AlertType.harvest:
        return 0xFFFF9800;
      case AlertType.payment:
        return 0xFF9C27B0;
      case AlertType.marketplace:
        return 0xFF795548;
      case AlertType.system:
        return 0xFF607D8B;
      case AlertType.government:
        return 0xFF3F51B5;
    }
  }

  int get severityColor {
    switch (severity) {
      case AlertSeverity.info:
        return 0xFF2196F3;
      case AlertSeverity.warning:
        return 0xFFFFC107;
      case AlertSeverity.high:
        return 0xFFFF9800;
      case AlertSeverity.critical:
        return 0xFFE53935;
    }
  }

  String get severityText {
    switch (severity) {
      case AlertSeverity.info:
        return 'Info';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.high:
        return 'High Priority';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class NotificationPreferences {
  final bool weatherAlerts;
  final bool diseaseAlerts;
  final bool priceAlerts;
  final bool irrigationReminders;
  final bool harvestReminders;
  final bool marketplaceNotifications;
  final bool paymentNotifications;
  final bool governmentSchemes;
  final bool pushNotifications;
  final bool smsNotifications;
  final bool emailNotifications;
  final bool whatsappNotifications;
  final String quietHoursStart;
  final String quietHoursEnd;

  NotificationPreferences({
    this.weatherAlerts = true,
    this.diseaseAlerts = true,
    this.priceAlerts = true,
    this.irrigationReminders = true,
    this.harvestReminders = true,
    this.marketplaceNotifications = true,
    this.paymentNotifications = true,
    this.governmentSchemes = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
    this.emailNotifications = true,
    this.whatsappNotifications = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '06:00',
  });
}
