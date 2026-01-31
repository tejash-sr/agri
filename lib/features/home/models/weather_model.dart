class WeatherData {
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String condition;
  final String icon;
  final double feelsLike;
  final int uvIndex;
  final int precipitation;
  final double visibility;
  final int pressure;
  final String sunrise;
  final String sunset;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.icon,
    required this.feelsLike,
    required this.uvIndex,
    required this.precipitation,
    required this.visibility,
    required this.pressure,
    required this.sunrise,
    required this.sunset,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['temperature'] ?? 0).toDouble(),
      humidity: json['humidity'] ?? 0,
      windSpeed: (json['windSpeed'] ?? 0).toDouble(),
      condition: json['condition'] ?? 'Unknown',
      icon: json['icon'] ?? 'unknown',
      feelsLike: (json['feelsLike'] ?? 0).toDouble(),
      uvIndex: json['uvIndex'] ?? 0,
      precipitation: json['precipitation'] ?? 0,
      visibility: (json['visibility'] ?? 0).toDouble(),
      pressure: json['pressure'] ?? 0,
      sunrise: json['sunrise'] ?? '',
      sunset: json['sunset'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'condition': condition,
      'icon': icon,
      'feelsLike': feelsLike,
      'uvIndex': uvIndex,
      'precipitation': precipitation,
      'visibility': visibility,
      'pressure': pressure,
      'sunrise': sunrise,
      'sunset': sunset,
    };
  }
}

class WeatherForecast {
  final String day;
  final double high;
  final double low;
  final String condition;
  final String icon;
  final int rainChance;

  WeatherForecast({
    required this.day,
    required this.high,
    required this.low,
    required this.condition,
    required this.icon,
    required this.rainChance,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      day: json['day'] ?? '',
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      condition: json['condition'] ?? 'Unknown',
      icon: json['icon'] ?? 'unknown',
      rainChance: json['rainChance'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'high': high,
      'low': low,
      'condition': condition,
      'icon': icon,
      'rainChance': rainChance,
    };
  }
}

class WeatherAlert {
  final String id;
  final String title;
  final String description;
  final String severity;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> affectedCrops;
  final List<String> recommendations;

  WeatherAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.startTime,
    required this.endTime,
    required this.affectedCrops,
    required this.recommendations,
  });
}
