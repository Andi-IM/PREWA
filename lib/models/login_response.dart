enum TrainingStatus { notTrained, trained, resampleRequired }

class LoginResponse {
  final bool isSuccess;
  final String? status;
  final String? userId;
  final String? token;
  final String? namaUser;
  final String? sampleId;
  final TrainingStatus? trainingStatus;
  final String? ceklok;
  final String? tglKerja;

  LoginResponse({
    required this.isSuccess,
    this.status,
    this.userId,
    this.token,
    this.namaUser,
    this.sampleId,
    this.trainingStatus,
    this.ceklok,
    this.tglKerja,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    TrainingStatus? trainingStatus;
    final statusTraining = json['status_training'];

    if (statusTraining != null) {
      int? statusInt;
      if (statusTraining is int) {
        statusInt = statusTraining;
      } else if (statusTraining is String) {
        statusInt = int.tryParse(statusTraining);
      }

      if (statusInt == 0) {
        trainingStatus = TrainingStatus.notTrained;
      } else if (statusInt == 1) {
        trainingStatus = TrainingStatus.trained;
      } else {
        trainingStatus = TrainingStatus.resampleRequired;
      }
    }

    return LoginResponse(
      isSuccess: json['status'] == 'OK',
      status: json['status']?.toString(),
      userId: json['user_id']?.toString(),
      token: json['token']?.toString(),
      namaUser: json['nama_user']?.toString(),
      sampleId: json['sample_id']?.toString(),
      trainingStatus: trainingStatus,
      ceklok: json['ceklok']?.toString(),
      tglKerja: json['tgl_kerja']?.toString(),
    );
  }

  Map<String, dynamic> toLogMap() {
    return {
      'status': status,
      'user_id': userId,
      'token': token != null ? '****' : null,
      'nama_user': namaUser,
      'sample_id': sampleId,
      'status_training': trainingStatus?.name,
      'ceklok': ceklok,
      'tgl_kerja': tglKerja,
    };
  }
}
