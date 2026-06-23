import '../types/ticket.dart';
import '../mocks/tickets.mock.dart';
import '../utils/network_simulator.dart';

class TicketService {
  // In-memory mock database
  static final List<TicketDto> _mockDb = List.from(mockTickets);

  Future<ApiResponse<List<TicketDto>>> getTickets({int page = 1, int limit = 10}) async {
    if (NetworkSimulator.USE_MOCK_API) {
      await NetworkSimulator.simulate();
      
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      
      if (startIndex >= _mockDb.length) {
         return ApiResponse.success(
           [], 
           meta: MetaData(page: page, total: _mockDb.length, totalPages: (_mockDb.length / limit).ceil())
         );
      }
      
      final paginatedData = _mockDb.sublist(
        startIndex, 
        endIndex > _mockDb.length ? _mockDb.length : endIndex
      );

      return ApiResponse.success(
        paginatedData,
        meta: MetaData(
          page: page, 
          total: _mockDb.length, 
          totalPages: (_mockDb.length / limit).ceil(),
        )
      );
    } else {
      throw UnimplementedError("Real API not connected yet");
    }
  }

  Future<ApiResponse<TicketDto>> createTicket(Map<String, dynamic> payload) async {
    if (NetworkSimulator.USE_MOCK_API) {
      await NetworkSimulator.simulate();
      
      if (payload['reporter_id'] == null) return ApiResponse.error("reporter_id is required", code: 400);
      if (payload['reported_user_id'] == null) return ApiResponse.error("reported_user_id is required", code: 400);
      if (payload['reason'] == null) return ApiResponse.error("reason is required", code: 400);

      final newTicket = TicketDto(
        id: "uuid-ticket-${DateTime.now().millisecondsSinceEpoch}",
        reporterId: payload['reporter_id'],
        reportedUserId: payload['reported_user_id'],
        reason: payload['reason'],
        status: "pending",
        createdAt: DateTime.now(),
      );

      _mockDb.insert(0, newTicket);
      return ApiResponse.success(newTicket);
    } else {
      throw UnimplementedError("Real API not connected yet");
    }
  }
}
