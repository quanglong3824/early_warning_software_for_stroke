import 'dart:async';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../data/models/chat_models.dart';
import '../services/auth_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _authService = AuthService();

  /// Get all conversations for a user
  Stream<List<ConversationModel>> getUserConversations(String userId) {
    return _db
        .child('conversations')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .asyncMap((event) async {
      final List<ConversationModel> conversations = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        // Fetch all conversations with doctor names
        for (var entry in data.entries) {
          final convData = Map<String, dynamic>.from(entry.value as Map);
          final doctorId = convData['doctorId'] as String?;
          
          // Fetch doctor name from users table
          String? doctorName;
          if (doctorId != null) {
            doctorName = await _fetchDoctorName(doctorId);
          }
          
          // Create conversation with doctor name
          final conversation = ConversationModel.fromJson({
            ...convData,
            'doctorName': doctorName,
          });
          conversations.add(conversation);
        }
      }
      
      // Sort by lastMessageTime descending
      conversations.sort((a, b) {
        final aTime = a.lastMessageTime ?? 0;
        final bTime = b.lastMessageTime ?? 0;
        return bTime.compareTo(aTime);
      });
      return conversations;
    });
  }

  /// Fetch doctor name from users table
  Future<String?> _fetchDoctorName(String doctorId) async {
    try {
      final snapshot = await _db.child('users').child(doctorId).get();
      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        return userData['name'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching doctor name: $e');
      return null;
    }
  }

  /// Get messages for a conversation
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _db
        .child('messages')
        .child(conversationId)
        .orderByChild('createdAt')
        .onValue
        .map((event) {
      final List<MessageModel> messages = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final msgData = Map<String, dynamic>.from(value as Map);
          messages.add(MessageModel.fromJson(msgData));
        });
      }
      // Sort by timestamp ascending (oldest first)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  /// Create or get conversation with a doctor
  Future<String?> createOrGetConversation({
    required String userId,
    required String doctorId,
    String? doctorName,
  }) async {
    try {
      // Check if conversation already exists
      final snapshot = await _db
          .child('conversations')
          .orderByChild('userId')
          .equalTo(userId)
          .get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        for (var entry in data.entries) {
          final conv = Map<String, dynamic>.from(entry.value as Map);
          if (conv['doctorId'] == doctorId) {
            return conv['conversationId'];
          }
        }
      }

      // Create new conversation
      final convRef = _db.child('conversations').push();
      final conversationId = convRef.key!;
      final now = DateTime.now().millisecondsSinceEpoch;

      final conversation = ConversationModel(
        conversationId: conversationId,
        userId: userId,
        doctorId: doctorId,
        doctorName: doctorName,
        userUnreadCount: 0,
        doctorUnreadCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      await convRef.set(conversation.toJson());

      // Add to user_conversations index
      await _db
          .child('user_conversations')
          .child(userId)
          .child(conversationId)
          .set({
        'conversationId': conversationId,
        'doctorId': doctorId,
        'createdAt': now,
      });

      // Add to doctor_conversations index
      await _db
          .child('doctor_conversations')
          .child(doctorId)
          .child(conversationId)
          .set({
        'conversationId': conversationId,
        'userId': userId,
        'createdAt': now,
      });

      return conversationId;
    } catch (e) {
      print('Error creating conversation: $e');
      return null;
    }
  }

  /// Send a message
  Future<String?> sendMessage({
    required String conversationId,
    required String senderId,
    String? senderName,
    required String message,
    String type = 'text',
    String? prescriptionId,
  }) async {
    try {
      final messageRef = _db.child('messages').child(conversationId).push();
      final messageId = messageRef.key!;
      final now = DateTime.now().millisecondsSinceEpoch;

      final messageModel = MessageModel(
        messageId: messageId,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        message: message,
        type: type,
        prescriptionId: prescriptionId,
        timestamp: now,
        isRead: false,
      );

      await messageRef.set(messageModel.toJson());

      // Update conversation
      final convSnapshot = await _db.child('conversations').child(conversationId).get();
      if (convSnapshot.exists) {
        final convData = Map<String, dynamic>.from(convSnapshot.value as Map);
        final isUser = convData['userId'] == senderId;

        await _db.child('conversations').child(conversationId).update({
          'lastMessage': message,
          'lastMessageTime': now,
          'updatedAt': now,
          // Increment unread count for the receiver
          if (isUser) 'doctorUnreadCount': ServerValue.increment(1),
          if (!isUser) 'userUnreadCount': ServerValue.increment(1),
        });
      }

      return messageId;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  /// Send prescription message
  Future<String?> sendPrescriptionMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String prescriptionId,
    required String prescriptionCode,
  }) async {
    return sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      message: 'Đã kê đơn thuốc - Mã: $prescriptionCode',
      type: 'prescription',
      prescriptionId: prescriptionId,
    );
  }

  /// Mark messages as read
  Future<bool> markAsRead(String conversationId, String userId) async {
    try {
      // Get conversation to check if user is the receiver
      final convSnapshot = await _db.child('conversations').child(conversationId).get();
      if (!convSnapshot.exists) return false;

      final convData = Map<String, dynamic>.from(convSnapshot.value as Map);
      final isUser = convData['userId'] == userId;

      // Reset unread count
      await _db.child('conversations').child(conversationId).update({
        if (isUser) 'userUnreadCount': 0,
        if (!isUser) 'doctorUnreadCount': 0,
      });

      return true;
    } catch (e) {
      print('Error marking as read: $e');
      return false;
    }
  }

  /// Get conversation by ID
  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      final snapshot = await _db.child('conversations').child(conversationId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return ConversationModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting conversation: $e');
      return null;
    }
  }

  // ============================================
  // DOCTOR-SPECIFIC METHODS
  // ============================================

  /// Get all conversations for a doctor, sorted by most recent message
  /// Requirements: 4.1
  Stream<List<ConversationModel>> getDoctorConversations(String doctorId) {
    return _db
        .child('conversations')
        .orderByChild('doctorId')
        .equalTo(doctorId)
        .onValue
        .asyncMap((event) async {
      final List<ConversationModel> conversations = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        for (var entry in data.entries) {
          final convData = Map<String, dynamic>.from(entry.value as Map);
          final patientId = convData['userId'] as String?;
          
          // Fetch patient name from users table
          String? patientName;
          String? patientAvatar;
          bool isOnline = false;
          
          if (patientId != null) {
            final patientInfo = await _fetchUserInfo(patientId);
            patientName = patientInfo['name'];
            patientAvatar = patientInfo['avatar'];
            isOnline = patientInfo['isOnline'] ?? false;
          }
          
          // Create conversation with patient info
          final conversation = ConversationModel.fromJson({
            ...convData,
            'patientName': patientName,
            'patientAvatar': patientAvatar,
            'isOnline': isOnline,
          });
          conversations.add(conversation);
        }
      }
      
      // Sort by lastMessageTime descending (most recent first)
      conversations.sort((a, b) {
        final aTime = a.lastMessageTime ?? 0;
        final bTime = b.lastMessageTime ?? 0;
        return bTime.compareTo(aTime);
      });
      return conversations;
    });
  }

  /// Fetch user info from users table
  Future<Map<String, dynamic>> _fetchUserInfo(String userId) async {
    try {
      final snapshot = await _db.child('users').child(userId).get();
      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        return {
          'name': userData['name'] as String?,
          'avatar': userData['avatar'] as String?,
          'isOnline': userData['isOnline'] as bool? ?? false,
        };
      }
      return {'name': null, 'avatar': null, 'isOnline': false};
    } catch (e) {
      print('Error fetching user info: $e');
      return {'name': null, 'avatar': null, 'isOnline': false};
    }
  }

  /// Get total unread message count for a doctor across all conversations
  /// Requirements: 4.4
  Stream<int> getUnreadCount(String doctorId) {
    return _db
        .child('conversations')
        .orderByChild('doctorId')
        .equalTo(doctorId)
        .onValue
        .map((event) {
      int totalUnread = 0;
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        for (var entry in data.entries) {
          final convData = Map<String, dynamic>.from(entry.value as Map);
          totalUnread += (convData['doctorUnreadCount'] as int?) ?? 0;
        }
      }
      return totalUnread;
    });
  }

  /// Send a media message (image/file) with Firebase Storage upload
  /// Requirements: 4.3, 4.5
  Future<String?> sendMediaMessage({
    required String conversationId,
    required String senderId,
    String? senderName,
    required File file,
    required String mediaType, // 'image' or 'file'
  }) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final fileName = '${conversationId}_${senderId}_$timestamp.$extension';
      
      // Upload to Firebase Storage
      final storageRef = _storage.ref().child('chat_media').child(conversationId).child(fileName);
      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // Create message with media URL
      final messageRef = _db.child('messages').child(conversationId).push();
      final messageId = messageRef.key!;
      final now = DateTime.now().millisecondsSinceEpoch;

      final messageModel = MessageModel(
        messageId: messageId,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        message: downloadUrl,
        type: mediaType,
        timestamp: now,
        isRead: false,
      );

      await messageRef.set(messageModel.toJson());

      // Update conversation
      final convSnapshot = await _db.child('conversations').child(conversationId).get();
      if (convSnapshot.exists) {
        final convData = Map<String, dynamic>.from(convSnapshot.value as Map);
        final isUser = convData['userId'] == senderId;
        
        final lastMessageText = mediaType == 'image' ? '📷 Hình ảnh' : '📎 Tệp đính kèm';

        await _db.child('conversations').child(conversationId).update({
          'lastMessage': lastMessageText,
          'lastMessageTime': now,
          'updatedAt': now,
          if (isUser) 'doctorUnreadCount': ServerValue.increment(1),
          if (!isUser) 'userUnreadCount': ServerValue.increment(1),
        });
      }

      return messageId;
    } catch (e) {
      print('Error sending media message: $e');
      return null;
    }
  }

  /// Mark all messages in a conversation as read for a specific user
  /// Requirements: 4.6
  Future<bool> markConversationAsRead(String conversationId, String readerId) async {
    try {
      // Get conversation to determine if reader is doctor or patient
      final convSnapshot = await _db.child('conversations').child(conversationId).get();
      if (!convSnapshot.exists) return false;

      final convData = Map<String, dynamic>.from(convSnapshot.value as Map);
      final isDoctor = convData['doctorId'] == readerId;
      final isUser = convData['userId'] == readerId;

      if (!isDoctor && !isUser) return false;

      // Reset unread count for the reader
      await _db.child('conversations').child(conversationId).update({
        if (isDoctor) 'doctorUnreadCount': 0,
        if (isUser) 'userUnreadCount': 0,
      });

      // Mark individual messages as read
      final messagesSnapshot = await _db
          .child('messages')
          .child(conversationId)
          .orderByChild('isRead')
          .equalTo(false)
          .get();

      if (messagesSnapshot.exists) {
        final messages = Map<String, dynamic>.from(messagesSnapshot.value as Map);
        final updates = <String, dynamic>{};
        
        for (var entry in messages.entries) {
          final msgData = Map<String, dynamic>.from(entry.value as Map);
          // Only mark messages from the other party as read
          if (msgData['senderId'] != readerId) {
            updates['messages/$conversationId/${entry.key}/isRead'] = true;
          }
        }
        
        if (updates.isNotEmpty) {
          await _db.update(updates);
        }
      }

      return true;
    } catch (e) {
      print('Error marking conversation as read: $e');
      return false;
    }
  }

  /// Get patient online status
  Stream<bool> getPatientOnlineStatus(String patientId) {
    return _db
        .child('users')
        .child(patientId)
        .child('isOnline')
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return event.snapshot.value as bool? ?? false;
      }
      return false;
    });
  }
}
