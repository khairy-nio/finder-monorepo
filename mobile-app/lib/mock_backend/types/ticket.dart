class TicketDto {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final String status; // 'pending', 'reviewed', 'resolved'
  final DateTime createdAt;

  TicketDto({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory TicketDto.fromJson(Map<String, dynamic> json) {
    return TicketDto(
      id: json['id'],
      reporterId: json['reporter_id'],
      reportedUserId: json['reported_user_id'],
      reason: json['reason'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'reported_user_id': reportedUserId,
      'reason': reason,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
