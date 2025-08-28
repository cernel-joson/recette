
import 'package:recette/core/data/repositories/data_repository.dart';
import 'package:recette/features/chat/data/models/chat_message_model.dart';

class ChatRepository {
  final messages = DataRepository<ChatMessage>(
    tableName: 'chat_messages',
    fromMap: (map) => ChatMessage.fromMap(map),
  );

  /*Future<List<ChatMessage>> getMessagesForSession(String sessionId) async {
    // Custom query to get messages for a specific chat
  }*/
}