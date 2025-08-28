import 'package:flutter/foundation.dart';
import 'package:recette/core/data/repositories/data_repository.dart';

@immutable
class ChatMessage implements DataModel {
  @override
  final int? id;
  final String? sessionId;
  final String? role; // "user" or "model"
  final String? content;
  final DateTime? timestamp;

  ChatMessage({
    this.id,
    this.sessionId,
    this.role,
    this.content,
    this.timestamp,
  });

  /// Converts a ChatMessage object into a Map for database insertion.
  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'role': role,
      'content': content,
      'timestamp': timestamp,
    };
  }
  
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      sessionId: map['sessionId'],
      role: map['role'],
      content: map['content'],
      timestamp: map['timestamp'],
    );
  }
}