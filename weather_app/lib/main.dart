import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const WeatherApp());

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.lightBlue),
      darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.lightBlue,
          brightness: Brightness.dark),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});
  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  late Future<WeatherBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<String> _resolvePlaceName(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      final p = placemarks.first;
      return p.locality?.isNotEmpty == true
          ? p.locality!
          : (p.subAdministrativeArea ?? 'Vị trí của bạn');
    } catch (_) {
      return 'Vị trí của bạn';
    }
  }

  Future<WeatherBundle> _load() async {
    double latitude = 16.0544;
    double longitude = 108.2022;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {

          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 10),
          );

          latitude = pos.latitude;
          longitude = pos.longitude;
        } else {
          debugPrint('Quyền vị trí bị từ chối. Dùng vị trí mặc định.');
        }
      } else {
        debugPrint('Dịch vụ vị trí đang tắt. Dùng vị trí mặc định.');
      }
    } catch (e) {
      debugPrint('Lỗi khi lấy vị trí: $e. Dùng vị trí mặc định.');
    }
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
          '?latitude=$latitude&longitude=$longitude'
          '&current=temperature_2m,relative_humidity_2m,apparent_temperature,wind_speed_10m'
          '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum'
          '&timezone=auto',
    );
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    }
    final Map<String, dynamic> j = jsonDecode(res.body);
    final bundle = WeatherBundle.fromJson(j);

    final placeName = await _resolvePlaceName(bundle.latitude, bundle.longitude);

    return bundle.copyWith(placeName: placeName);

  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thời tiết'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<WeatherBundle>(
          future: _future,
          builder: (context, s) {
            if (s.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (s.hasError) {
              return _ErrorView(error: s.error.toString(), onRetry: _reload);
            }
            final data = s.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _CurrentWeatherView(data: data),
                const SizedBox(height: 20),
                _DailyForecastCard(data: data),
                const SizedBox(height: 8),
                Text(
                  'Lat: ${data.latitude.toStringAsFixed(4)}, '
                      'Lon: ${data.longitude.toStringAsFixed(4)}',
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class WeatherBundle {
  final double latitude;
  final double longitude;
  final String timezone;
  final String? placeName;
  final CurrentWeather current;
  final List<DailyWeather> daily;

  WeatherBundle({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.placeName,
    required this.current,
    required this.daily,
  });

  WeatherBundle copyWith({String? placeName}) {
    return WeatherBundle(
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      current: current,
      daily: daily,
      placeName: placeName ?? this.placeName,
    );
  }


  factory WeatherBundle.fromJson(Map<String, dynamic> j) {
    final c = j['current'] as Map<String, dynamic>;
    final d = j['daily'] as Map<String, dynamic>;
    final List days = (d['time'] as List);
    final List<DailyWeather> daily = List.generate(days.length, (i) {
      return DailyWeather(
        date: DateTime.parse(d['time'][i]),
        tMax: (d['temperature_2m_max'][i] as num).toDouble(),
        tMin: (d['temperature_2m_min'][i] as num).toDouble(),
        precipSum: (d['precipitation_sum'][i] as num).toDouble(),
      );
    });

    return WeatherBundle(
      latitude: (j['latitude'] as num).toDouble(),
      longitude: (j['longitude'] as num).toDouble(),
      timezone: j['timezone'] as String,
      current: CurrentWeather(
        temperature: (c['temperature_2m'] as num).toDouble(),
        humidity: (c['relative_humidity_2m'] as num).toDouble(),
        apparentTemperature: (c['apparent_temperature'] as num).toDouble(),
        windSpeed: (c['wind_speed_10m'] as num).toDouble(),
        time: DateTime.parse(c['time'] as String),
      ),
      daily: daily,
    );
  }
}

// Le Cam Binh

class CurrentWeather {
  final double temperature;
  final double humidity;
  final double apparentTemperature;
  final double windSpeed;
  final DateTime time;

  CurrentWeather({
    required this.temperature,
    required this.humidity,
    required this.apparentTemperature,
    required this.windSpeed,
    required this.time,
  });
}

class DailyWeather {
  final DateTime date;
  final double tMax;
  final double tMin;
  final double precipSum;
  DailyWeather({
    required this.date,
    required this.tMax,
    required this.tMin,
    required this.precipSum,
  });
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 12),
            Text('Không tải được dữ liệu',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _CurrentWeatherView extends StatelessWidget {
  const _CurrentWeatherView({required this.data});
  final WeatherBundle data;

  @override
  Widget build(BuildContext context) {
    final c = data.current;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          data.placeName ?? 'Vị trí của bạn',
          style: textTheme.headlineSmall?.copyWith(color: color),
        ),
        const SizedBox(height: 8),
        Icon(_getWeatherIconForCurrent(c),
            size: 100, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          '${c.temperature.toStringAsFixed(1)}°C',
          style: textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'Cảm giác: ${c.apparentTemperature.toStringAsFixed(1)}°C',
          style: textTheme.titleMedium?.copyWith(color: color.withOpacity(0.8)),
        ),
        const SizedBox(height: 24),
        IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DetailItem(
                icon: Icons.water_drop_outlined,
                value: '${c.humidity.toStringAsFixed(0)}%',
                label: 'Độ ẩm',
              ),
              const VerticalDivider(width: 32, thickness: 1, indent: 4, endIndent: 4),
              _DetailItem(
                icon: Icons.air_outlined,
                value: '${c.windSpeed.toStringAsFixed(0)} km/h',
                label: 'Gió',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cập nhật: ${_fmtTime(c.time)}',
          style: textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(color: color.withOpacity(0.8)),
        ),
      ],
    );
  }
}

class _DailyForecastCard extends StatelessWidget {
  const _DailyForecastCard({required this.data});
  final WeatherBundle data;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.calendar_today_outlined),
            title: Text('Dự báo 7 ngày'),
          ),
          const Divider(height: 1),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: data.daily.length,
            separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, i) {
              final d = data.daily[i];
              return ListTile(
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(_getWeatherIconForDaily(d),
                      color: Theme.of(context).colorScheme.primary),
                ),
                title: Text(_fmtDate(d.date, i)),
                subtitle: Text('Mưa: ${d.precipSum.toStringAsFixed(1)} mm'),
                trailing: Text(
                  '${d.tMax.toStringAsFixed(0)}° / ${d.tMin.toStringAsFixed(0)}°',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Le Cam Binh

String _fmtTime(DateTime t) {
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

String _fmtDate(DateTime d, int index) {
  if (index == 0) return 'Hôm nay';
  if (index == 1) return 'Ngày mai';

  const days = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '${days[d.weekday - 1]}, $dd/$mm';
}

IconData _getWeatherIconForCurrent(CurrentWeather c) {
  if (c.temperature > 30) return Icons.wb_sunny_outlined;
  if (c.humidity > 80) return Icons.umbrella_outlined;
  return Icons.thermostat_outlined;
}

IconData _getWeatherIconForDaily(DailyWeather d) {
  if (d.precipSum > 5) return Icons.umbrella_outlined;
  if (d.precipSum > 0.5) return Icons.water_drop_outlined;
  if (d.tMax > 32) return Icons.wb_sunny_outlined;
  if (d.tMin < 15) return Icons.ac_unit_outlined;
  return Icons.cloud_outlined;
}