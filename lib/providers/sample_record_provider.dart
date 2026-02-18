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

  // Configuration
  final int _targetSamples = 10;
  bool _isWfa = false;

  // State
  List<File> _imgList = [];
  int _currentPhotoIndex = 1; // 1-based index for display
  int _successUploads = 0;
  int _failedUploads = 0;

  // Getters
  SampleRecordStatus get status => _status;
  String get message => _message;
  int get currentPhotoIndex => _currentPhotoIndex;
  int get totalSamples => _targetSamples;
  int get successUploads => _successUploads;
  int get failedUploads => _failedUploads;

  void init(bool isWfa) {
    _isWfa = isWfa;
    reset();
  }

  void reset() {
    _status = SampleRecordStatus.idle;
    _message = '';
    _imgList = [];
    _currentPhotoIndex = 1;
    _successUploads = 0;
    _failedUploads = 0;
    notifyListeners();
  }

  Future<void> startRecording() async {
    reset();
    _status = SampleRecordStatus.readyToCapture;
    _updateMessage("Rekam Data Ke-$_currentPhotoIndex Dari $_targetSamples");
    notifyListeners();
  }

  Future<void> processImage(XFile xFile) async {
    _status = SampleRecordStatus.processingImage;
    notifyListeners();

    try {
      final File file = File(xFile.path);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception("Failed to decode image");
      }

      // Determine orientation
      String orientation = image.width > image.height ? "L" : "P";

      // Resize to 600x600
      final resized = img.copyResize(image, width: 600, height: 600);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'sample_${DateTime.now().millisecondsSinceEpoch}_$orientation.jpg'; // Encoded orientation in filename for simplicity or store separately
      final targetPath = path.join(tempDir.path, fileName);
      final targetFile = File(targetPath);

      await targetFile.writeAsBytes(img.encodeJpg(resized, quality: 85));

      _imgList.add(targetFile);

      if (_imgList.length < _targetSamples) {
        _currentPhotoIndex++;
        _status = SampleRecordStatus.readyToCapture;
        _updateMessage(
          "Rekam Data Ke-$_currentPhotoIndex Dari $_targetSamples",
        );
      } else {
        _startUploadProcess();
      }
    } catch (e, stack) {
      CrashlyticsService().recordError(
        e,
        stack,
        reason: 'Image Processing Error',
      );
      _status = SampleRecordStatus.error;
      _updateMessage("Gagal memproses gambar: $e");
    }
    notifyListeners();
  }

  Future<void> _startUploadProcess() async {
    _status = SampleRecordStatus.uploading;

    // We iterate
    for (int i = 0; i < _imgList.length; i++) {
      int displayNum = i + 1;
      _updateMessage("Kirim Data Ke-$displayNum Dari $_targetSamples");
      notifyListeners();

      bool success = await _uploadSingleImage(_imgList[i], i);
      if (success) {
        _successUploads++;
      } else {
        _failedUploads++;
        // Start immediate error check? User said: "Jika kode response mengembalikan 401..."
        // My _uploadSingleImage should handle that.
        if (_status == SampleRecordStatus.unauthorized) return;
      }
    }

    // Finished uploads
    if (_successUploads >= _targetSamples) {
      _startTrainingProcess();
    } else {
      // Some failed
      _status =
          SampleRecordStatus.error; // Or a specific 'partial_success' state?
      // User said: "Jika ada yang gagal; hitung errUpload... Tampilkan pesan Ada X data gagal simpan. Coba lagi..."
      _updateMessage("Ada $_failedUploads data gagal simpan.\nCoba lagi...");
      notifyListeners();
    }
  }

  Future<bool> _uploadSingleImage(File imageFile, int index) async {
    final token = _storage.token;
    final sampleId = _storage.sampleId;

    // orientation was encoded in filename? Or we should have stored it?
    // The filename I made: sample_..._P.jpg
    String orientation = "P";
    if (imageFile.path.contains("_L.jpg")) orientation = "L";

    final endpoint = _isWfa
        ? ApiEndpoints.uploadFotoGlobal
        : ApiEndpoints.uploadFoto;
    final url = Uri.parse(
      '${ApiConfig.baseUrl}$endpoint'
      '?token=$token&sample_id=$sampleId&index=$index&orientasi=$orientation',
    );

    try {
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'X-API-TOKEN': token ?? '',
      }); // Prompt says: "Gunakan Header X-API-TOKEN"

      request.files.add(
        await http.MultipartFile.fromPath('foto', imageFile.path),
      );

      final streamedResponse = await request.send().timeout(
        ApiConfig.defaultTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (response.body.contains("OK")) {
          return true;
        } else {
          // Unknown body but 200?
          CrashlyticsService().recordError(
            "Upload 200 but not OK: ${response.body}",
            StackTrace.current,
            reason: 'Upload Logic Error',
          );
          return false;
        }
      } else if (response.statusCode == 401) {
        if (response.body.contains("NO_LOGIN")) {
          _status = SampleRecordStatus.unauthorized;
          _updateMessage("Sesi Habis. Login Ulang.");
          notifyListeners();
          return false;
        }
      }

      // Log other errors
      CrashlyticsService().recordError(
        "Upload Failed: ${response.statusCode} ${response.body}",
        StackTrace.current,
        reason: 'Backend Error',
      );
      return false;
    } catch (e, stack) {
      // Connection error / RTO
      CrashlyticsService().recordError(
        e,
        stack,
        reason: 'Upload Connection Error',
      );
      // Do not fail the whole process immediately?
      // User says: "Jika server mengembalikan error yang tak dikenali, maka tampilkan pesan Koneksi server terganggu."
      // But this is inside a loop.
      return false;
    }
  }

  Future<void> _startTrainingProcess() async {
    _status = SampleRecordStatus.training;
    _updateMessage("Memproses Data...");
    notifyListeners();

    final token = _storage.token;
    final sampleId = _storage.sampleId;
    final endpoint = _isWfa
        ? ApiEndpoints.processTrainGlobal
        : ApiEndpoints.processTrain;
    final url = Uri.parse(
      '${ApiConfig.baseUrl}$endpoint'
      '?token=$token&sample_id=$sampleId',
    );

    try {
      final response = await http.get(url).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        if (response.body.contains("OK")) {
          _status = SampleRecordStatus.success;
          _updateMessage(
            "Anda telah merekam\nData Sampel Wajah\n\nData Sampel Presensi Wajah sudah dikirim dan diproses. Silakan login kembali untuk mengisi presensi Anda. Terima Kasih.",
          );
        } else {
          _status = SampleRecordStatus.error;
          _updateMessage("Gagal memproses data: ${response.body}");
          CrashlyticsService().recordError(
            "Train 200 not OK: ${response.body}",
            StackTrace.current,
          );
        }
      } else if (response.statusCode == 401) {
        if (response.body.contains("NO_LOGIN")) {
          _status = SampleRecordStatus.unauthorized;
          _updateMessage("Sesi Habis. Login Ulang.");
        } else {
          _handleGenericError(response);
        }
      } else {
        _handleGenericError(response);
      }
    } catch (e, stack) {
      _status = SampleRecordStatus.error;
      _updateMessage("Koneksi server terganggu.");
      CrashlyticsService().recordError(
        e,
        stack,
        reason: 'Training Connection Error',
      );
    }
    notifyListeners();
  }

  void _handleGenericError(http.Response response) {
    _status = SampleRecordStatus.error;
    _updateMessage("Koneksi server terganggu.");
    CrashlyticsService().recordError(
      "Train Failed: ${response.statusCode} ${response.body}",
      StackTrace.current,
    );
  }

  void _updateMessage(String msg) {
    _message = msg;
    // We don't notify here because logic usually does it after
  }
}
