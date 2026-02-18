enum AccessStatus { ok, noWfa, invalid }

enum WorkStatus { ok, notWorkingDay }

class PingResponse {
  final AccessStatus accessStatus;
  final WorkStatus? workStatus;
  final String? ipClient;

  PingResponse({required this.accessStatus, this.workStatus, this.ipClient});

  factory PingResponse.fromJson(Map<String, dynamic> json) {
    AccessStatus accessStatus;
    final stsAkses = json['sts_akses'];

    if (stsAkses == 'OK') {
      accessStatus = AccessStatus.ok;
    } else if (stsAkses == 'NO_WFA') {
      accessStatus = AccessStatus.noWfa;
    } else {
      accessStatus = AccessStatus.invalid;
    }

    WorkStatus? workStatus;
    final stsKerja = json['sts_kerja'];

    if (stsKerja == 'OK') {
      workStatus = WorkStatus.ok;
    } else if (stsKerja != null) {
      workStatus = WorkStatus.notWorkingDay;
    }

    return PingResponse(
      accessStatus: accessStatus,
      workStatus: workStatus,
      ipClient: json['ip_client']?.toString(),
    );
  }

  bool get isValid =>
      accessStatus == AccessStatus.ok && workStatus == WorkStatus.ok;
  bool get isWfaDisabled => accessStatus == AccessStatus.noWfa;
  bool get isNotWorkingDay => workStatus == WorkStatus.notWorkingDay;
}
