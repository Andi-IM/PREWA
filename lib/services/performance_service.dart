import 'package:firebase_performance/firebase_performance.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  FirebasePerformance get _performance => FirebasePerformance.instance;

  Future<void> initialize() async {
    await _performance.setPerformanceCollectionEnabled(true);
  }

  Trace startTrace(String name) {
    final trace = _performance.newTrace(name);
    trace.start();
    return trace;
  }

  Future<void> stopTrace(Trace trace, {Map<String, String>? attributes}) async {
    if (attributes != null) {
      attributes.forEach((key, value) {
        trace.putAttribute(key, value);
      });
    }
    await trace.stop();
  }

  Future<T> traceAsync<T>(
    String name,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
  }) async {
    final trace = _performance.newTrace(name);
    await trace.start();

    try {
      final result = await operation();

      if (attributes != null) {
        attributes.forEach((key, value) {
          trace.putAttribute(key, value);
        });
      }

      return result;
    } finally {
      await trace.stop();
    }
  }

  HttpMetric startHttpMetric(String url, String httpMethod) {
    final metric = _performance.newHttpMetric(
      url,
      HttpMethod.values.firstWhere(
        (e) => e.name.toUpperCase() == httpMethod.toUpperCase(),
        orElse: () => HttpMethod.Get,
      ),
    );
    metric.start();
    return metric;
  }

  Future<void> stopHttpMetric(
    HttpMetric metric, {
    int? responseCode,
    int? responsePayloadSize,
    String? responseContentType,
  }) async {
    if (responseCode != null) {
      metric.httpResponseCode = responseCode;
    }
    if (responsePayloadSize != null) {
      metric.responsePayloadSize = responsePayloadSize;
    }
    if (responseContentType != null) {
      metric.responseContentType = responseContentType;
    }
    await metric.stop();
  }
}
