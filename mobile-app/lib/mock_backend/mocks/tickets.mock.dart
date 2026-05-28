import '../types/ticket.dart';
import 'users.mock.dart';

final List<TicketDto> mockTickets = [
  TicketDto(
    id: "uuid-ticket-1",
    reporterId: mockUsers[1].id, // Sarah Ahmed
    reportedUserId: mockUsers[0].id, // Ahmed Ali
    reason: "Suspicious behavior and posting fake found items.",
    status: "pending",
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  TicketDto(
    id: "uuid-ticket-2",
    reporterId: mockUsers[0].id,
    reportedUserId: "uuid-user-unknown",
    reason: "Spam messages in chat.",
    status: "resolved",
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
  ),
];
