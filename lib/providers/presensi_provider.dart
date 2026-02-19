import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../services/storage_service.dart';
import '../services/crashlytics_service.dart';
import '../services/performance_service.dart';
import '../services/analytics_service.dart';
import '../providers/app_config_provider.dart';

enum PresensiStatus {
  idle,
  processing,
  success,
  failed,
  unauthorized,
  error,
  notWorkingDay,
}

class PresensiProvider extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;

  PresensiStatus _status = PresensiStatus.idle;
  String _statusMessage = '';
  String? _tglKerja;
  String? _ceklok;
  int _numTry = 0;
  static const int _maxTry = 5;

  PresensiStatus get status => _status;
  String get statusMessage => _statusMessage;
  String? get tglKerja => _tglKerja;
  String? get ceklok => _ceklok;
  int get numTry => _numTry;
  bool get isCeklokButtonVisible => _ceklok == '0';
  int get remainingTry => _maxTry - _numTry;

  void setData({String? ceklok, String? tglKerja}) {
    _ceklok = ceklok;
    _tglKerja = tglKerja;
    _updateStatusMessage();
    notifyListeners();
  }

  void _updateStatusMessage() {
    if (_ceklok == null) {
      _statusMessage = 'Maaf. Ada masalah koneksi Server.';
    } else if (_ceklok == '0') {
      _statusMessage = 'Anda belum ceklok hari ini.\nSilakan ceklok.';
    } else if (_ceklok == '1') {
      _statusMessage = 'Anda sudah ceklok hari ini.\nTerima Kasih.';
    } else if (_ceklok == '2') {
      _statusMessage = 'Maaf. Ini bukan hari kerja.';
    }
    _status = PresensiStatus.idle;
  }

  void resetTryCount() {
    _numTry = 0;
    notifyListeners();
  }

  Future<void> processFaceRecognition(File imageFile) async {
    _status = PresensiStatus.processing;
    _statusMessage = 'Memproses...';
    notifyListeners();

    final trace = PerformanceService().startTrace('face_recognition_presensi');

    final token = _storage.token;
    final userId = _storage.userId;
    final sampleId = _storage.sampleId;
    final isWfa = AppConfigProvider().isWfa;

    final endpoint = isWfa
        ? ApiEndpoints.recognizeGlobal
        : ApiEndpoints.recognizeGlobal;
    final url = Uri.parse(
      '${ApiConfig.baseUrl}$endpoint?token=$token&user_id=$userId&sample_id=$sampleId&orientasi=P',
    );

    try {
      final bytes = await imageFile.readAsBytes();

      debugPrint('=== PRESENSI FACE RECOGNITION REQUEST ===');
      debugPrint('Method: POST');
      debugPrint('URL: $url');
      debugPrint('Body: ${bytes.length} bytes (image/jpeg)');

      final response = await http
          .post(
            url,
            body: bytes,
            headers: {'Content-Type': 'image/jpeg', 'X-API-TOKEN': token ?? ''},
          )
          .timeout(ApiConfig.defaultTimeout);

      debugPrint(
        '[PRESENSI] Status: ${response.statusCode}, Body: ${response.body}',
      );
      debugPrint('=== PRESENSI RESPONSE END ===');

      trace.putAttribute('status_code', '${response.statusCode}');

      if (response.statusCode == 200) {
        final body = response.body.trim();

        if (body == 'OK') {
          await PerformanceService().stopTrace(trace);
          _status = PresensiStatus.success;
          _statusMessage = 'Pencocokan wajah Sukses.\nStatus Anda Hadir.';
          AnalyticsService().logEvent(
            name: 'presensi_success',
            parameters: {'num_try': _numTry + 1},
          );
        } else if (body.contains('ERROR: Failed to update presensi')) {
          await PerformanceService().stopTrace(trace);
          _status = PresensiStatus.error;
          _statusMessage = 'Koneksi Server Terganggu.';
        } else {
          _numTry++;
          if (_numTry >= _maxTry) {
            await PerformanceService().stopTrace(trace);
            _status = PresensiStatus.failed;
            _statusMessage =
                'Pencocokan wajah gagal.\nSilakan coba beberapa saat lagi.';
            AnalyticsService().logEvent(
              name: 'presensi_failed_max_retry',
              parameters: {'num_try': _numTry},
            );
          } else {
            await PerformanceService().stopTrace(trace);
            _status = PresensiStatus.failed;
            _statusMessage =
                'Pencocokan wajah gagal.\nCoba diulang lagi. [$_numTry / $_maxTry]';
            AnalyticsService().logEvent(
              name: 'presensi_retry',
              parameters: {'num_try': _numTry, 'remaining': _maxTry - _numTry},
            );
          }
        }
      } else if (response.statusCode == 401) {
        await PerformanceService().stopTrace(trace);
        if (response.body.contains('NO_LOGIN')) {
          _status = PresensiStatus.unauthorized;
          _statusMessage = 'Sesi habis. Login Ulang.';
        } else {
          _handleServerError(trace);
        }
      } else {
        _handleServerError(trace);
      }
    } catch (e, stack) {
      debugPrint('=== PRESENSI ERROR: $e ===');
      CrashlyticsService().recordError(
        e,
        stack,
        reason: 'Presensi Connection Error',
      );
      _status = PresensiStatus.error;
      _statusMessage = 'Koneksi Server Terganggu.';
      await PerformanceService().stopTrace(trace);
    }
    notifyListeners();
  }

  void _handleServerError(dynamic trace) {
    _status = PresensiStatus.error;
    _statusMessage = 'Koneksi Server Tergangguan.';
    CrashlyticsService().recordError(
      'Presensi Server Error',
      StackTrace.current,
      reason: 'Backend Error',
    );
    PerformanceService().stopTrace(trace);
  }

  Future<File?> preprocessImage(XFile xFile) async {
    try {
      debugPrint('=== PREPROCESS IMAGE FOR PRESENSI ===');

      debugPrint('[1/4] Reading original file: ${xFile.path}');
      final File file = File(xFile.path);
      final bytes = await file.readAsBytes();
      debugPrint('[1/4] Original file size: ${bytes.length} bytes');

      if (bytes.isEmpty) {
        throw Exception("File kosong");
      }

      debugPrint('[2/4] Decoding image...');
      final image = img.decodeImage(bytes);

      if (image == null) {
        debugPrint('[2/4] ERROR: Failed to decode image');
        throw Exception("Gagal decode gambar");
      }
      debugPrint('[2/4] Image decoded: ${image.width}x${image.height}');

      debugPrint('[3/4] Resizing image to 600x600...');
      final resized = img.copyResize(image, width: 600, height: 600);
      debugPrint('[3/4] Image resized: ${resized.width}x${resized.height}');

      debugPrint('[4/4] Encoding JPEG (quality: 85)...');
      final encodedBytes = img.encodeJpg(resized, quality: 85);
      debugPrint('[4/4] Encoded size: ${encodedBytes.length} bytes');

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'presensi_${DateTime.now().millisecondsSinceEpoch}_P.jpg';
      final targetPath = path.join(tempDir.path, fileName);
      final processedFile = File(targetPath);
      await processedFile.writeAsBytes(encodedBytes);

      debugPrint('=== PREPROCESS COMPLETE ===');
      return processedFile;
    } catch (e, stack) {
      debugPrint('=== PREPROCESS ERROR: $e ===');
      CrashlyticsService().recordError(
        e,
        stack,
        reason: 'Image Preprocessing Error',
      );
      return null;
    }
  }
}
