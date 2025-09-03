class ApiResponse<T> {
  final String status;
  final String message;
  final T? data;

  ApiResponse({required this.status, required this.message, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic json)? fromJsonT) {
    // Handling status as a Map if it comes as {name: "OK", code: 200}
    String parsedStatus;
    if (json['status'] is Map) {
      parsedStatus = json['status']['name'] as String;
    } else {
      parsedStatus = json['status'].toString();
    }

    return ApiResponse(
      status: parsedStatus,
      message: json['message'] as String,
      data: fromJsonT != null && json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }
}
