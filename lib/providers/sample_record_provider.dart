import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../config/api_config.dart';
import '../services/storage_service.dart';
import '../services/crashlytics_service.dart';
import '../services/performance_service.dart';
import '../services/analytics_service.dart';

enum SampleRecordStatus {
  idle,
  readyToCapture,
  processingImage,
  uploading,
  training,
  success,
  error,
  unauthorized,
}

class SampleRecordProvider extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;

  SampleRecordStatus _status = SampleRecordStatus.idle;
  String _message = '';

  final int _targetSamples = 10;
  bool _isWfa = false;

  int _currentPhotoIndex = 1;
  int _successUploads = 0;

  SampleRecordStatus get status => _status;
  String get message => _message;
  int get currentPhotoIndex => _currentPhotoIndex;
  int get totalSamples => _targetSamples;
  int get successUploads => _successUploads;

  void init(bool isWfa) {
    _isWfa = isWfa;
    reset();
  }

  void reset() {
    _status = SampleRecordStatus.idle;
    _message = '';
    _currentPhotoIndex = 1;
    _successUploads = 0;
    notifyListeners();
  }

  void retryCapture() {
    _status = SampleRecordStatus.readyToCapture;
    _updateMessage("Rekam Data Ke-$_currentPhotoIndex Dari $_targetSamples");
    notifyListeners();
  }

  Future<void> startRecording() async {
    reset();
    _status = SampleRecordStatus.readyToCapture;
    _updateMessage("Rekam Data Ke-$_currentPhotoIndex Dari $_targetSamples");
    AnalyticsService().logEvent(
      name: 'start_face_recording',
      parameters: {'mode': _isWfa ? 'wfa' : 'wfo'},
    );
    notifyListeners();
  }

  Future<void> processImage(XFile xFile) async {
    _status = SampleRecordStatus.processingImage;
    notifyListeners();

    File? processedFile;

    try {
      debugPrint(
        '=== PROCESS IMAGE START [$_currentPhotoIndex/$_targetSamples] ===',
      );

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
      final fileName = 'sample_${DateTime.now().millisecondsSinceEpoch}_P.jpg';
      final targetPath = path.join(tempDir.path, fileName);
      processedFile = File(targetPath);
      await processedFile.writeAsBytes(encodedBytes);

      debugPrint('=== PROCESS IMAGE COMPLETE. Starting upload... ===');

      await _uploadSingleImage(processedFile);
    } catch (e, stack) {
      debugPrint('=== PROCESS IMAGE ERROR: $e ===');
      CrashlyticsService().recordError(
        e,
        stack,
        reason: 'Image Processing Error',
      );
      _status = SampleRecordStatus.error;
      _updateMessage("Gagal memproses gambar: $e");
      notifyListeners();
    }
  }

  Future<void> _uploadSingleImage(File imageFile) async {
    _status = SampleRecordStatus.uploading;
    _updateMessage("Mengirim Data Ke-$_currentPhotoIndex Dari $_targetSamples");
    notifyListeners();

    final trace = PerformanceService().startTrace('upload_single_image');
    trace.putAttribute('index', '$_currentPhotoIndex');

    final token = _storage.token;
    final sampleId = _storage.sampleId;

    final endpoint = _isWfa
        ? ApiEndpoints.uploadFotoGlobal
        : ApiEndpoints.uploadFoto;
    final url = Uri.parse(
      '${ApiConfig.baseUrl}$endpoint'
      '?token=$token&sample_id=$sampleId&index=$_currentPhotoIndex&orientasi=P',
    );

    try {
      final bytes = await imageFile.readAsBytes();

      debugPrint(
        '=== UPLOAD REQUEST [$_currentPhotoIndex/$_targetSamples] ===',
      );
      debugPrint('Method: POST');
      debugPrint('URL: $url');
      debugPrint(
        'Headers: {Content-Type: image/jpeg, X-API-TOKEN: ${token?.substring(0, 8)}...}',
      );
      debugPrint('Body: ${bytes.length} bytes (image/jpeg)');

      final response = await http
          .post(
            url,
            body: bytes,
            headers: {'Content-Type': 'image/jpeg', 'X-API-TOKEN': token ?? ''},
          )
          .timeout(ApiConfig.defaultTimeout);

      debugPrint(
        '[UPLOAD] Status: ${response.statusCode}, Body: ${response.body}',
      );
      debugPrint('=== UPLOAD RESPONSE END ===');

      trace.putAttribute('status_code', '${response.statusCode}');

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body == "OK") {
          debugPrint('[UPLOAD] Success: Foto lolos validasi');
          await PerformanceService().stopTrace(trace);

          _successUploads++;

          if (_currentPhotoIndex >= _targetSamples) {
            debugPrint('=== ALL PHOTOS UPLOADED. Starting training... ===');
            await _startTrainingProcess();
          } else {
            _currentPhotoIndex++;
            _status = SampleRecordStatus.readyToCapture;
            _updateMessage(
              "Rekam Data Ke-$_currentPhotoIndex Dari $_targetSamples",
            );
            debugPrint(
              '=== Ready for next capture [$_currentPhotoIndex/$_targetSamples] ===',
            );
          }
          notifyListeners();
        } else {
          final nextIndex = int.tryParse(body);
          if (nextIndex != null) {
            debugPrint(
              '[UPLOAD] Failed: Foto tidak lolos validasi. Next index: $nextIndex',
            );
            _currentPhotoIndex = nextIndex;
            _status = SampleRecordStatus.readyToCapture;
            _updateMessage(
              "Rekam Data Ke-$_currentPhotoIndex Dari $_targetSamples",
            );
          } else {
            debugPrint('[UPLOAD] Failed: Unknown response: $body');
            _status = SampleRecordStatus.error;
            _updateMessage("Respons tidak dikenal. Coba lagi.");
          }
          notifyListeners();
          await PerformanceService().stopTrace(trace);
        }
      } else if (response.statusCode == 401) {
        if (response.body.contains("NO_LOGIN")) {
          _status = SampleRecordStatus.unauthorized;
          _updateMessage("Sesi Habis. Login Ulang.");
          notifyListeners();
          await PerformanceService().stopTrace(trace);
        } else {
          _handleUploadError(response, trace);
        }
      } else {
        _handleUploadError(response, trace);
      }
    } catch (e, stack) {
      debugPrint('=== UPLOAD ERROR: $e ===');
      CrashlyticsService().recordError(
        e,
        stack,
        reason: 'Upload Connection Error',
      );
      _status = SampleRecordStatus.error;
      _updateMessage("Koneksi terganggu. Coba lagi.");
      notifyListeners();
      await PerformanceService().stopTrace(trace);
    }
  }

  void _handleUploadError(http.Response response, dynamic trace) {
    CrashlyticsService().recordError(
      "Upload Failed: ${response.statusCode} ${response.body}",
      StackTrace.current,
      reason: 'Backend Error',
    );
    _status = SampleRecordStatus.error;
    _updateMessage("Gagal mengirim foto. Coba lagi.");
    notifyListeners();
    PerformanceService().stopTrace(trace);
  }

  Future<void> _startTrainingProcess() async {
    _status = SampleRecordStatus.training;
    _updateMessage("Memproses Data...");
    notifyListeners();

    final trace = PerformanceService().startTrace('face_training');

    final token = _storage.token;
    final sampleId = _storage.sampleId;
    final endpoint = _isWfa
        ? ApiEndpoints.processTrainGlobal
        : ApiEndpoints.processTrain;
    final url = Uri.parse(
      '${ApiConfig.baseUrl}$endpoint?token=$token&sample_id=$sampleId',
    );

    try {
      debugPrint('=== TRAIN REQUEST ===');
      debugPrint('Method: POST');
      debugPrint('URL: $url');
      debugPrint('Headers: {X-API-TOKEN: ${token?.substring(0, 8)}...}');

      final response = await http
          .post(url, headers: {'X-API-TOKEN': token ?? ''})
          .timeout(ApiConfig.defaultTimeout);

      debugPrint(
        '[TRAIN] Status: ${response.statusCode}, Body: ${response.body}',
      );
      debugPrint('=== TRAIN RESPONSE END ===');

      trace.putAttribute('status_code', '${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.body.trim() == "OK") {
          _status = SampleRecordStatus.success;
          _updateMessage(
            "Anda telah merekam\nData Sampel Wajah\n\nData Sampel Presensi Wajah sudah dikirim dan diproses. Silakan login kembali untuk mengisi presensi Anda. Terima Kasih.",
          );
          AnalyticsService().logEvent(
            name: 'face_training_completed',
            parameters: {'success_uploads': _successUploads},
          );
        } else {
          _status = SampleRecordStatus.error;
          _updateMessage("Gagal memproses data: ${response.body}");
          CrashlyticsService().recordError(
            "Train 200 not OK: ${response.body}",
            StackTrace.current,
          );
          AnalyticsService().logEvent(
            name: 'face_training_failed',
            parameters: {'reason': response.body},
          );
        }
      } else if (response.statusCode == 401) {
        if (response.body.contains("NO_LOGIN")) {
          _status = SampleRecordStatus.unauthorized;
          _updateMessage("Sesi Habis. Login Ulang.");
        } else {
          _handleTrainError(response);
        }
      } else {
        _handleTrainError(response);
      }
    } catch (e, stack) {
      _status = SampleRecordStatus.error;
      _updateMessage("Koneksi server terganggu.");
      CrashlyticsService().recordError(
        e,
        stack,
        reason: 'Training Connection Error',
      );
    } finally {
      await PerformanceService().stopTrace(trace);
    }
    notifyListeners();
  }

  void _handleTrainError(http.Response response) {
    _status = SampleRecordStatus.error;
    _updateMessage("Koneksi server terganggu.");
    CrashlyticsService().recordError(
      "Train Failed: ${response.statusCode} ${response.body}",
      StackTrace.current,
    );
  }

  void _updateMessage(String msg) {
    _message = msg;
  }
}
