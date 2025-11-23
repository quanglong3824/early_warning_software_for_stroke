import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../models/patient_model.dart';
import '../models/alert_model.dart';
import '../models/forum_post_model.dart';
import '../models/knowledge_article_model.dart';
import '../models/prediction_result_model.dart';

class AppDataProvider with ChangeNotifier {
  // Current User
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // Patients
  List<PatientModel> _patients = [];
  List<PatientModel> get patients => _patients;

  // Alerts
  List<AlertModel> _alerts = [];
  List<AlertModel> get alerts => _alerts;
  int get unreadAlertsCount => _alerts.where((a) => !a.isRead).length;

  // Dashboard Stats
  Map<String, int> _dashboardStats = {};
  Map<String, int> get dashboardStats => _dashboardStats;

  // Forum Posts
  List<ForumPostModel> _forumPosts = [];
  List<ForumPostModel> get forumPosts => _forumPosts;

  // Knowledge Articles
  List<KnowledgeArticleModel> _knowledgeArticles = [];
  List<KnowledgeArticleModel> get knowledgeArticles => _knowledgeArticles;

  // Prediction Results
  List<PredictionResultModel> _predictionResults = [];
  List<PredictionResultModel> get predictionResults => _predictionResults;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Initialize Provider
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Listen to auth state
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user != null) {
          await _fetchUserData(user.uid);
        } else {
          _currentUser = null;
          notifyListeners();
        }
      });
      
      // Initial check
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _fetchUserData(user.uid);
      }

      // Load other data (to be replaced with real data later)
      // For now we still load mock data for other features to avoid breaking the app completely
      // while we transition
      final String jsonString = await rootBundle.loadString('assets/data/app_data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Load patients (Mock)
      if (jsonData['patients'] != null) {
        _patients = (jsonData['patients'] as List)
            .map((p) => PatientModel.fromJson(p))
            .toList();
      }

      // Load alerts (Mock)
      if (jsonData['alerts'] != null) {
        _alerts = (jsonData['alerts'] as List)
            .map((a) => AlertModel.fromJson(a))
            .toList();
      }

      // Load dashboard stats (Mock)
      if (jsonData['dashboardStats'] != null) {
        _dashboardStats = Map<String, int>.from(jsonData['dashboardStats']);
      }

      // Load forum posts (Mock)
      if (jsonData['forumPosts'] != null) {
        _forumPosts = (jsonData['forumPosts'] as List)
            .map((p) => ForumPostModel.fromJson(p))
            .toList();
      }

      // Load knowledge articles (Mock)
      if (jsonData['knowledgeArticles'] != null) {
        _knowledgeArticles = (jsonData['knowledgeArticles'] as List)
            .map((a) => KnowledgeArticleModel.fromJson(a))
            .toList();
      }

      // Load prediction results (Mock)
      if (jsonData['predictionResults'] != null) {
        _predictionResults = (jsonData['predictionResults'] as List)
            .map((r) => PredictionResultModel.fromJson(r))
            .toList();
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  StreamSubscription<DatabaseEvent>? _userSubscription;

  // Fetch user data from Firebase
  Future<void> _fetchUserData(String uid) async {
    try {
      _userSubscription?.cancel();
      _userSubscription = FirebaseDatabase.instance.ref('users/$uid').onValue.listen((event) {
        if (event.snapshot.exists) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          _currentUser = UserModel.fromJson(data);
          notifyListeners();
        }
      });
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  // Get patient by ID
  PatientModel? getPatientById(String id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get forum post by ID
  ForumPostModel? getForumPostById(String id) {
    try {
      return _forumPosts.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get knowledge article by ID
  KnowledgeArticleModel? getKnowledgeArticleById(String id) {
    try {
      return _knowledgeArticles.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  // Filter knowledge articles by category
  List<KnowledgeArticleModel> getArticlesByCategory(String category) {
    if (category == 'Tất cả') return _knowledgeArticles;
    return _knowledgeArticles
        .where((a) => a.categories.contains(category))
        .toList();
  }

  // Get patients by status
  List<PatientModel> getPatientsByStatus(String status) {
    if (status == 'all') return _patients;
    return _patients.where((p) => p.status == status).toList();
  }

  // Get latest prediction by type
  PredictionResultModel? getLatestPrediction(String type) {
    try {
      final predictions = _predictionResults
          .where((p) => p.type == type)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return predictions.isNotEmpty ? predictions.first : null;
    } catch (e) {
      return null;
    }
  }

  // Mark alert as read
  void markAlertAsRead(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = AlertModel(
        id: _alerts[index].id,
        patientId: _alerts[index].patientId,
        patientName: _alerts[index].patientName,
        level: _alerts[index].level,
        message: _alerts[index].message,
        createdAt: _alerts[index].createdAt,
        isRead: true,
      );
      notifyListeners();
    }
  }

  // Add new forum post
  void addForumPost(ForumPostModel post) {
    _forumPosts.insert(0, post);
    notifyListeners();
  }

  // Like/Unlike forum post
  void toggleLikePost(String postId) {
    final index = _forumPosts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _forumPosts[index];
      _forumPosts[index] = ForumPostModel(
        id: post.id,
        authorId: post.authorId,
        authorName: post.authorName,
        title: post.title,
        content: post.content,
        likes: post.likes + 1,
        comments: post.comments,
        createdAt: post.createdAt,
        tags: post.tags,
      );
      notifyListeners();
    }
  }

  // Add prediction result
  void addPredictionResult(PredictionResultModel result) {
    _predictionResults.insert(0, result);
    notifyListeners();
  }

  // Update user profile
  void updateUserProfile(UserModel updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }
}
