import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi/config/api_config.dart';
import 'package:absensi/services/auth_service.dart';

class AbsensiResult {
  final bool success;
  final String message;

  const AbsensiResult({required this.success, required this.message});
}

class AbsensiStatus {
  final String? jamMasuk;
  final String? jamPulang;
  final bool bisaClock;
  final String? clockBerikutnya;
  final int cooldownSisaMenit;

  const AbsensiStatus({
    required this.jamMasuk,
    required this.jamPulang,
    required this.bisaClock,
    required this.clockBerikutnya,
    required this.cooldownSisaMenit,
  });

  factory AbsensiStatus.fromJson(Map<String, dynamic> json) {
    return AbsensiStatus(
      jamMasuk: json['jam_masuk'] as String?,
      jamPulang: json['jam_pulang'] as String?,
      bisaClock: json['bisa_clock'] as bool? ?? true,
      clockBerikutnya: json['clock_berikutnya'] as String?,
      cooldownSisaMenit: (json['cooldown_sisa_menit'] as num?)?.toInt() ?? 0,
    );
  }
}

class AbsensiStatusResult {
  final bool success;
  final String message;
  final AbsensiStatus? data;

  const AbsensiStatusResult({
    required this.success,
    required this.message,
    this.data,
  });
}

class AbsensiHistoryLog {
  final String jenis;
  final String? jam;
  final String? source;
  final String? keterangan;

  const AbsensiHistoryLog({
    required this.jenis,
    required this.jam,
    required this.source,
    required this.keterangan,
  });

  factory AbsensiHistoryLog.fromJson(Map<String, dynamic> json) {
    return AbsensiHistoryLog(
      jenis: (json['jenis'] ?? '').toString(),
      jam: json['jam'] as String?,
      source: json['source'] as String?,
      keterangan: json['keterangan'] as String?,
    );
  }
}

class AbsensiHistoryDay {
  final int? id;
  final String tanggal;
  final String status;
  final String? jamMasuk;
  final String? jamPulang;
  final List<AbsensiHistoryLog> logs;

  const AbsensiHistoryDay({
    required this.id,
    required this.tanggal,
    required this.status,
    required this.jamMasuk,
    required this.jamPulang,
    required this.logs,
  });

  factory AbsensiHistoryDay.fromJson(Map<String, dynamic> json) {
    final logsRaw = json['logs'];
    final parsedLogs = <AbsensiHistoryLog>[];
    if (logsRaw is List) {
      for (final item in logsRaw) {
        if (item is Map) {
          parsedLogs.add(
            AbsensiHistoryLog.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return AbsensiHistoryDay(
      id: (json['id'] as num?)?.toInt(),
      tanggal: (json['tanggal'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      jamMasuk: json['jam_masuk'] as String?,
      jamPulang: json['jam_pulang'] as String?,
      logs: parsedLogs,
    );
  }
}

class AbsensiHistoryResult {
  final bool success;
  final String message;
  final List<AbsensiHistoryDay> data;
  final bool fromCache;
  final DateTime? fetchedAt;

  const AbsensiHistoryResult({
    required this.success,
    required this.message,
    required this.data,
    required this.fromCache,
    this.fetchedAt,
  });
}

class _HistoryCacheData {
  final List<AbsensiHistoryDay> data;
  final DateTime cachedAt;

  const _HistoryCacheData({required this.data, required this.cachedAt});
}

class AbsensiService {
  static const Duration _historyCacheTtl = Duration(minutes: 15);
  final _authService = AuthService();

  Future<AbsensiResult> submitAbsen({
    required double lat,
    required double lng,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      return const AbsensiResult(
        success: false,
        message: 'Tidak ada sesi aktif, harap login kembali.',
      );
    }

    try {
      final response = await _postWithFallback(
        '/absensi/clock',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'lat': lat, 'lng': lng}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _invalidateHistoryCache();
        return AbsensiResult(
          success: true,
          message: data['message'] ?? 'Berhasil absen',
        );
      }

      return AbsensiResult(
        success: false,
        message: data['message'] ?? 'Gagal melakukan absen',
      );
    } catch (_) {
      return const AbsensiResult(
        success: false,
        message: 'Tidak dapat terhubung ke server',
      );
    }
  }

  Future<AbsensiStatusResult> getTodayStatus() async {
    final token = await _authService.getToken();
    if (token == null) {
      return const AbsensiStatusResult(
        success: false,
        message: 'Tidak ada sesi aktif, harap login kembali.',
      );
    }

    try {
      final response = await _getWithFallback(
        '/absensi/status',
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final payload = data['data'] as Map<String, dynamic>?;
        if (payload == null) {
          return const AbsensiStatusResult(
            success: false,
            message: 'Format data status absensi tidak valid.',
          );
        }

        return AbsensiStatusResult(
          success: true,
          message: data['message'] ?? 'Status absensi hari ini',
          data: AbsensiStatus.fromJson(payload),
        );
      }

      return AbsensiStatusResult(
        success: false,
        message: data['message'] ?? 'Gagal mengambil status absensi',
      );
    } catch (_) {
      return const AbsensiStatusResult(
        success: false,
        message: 'Tidak dapat terhubung ke server',
      );
    }
  }

  Future<AbsensiHistoryResult> getHistory({
    int perPage = 60,
    bool forceRefresh = false,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      return const AbsensiHistoryResult(
        success: false,
        message: 'Tidak ada sesi aktif, harap login kembali.',
        data: [],
        fromCache: false,
      );
    }

    final cacheKey = await _historyCacheKey(perPage);
    final cache = await _readHistoryCache(cacheKey);
    final isCacheFresh =
        cache != null &&
        DateTime.now().difference(cache.cachedAt) <= _historyCacheTtl;

    if (!forceRefresh && cache != null && isCacheFresh) {
      return AbsensiHistoryResult(
        success: true,
        message: 'Riwayat absensi (cache lokal)',
        data: cache.data,
        fromCache: true,
        fetchedAt: cache.cachedAt,
      );
    }

    try {
      final response = await _getWithFallback(
        '/absensi/history?per_page=$perPage',
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body);
      final message = (body['message'] ?? 'Riwayat absensi').toString();
      final payload = body['data'];

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _parseHistoryList(payload);
        final now = DateTime.now();
        await _writeHistoryCache(cacheKey, payload, now);

        return AbsensiHistoryResult(
          success: true,
          message: message,
          data: data,
          fromCache: false,
          fetchedAt: now,
        );
      }

      if (cache != null) {
        return AbsensiHistoryResult(
          success: true,
          message: '$message Menampilkan cache lokal.',
          data: cache.data,
          fromCache: true,
          fetchedAt: cache.cachedAt,
        );
      }

      return AbsensiHistoryResult(
        success: false,
        message: message,
        data: const [],
        fromCache: false,
      );
    } catch (_) {
      if (cache != null) {
        return AbsensiHistoryResult(
          success: true,
          message: 'Gagal sinkron ke server, menampilkan cache lokal.',
          data: cache.data,
          fromCache: true,
          fetchedAt: cache.cachedAt,
        );
      }

      return const AbsensiHistoryResult(
        success: false,
        message: 'Tidak dapat terhubung ke server',
        data: [],
        fromCache: false,
      );
    }
  }

  List<AbsensiHistoryDay> _parseHistoryList(dynamic rawList) {
    if (rawList is! List) return const [];

    final parsed = <AbsensiHistoryDay>[];
    for (final item in rawList) {
      if (item is Map) {
        parsed.add(AbsensiHistoryDay.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return parsed;
  }

  Future<String> _historyCacheKey(int perPage) async {
    final user = await _authService.getUser();
    final userId = (user?['id'] ?? user?['username'] ?? 'unknown').toString();
    return 'absensi_history_${userId}_$perPage';
  }

  Future<_HistoryCacheData?> _readHistoryCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    final cachedAtMillis = prefs.getInt('${key}_cached_at');
    if (raw == null || cachedAtMillis == null) return null;

    try {
      final decoded = jsonDecode(raw);
      final data = _parseHistoryList(decoded);
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMillis);
      return _HistoryCacheData(data: data, cachedAt: cachedAt);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeHistoryCache(
    String key,
    dynamic rawList,
    DateTime cachedAt,
  ) async {
    if (rawList is! List) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(rawList));
    await prefs.setInt('${key}_cached_at', cachedAt.millisecondsSinceEpoch);
  }

  Future<void> _invalidateHistoryCache() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await _authService.getUser();
    final userId = (user?['id'] ?? user?['username'] ?? 'unknown').toString();
    final prefix = 'absensi_history_${userId}_';

    final keysToDelete =
        prefs.getKeys().where((key) => key.startsWith(prefix)).toList();
    for (final key in keysToDelete) {
      await prefs.remove(key);
    }
  }

  Future<http.Response> _postWithFallback(
    String endpoint, {
    required Map<String, String> headers,
    Object? body,
  }) async {
    Object? lastError;

    for (final baseUrl in ApiConfig.fallbackBaseUrls) {
      try {
        return await http
            .post(Uri.parse('$baseUrl$endpoint'), headers: headers, body: body)
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('Gagal terhubung ke API');
  }

  Future<http.Response> _getWithFallback(
    String endpoint, {
    required Map<String, String> headers,
  }) async {
    Object? lastError;

    for (final baseUrl in ApiConfig.fallbackBaseUrls) {
      try {
        return await http
            .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('Gagal terhubung ke API');
  }
}
