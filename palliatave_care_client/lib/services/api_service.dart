// A centralized service for making API calls to the backend.
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:palliatave_care_client/models/api_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:palliatave_care_client/models/enriched_post.dart';
import 'package:palliatave_care_client/models/post.dart'; // Import the Post model
import 'package:palliatave_care_client/models/post_summary.dart';
import 'package:palliatave_care_client/util/http_status.dart'; // Import HttpStatus
import '../models/user_account.dart'; // Import UserAccount model
import '../models/login_response.dart'; // Import LoginResponse model
import '../models/topic.dart';
import 'dart:io'; // For File
import 'package:palliatave_care_client/models/post_summary_page_response.dart';
import 'package:palliatave_care_client/models/post_dto.dart'; // Assuming you have a PostDTO model
import 'package:palliatave_care_client/models/comment_dto.dart'; // Assuming you have a CommentDTO model
import 'package:palliatave_care_client/models/chat_models.dart';
import 'package:palliatave_care_client/models/notification_model.dart'; 


class ApiService {
  // Define the base URL for your backend server.
  // IMPORTANT: For Android Emulator, use 'http://10.0.2.2:8080' to access host localhost.
  // For iOS Simulator, 'http://localhost:8080' usually works.
  // For physical devices, use your machine's actual IP address.
  // static const String _baseUrl = "http://localhost:8080";
  static const String _baseUrl = "https://palliativecare-k6g2.onrender.com";

  // Endpoint specific paths
  static const String _authPath = "/api/auth";
  static const String _postsPath = "/api/posts"; 
  static const String _topicsPath = "/api/topics";

  // Secure storage instance
  final _secureStorage = const FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token'; // Key for storing the token
  static const String _userProfileKey = 'user_profile'; // Key for storing user profile

  // Method to save the JWT token securely
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    print('Token saved securely.');
  }

  // Method to retrieve the JWT token securely
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  // Method to delete the JWT token securely (for logout)
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
    print('Token deleted securely.');
  }

  // Method to save user profile securely
  Future<void> saveUserProfile(UserAccount user) async {
    await _secureStorage.write(key: _userProfileKey, value: json.encode(user.toJson()));
    print('User profile saved securely.');
  }

  // Method to load user profile securely
  Future<UserAccount?> loadUserProfile() async {
    String? userProfileJson = await _secureStorage.read(key: _userProfileKey);
    if (userProfileJson != null) {
      return UserAccount.fromJson(json.decode(userProfileJson));
    }
    return null;
  }

  // Method to delete user profile securely
  Future<void> deleteUserProfile() async {
    await _secureStorage.delete(key: _userProfileKey);
    print('User profile deleted securely.');
  }


// --- Authentication ---
  // Modified registerUser to accept all necessary registration fields directly
  Future<ApiResponse<LoginResponse>> registerUser({
    required String firstName,
    required String middleName,
    required String lastName, // Changed from familyName
    required String birthDate,
    required String mobile, // Changed from mobileNo
    required String email,
    required String address,
    required String password,
    required String confirmPassword, // Added confirmPassword
    required String role, // Changed from userType
  }) async {
    final url = Uri.parse('$_baseUrl$_authPath/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'firstName': firstName,
          'middleName': middleName,
          'lastName': lastName, // Corrected field name
          'birthDate': birthDate,
          'mobile': mobile, // Corrected field name
          'email': email,
          'address': address,
          'password': password,
          'confirmPassword': confirmPassword, // Included in the payload
          'role': role, // Corrected field name
        }),
      );
      final decodedResponse = json.decode(response.body);
      ApiResponse<LoginResponse> apiResponse = ApiResponse.fromJson(decodedResponse, (json) => LoginResponse.fromJson(json));

      if (apiResponse.status == HttpStatus.CREATED.name && apiResponse.data != null) {
        await saveToken(apiResponse.data!.jwtToken);
        await saveUserProfile(apiResponse.data!.user);
      }
      return apiResponse;
    } catch (e) {
      return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.toString(),
        message: "Failed to connect to the server: $e",
      );
    }
  }

  Future<ApiResponse<LoginResponse>> loginUser(String email, String password) async {
    final url = Uri.parse('$_baseUrl$_authPath/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      final decodedResponse = json.decode(response.body);
      ApiResponse<LoginResponse> apiResponse = ApiResponse.fromJson(decodedResponse, (json) => LoginResponse.fromJson(json));

      if (apiResponse.status == HttpStatus.OK.name && apiResponse.data != null) {
        await saveToken(apiResponse.data!.jwtToken);
        await saveUserProfile(apiResponse.data!.user);
      }
      return apiResponse;
    } catch (e) {
      return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.toString(),
        message: "Failed to connect to the server: $e",
      );
    }
  }

  // --- Topics ---
  // Method to get all topics
  Future<ApiResponse<List<Topic>>> getAllTopics() async {
    final url = Uri.parse('$_baseUrl$_topicsPath/all');
    try {
      final String? token = await getToken();
      if (token == null) {
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "No authentication token found. Please log in.",
        );
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      // Check for empty body before decoding
      if (response.body.isEmpty) {
        return ApiResponse(
          status: HttpStatus.OK.name,
          message: "No topics found.",
          data: [], // Return an empty list explicitly
        );
      }

      final decodedResponse = json.decode(response.body);

      if (decodedResponse['status'] == 'OK' && decodedResponse['data'] != null) {
        final List<dynamic> topicJsonList = decodedResponse['data'] ?? [];
        final List<Topic> topics = topicJsonList.map((json) => Topic.fromJson(json)).toList();
        return ApiResponse(status: 'OK', message: decodedResponse['message'] ?? "Topics fetched successfully", data: topics);
      } else {
        return ApiResponse(
          status: decodedResponse['status']?.toString() ?? HttpStatus.BAD_REQUEST.name,
          message: decodedResponse['message'] ?? "Failed to fetch topics",
        );
      }
    } catch (e) {
      return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.toString(),
        message: "Failed to fetch topics: $e",
      );
    }
  }

  // Method to get subscribed topics 
  Future<ApiResponse<List<Topic>>> getSubscribedTopics() async {
    final url = Uri.parse('$_baseUrl$_topicsPath/subscribed');
    try {
      final String? token = await getToken();
      if (token == null) {
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "No authentication token found. Please log in.",
        );
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Check for empty body before decoding
      if (response.body.isEmpty) {
        return ApiResponse(
          status: HttpStatus.OK.name,
          message: "No subscribed topics found.",
          data: [], // Return an empty list explicitly
        );
      }

      final decodedResponse = json.decode(response.body);

      if (decodedResponse['status'] == 'OK' && decodedResponse['data'] != null) {
        final List<dynamic> topicJsonList = decodedResponse['data'] ?? [];
        final List<Topic> topics = topicJsonList.map((json) => Topic.fromJson(json)).toList();
        return ApiResponse(status: 'OK', message: decodedResponse['message'] ?? "Subscribed topics fetched successfully", data: topics);
      } else {
        return ApiResponse(
          status: decodedResponse['status']?.toString() ?? HttpStatus.BAD_REQUEST.name,
          message: decodedResponse['message'] ?? "Failed to fetch subscribed topics",
        );
      }
    } catch (e) {
      return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.toString(),
        message: "Failed to fetch subscribed topics: $e",
      );
    }
  }

  // Method to get just the IDs of subscribed topics
  Future<ApiResponse<List<String>>> getSubscribedTopicIds() async {
    // This method now calls getSubscribedTopics and extracts IDs
    final ApiResponse<List<Topic>> apiResponse = await getSubscribedTopics();

    if (apiResponse.status == HttpStatus.OK.name && apiResponse.data != null) {
      final List<String> topicIds = apiResponse.data!.map((topic) => topic.id).toList();
      return ApiResponse(status: 'OK', message: apiResponse.message, data: topicIds);
    } else {
      return ApiResponse(
        status: apiResponse.status,
        message: apiResponse.message,
        data: [], // Ensure an empty list of IDs on error
      );
    }
  }

  // Method to create a new topic
  Future<ApiResponse<String>> createTopic({
    required String title,
    required String description,
    File? logo,
    List<File>? resources,
  }) async {
    final url = Uri.parse('$_baseUrl$_topicsPath/create');
    try {
      final String? token = await getToken();
      if (token == null) {
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "No authentication token found. Please log in.",
        );
      }

      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['title'] = title
        ..fields['description'] = description;

      if (logo != null) {
        request.files.add(await http.MultipartFile.fromPath('logo', logo.path));
      }
      if (resources != null) {
        for (var resourceFile in resources) {
          request.files.add(await http.MultipartFile.fromPath('resources', resourceFile.path));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Check for empty body before decoding
      if (response.body.isEmpty) {
        return ApiResponse(
          status: HttpStatus.INTERNAL_SERVER_ERROR.name, // Or a more specific status
          message: "Server returned an empty response body.",
          data: null,
        );
      }

      final decodedResponse = json.decode(response.body);

      return ApiResponse.fromJson(decodedResponse, (json) => json.toString());
    } catch (e) {
      return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.toString(),
        message: "Failed to create topic: $e",
      );
    }
  }

  // Method to register user to a topic
  Future<ApiResponse<String>> registerToTopic(String topicId) async {
    final url = Uri.parse('$_baseUrl$_topicsPath/$topicId/register');
    try {
      final String? token = await getToken();
      if (token == null) {
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "No authentication token found. Please log in.",
        );
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      // Check for empty body before decoding
      if (response.body.isEmpty) {
        return ApiResponse(
          status: HttpStatus.INTERNAL_SERVER_ERROR.name,
          message: "Server returned an empty response body for topic registration.",
          data: null,
        );
      }

      final decodedResponse = json.decode(response.body);
      return ApiResponse.fromJson(decodedResponse, (json) => json.toString());
    } catch (e) {
      return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.toString(),
        message: "Failed to register to topic: $e",
      );
    }
  }

  // Method to unregister user from a topic
  Future<ApiResponse<String>> unregisterFromTopic(String topicId) async {
    final url = Uri.parse('$_baseUrl$_topicsPath/$topicId/unregister');
    try {
      final String? token = await getToken();
      if (token == null) {
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "No authentication token found. Please log in.",
        );
      }

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      // Check for empty body before decoding
      if (response.body.isEmpty) {
        return ApiResponse(
          status: HttpStatus.INTERNAL_SERVER_ERROR.name,
          message: "Server returned an empty response body for topic unregistration.",
          data: null,
        );
      }

      final decodedResponse = json.decode(response.body);
      return ApiResponse.fromJson(decodedResponse, (json) => json.toString());
    } catch (e) {
      return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.toString(),
        message: "Failed to unregister from topic: $e",
      );
    }
  }

  // Method to get posts by topic ID with pagination
  Future<ApiResponse<PostSummaryPageResponse>> getPostsByTopic(String topicId, int page, int size) async {
    final url = Uri.parse('$_baseUrl$_postsPath/by-topic/$topicId?page=$page&size=$size');
    try {
      final String? token = await getToken();
      if (token == null) {
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "No authentication token found. Please log in.",
        );
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.body.isEmpty) {
        return ApiResponse(
          status: HttpStatus.OK.name,
          message: "No posts found for this topic.",
          data: PostSummaryPageResponse(posts: [], isLastPage: true),
        );
      }

      final decodedResponse = json.decode(response.body);

      // *** FIX IS HERE: More defensive parsing ***
      if (decodedResponse['status'] == 'OK') {
        // First, check if 'data' is not null AND is actually a Map
        if (decodedResponse['data'] is Map<String, dynamic>) {
          final Map<String, dynamic> pageData = decodedResponse['data'];
          final List<dynamic> postJsonList = pageData['content'] ?? [];
          final bool isLastPage = pageData['last'] ?? true;
         final List<PostSummary> posts =
            postJsonList.map((json) => PostSummary.fromJson(json)).toList();
          final pageResponse  = PostSummaryPageResponse(posts: posts, isLastPage: isLastPage);

          return ApiResponse(
            status: 'OK',
            message: decodedResponse['message'] ?? "Posts fetched successfully",
            data: pageResponse 
          );
        } else {
          // This handles the case where "data" is null or not a Map, but status is OK
          // (e.g., an empty topic with no posts)
          return ApiResponse(
            status: 'OK',
            message: "No posts found for this topic.",
            data: PostSummaryPageResponse(posts: [], isLastPage: true),
          );
        }
      } else {
        // This handles actual error responses from the backend
        return ApiResponse(
          status: decodedResponse['status']?.toString() ?? HttpStatus.BAD_REQUEST.name,
          message: decodedResponse['message'] ?? "Failed to fetch posts for topic",
        );
      }
    } catch (e) {
      return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.toString(),
        message: "Failed to fetch posts for topic: $e",
      );
    }
  }
  // --- Posts ---
  // Method to get paginated posts from subscribed topics
  Future<ApiResponse<PostSummaryPageResponse>> getPostsFromSubscribedTopicsPaged(int page, int size) async {
    final url = Uri.parse('$_baseUrl$_postsPath/subscribed/paged?page=$page&size=$size');
    try {
      final String? token = await getToken();
      if (token == null) {
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "No authentication token found. Please log in.",
        );
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
        if (response.body.isEmpty) {
        return ApiResponse(
          status: HttpStatus.OK.name,
          message: "No posts found from subscribed topics.",
          data: PostSummaryPageResponse(posts: [], isLastPage: true),
        );
      }

      final decodedResponse = json.decode(response.body);

      if (decodedResponse['status'] == 'OK' && decodedResponse['data'] is Map<String, dynamic>) {
        final Map<String, dynamic> pageData = decodedResponse['data'];
        final List<dynamic> postJsonList = pageData['content'] ?? [];
        final bool isLastPage = pageData['last'] ?? true;
        final List<PostSummary> posts =
            postJsonList.map((json) => PostSummary.fromJson(json)).toList();
        final pageResponse = PostSummaryPageResponse(posts: posts, isLastPage: isLastPage);

        return ApiResponse(
          status: 'OK',
          message: decodedResponse['message'] ?? "Posts fetched successfully",
          data: pageResponse,
        );
      } else {
        return ApiResponse(
          status: decodedResponse['status']?.toString() ?? HttpStatus.BAD_REQUEST.name,
          message: decodedResponse['message'] ?? "Failed to fetch posts",
        );
      }
    } catch (e) {
      return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.toString(),
        message: "Failed to connect to the server: $e",
      );
    }
  }

  // In lib/services/api_service.dart

  // New method to create a doctor's post (multipart/form-data)
  Future<ApiResponse<Post>> createDoctorPost(String topicId, PostDTO postDTO) async {
    final url = Uri.parse('$_baseUrl$_postsPath/$topicId/create');
    try {
      final String? token = await getToken();
      if (token == null) {
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "No authentication token found. Please log in.",
        );
      }

      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        // Use the correct non-nullable fields
        ..fields['title'] = postDTO.title
        ..fields['content'] = postDTO.content;
        // REMOVED: ..fields['postType'] = postDTO.postType!; because it doesn't exist

      // ADDED LOOP: To handle multiple files correctly
      // CHANGED: 'media' to 'resources' to match the DTO and backend
      if (postDTO.resources.isNotEmpty) {
        for (var resourceFile in postDTO.resources) {
          request.files.add(await http.MultipartFile.fromPath(
            'resources', // This key MUST match the backend's "@RequestParam List<MultipartFile> resources"
            resourceFile.path
          ));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final decodedResponse = json.decode(response.body);
      
      return ApiResponse.fromJson(decodedResponse, (json) => Post.fromJson(json));
    } catch (e) {
      return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.toString(),
        message: "Failed to create doctor's post: $e",
      );
    }
  }

  // New method to create a patient question (@RequestBody JSON)
  Future<ApiResponse<Post>> createPatientQuestion(PostDTO postDTO) async {
    final url = Uri.parse('$_baseUrl$_postsPath/q-a/create');
    try {
      final String? token = await getToken();
      if (token == null) {
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "No authentication token found. Please log in.",
        );
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        // CHANGED: Create the JSON map directly, since PostDTO doesn't have toJson()
        // This endpoint likely only needs title and content.
        body: json.encode({
          'title': postDTO.title,
          'content': postDTO.content,
        }),
      );
      final decodedResponse = json.decode(response.body);
      
      return ApiResponse.fromJson(decodedResponse, (json) => Post.fromJson(json));
    } catch (e) {
      return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.toString(),
        message: "Failed to create patient question: $e",
      );
    }
  }

  // New method to add a comment to a post
  Future<ApiResponse<Post>> addComment(String postId, CommentDTO commentDTO) async {
    final url = Uri.parse('$_baseUrl$_postsPath/$postId/comment');
    try {
      final String? token = await getToken();
      if (token == null) {
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "No authentication token found. Please log in.",
        );
      }
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(commentDTO.toJson()),
      );
      final decodedResponse = json.decode(response.body);
      
      return ApiResponse.fromJson(decodedResponse, (json) => Post.fromJson(json));
    } catch (e) {
      return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.toString(),
        message: "Failed to add comment: $e",
      );
    }
  }

  // New method to get an enriched post
  Future<ApiResponse<EnrichedPost>> getEnrichedPost(String postId) async {
    final url = Uri.parse('$_baseUrl$_postsPath/$postId/enriched');
    try {
      final String? token = await getToken();
      if (token == null) {
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "No authentication token found. Please log in.",
        );
      }
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final decodedResponse = json.decode(response.body);
      
      return ApiResponse.fromJson(decodedResponse, (json) => EnrichedPost.fromJson(json));
    } catch (e) {
      return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.toString(),
        message: "Failed to get enriched post: $e",
      );
    }
  }

  // New method to delete a post
  Future<ApiResponse<String>> deletePost(String postId) async {
    final url = Uri.parse('$_baseUrl$_postsPath/delete/$postId');
    try {
      final String? token = await getToken();
      if (token == null) {
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "No authentication token found. Please log in.",
        );
      }
      
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final decodedResponse = json.decode(response.body);
      
      return ApiResponse.fromJson(decodedResponse, (json) => json.toString());
    } catch (e) {
      return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.toString(),
        message: "Failed to delete post: $e",
      );
    }
  }
    Future<ApiResponse<String>> updateTopic({
    required String topicId,
    required String title,
    required String description,
    File? logo,
  }) async {
    // This path matches your @PutMapping("/update/{id}")
    final url = Uri.parse('$_baseUrl$_topicsPath/update/$topicId');
    try {
      final String? token = await getToken();
      if (token == null) {
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name.toString(),
           message: "Not logged in."
          );
      }

      var request = http.MultipartRequest('PUT', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['title'] = title
        ..fields['description'] = description;

      if (logo != null) {
        request.files.add(await http.MultipartFile.fromPath('logo', logo.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final decodedResponse = json.decode(response.body);
      
      if (response.statusCode != 200) {
      print('UPDATE FAILED - Status: ${response.statusCode}, Body: ${response.body}');
    }

      return ApiResponse.fromJson(decodedResponse, (json) => json.toString());
    } catch (e) {
      print('EXCEPTION during topic update: $e');
      return ApiResponse(
        status:HttpStatus.INTERNAL_SERVER_ERROR.name.toString(),
        message: "Failed to update topic: $e",
        );
    }
  }

  Future<ApiResponse<String>> deleteTopic(String topicId) async {
    // This path matches your @DeleteMapping("/delete/{id}")
    final url = Uri.parse('$_baseUrl$_topicsPath/delete/$topicId');
    try {
      final String? token = await getToken();
      if (token == null) {
          return ApiResponse(
            status: HttpStatus.UNAUTHORIZED.name.toString(),
            message: "Not logged in."
          );
      }

      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

    if (response.statusCode != 200) {
      print('DELETE FAILED - Status: ${response.statusCode}, Body: ${response.body}');
    }

      final decodedResponse = json.decode(response.body);
      return ApiResponse.fromJson(decodedResponse, (json) => json.toString());
    } catch (e) {
      print('EXCEPTION during topic delete: $e');
        return ApiResponse(
          status:HttpStatus.INTERNAL_SERVER_ERROR.name.toString(),
          message: "Failed to delete topic: $e",
        );
    }
  }

  Future<ApiResponse<List<Topic>>> searchTopics(String keyword) async {
    // URL encode the keyword to handle spaces and special characters
    final encodedKeyword = Uri.encodeComponent(keyword);
    final url = Uri.parse('$_baseUrl$_topicsPath/search?keyword=$encodedKeyword');

    try {
      final String? token = await getToken();
      if (token == null) {
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "No authentication token found. Please log in.",
        );
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.body.isEmpty) {
        return ApiResponse(
          status: HttpStatus.OK.name,
          message: "No topics found for '$keyword'.",
          data: [], // Return an empty list
        );
      }

      final decodedResponse = json.decode(response.body);

      if (decodedResponse['status'] == 'OK' && decodedResponse['data'] != null) {
        final List<dynamic> topicJsonList = decodedResponse['data'] ?? [];
        final List<Topic> topics = topicJsonList.map((json) => Topic.fromJson(json)).toList();
        return ApiResponse(
          status: 'OK',
          message: decodedResponse['message'] ?? "Search results fetched successfully",
          data: topics
        );
      } else {
        return ApiResponse(
          status: decodedResponse['status']?.toString() ?? HttpStatus.BAD_REQUEST.name,
          message: decodedResponse['message'] ?? "Failed to search topics",
        );
      }
    } catch (e) {
      return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.name,
        message: "Failed to search topics: $e",
      );
    }
  }

Future<List<ChatConversation>> getConversations() async {
  final url = Uri.parse('$_baseUrl/api/chats');

  // 1. Get the token from secure storage
  final String? token = await getToken();
  if (token == null) {
    // Or handle this more gracefully
    throw Exception('Authentication token not found. Please log in.');
  }

  // 2. Make the authenticated request
  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // <-- THE IMPORTANT PART
    },
  );

  if (response.statusCode == 200) {
    // The backend returns a list directly, no need to check for 'status' or 'data' keys
    List<dynamic> body = jsonDecode(response.body);
    List<ChatConversation> conversations = body
        .map((dynamic item) => ChatConversation.fromJson(item))
        .toList();
    return conversations;
  } else {
    // Throw a more informative error
    throw Exception('Failed to load conversations. Status code: ${response.statusCode}');
  }
}

Future<List<UserAccount>> getAllUsers() async {
  final url = Uri.parse('$_baseUrl/api/users'); // Ensure this matches your new controller path
  final token = await getToken();

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    // 1. Decode the entire response body as a Map (a JSON object)
    Map<String, dynamic> responseBody = json.decode(response.body);

    // 2. Extract the list of users from the 'data' key
    //    We cast it to List<dynamic> to be safe.
    List<dynamic> userList = responseBody['data'] as List<dynamic>;

    // 3. Now, map the extracted list just like before
    return userList.map((dynamic item) => UserAccount.fromJson(item)).toList();
    
  } else {
    // You can even parse the error message from your ApiResponse here
    throw Exception('Failed to load users');
  }
}

Future<List<ChatMessage>> getChatHistory(String roomId) async {
  final url = Uri.parse('$_baseUrl/api/chats/$roomId/messages');
  final token = await getToken();

  final response = await http.get(url, headers: {
    'Authorization': 'Bearer $token',
  });

  if (response.statusCode == 200) {
    List<dynamic> body = json.decode(response.body);
    // You'll need a fromJson constructor in your ChatMessage model
    return body.map((dynamic item) => ChatMessage.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load chat history');
  }
}

static Future<void> warmUpServer() async {
    final String baseUrl = 'https://palliativecare-k6g2.onrender.com';
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/actuator/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15)); 

      print('Server warm-up ping succeeded: ${response.statusCode}');
    } catch (e) {
      // This will catch any type of exception, including TimeoutException
      print('Server warm-up ping completed (may have timed out, which is okay): $e');
    }
  }

   Future<ApiResponse<List<PostSummary>>> getMyPosts() async {
    final url = Uri.parse('$_baseUrl$_postsPath/my-posts');
    try {
      final String? token = await getToken();
      if (token == null) {
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "No authentication token found. Please log in.",
        );
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

        // print('Raw Response from /my-posts: ${response.body}');

      if (response.body.isEmpty) {
        return ApiResponse(
          status: HttpStatus.OK.name,
          message: "No posts found.",
          data: [], // Return an empty list
        );
      }

      final decodedResponse = json.decode(response.body);

      // Check for the 'status' and 'data' keys from your custom ApiResponse in the backend
      if (decodedResponse['status'] == 'OK' && decodedResponse['data'] != null) {
        final List<dynamic> postJsonList = decodedResponse['data'] ?? [];
        
        // Your backend returns EnrichedPostDTO, which should map to your PostSummary model
        final List<PostSummary> posts = postJsonList.map((json) => PostSummary.fromJson(json)).toList();
        
        return ApiResponse(
          status: 'OK',
          message: decodedResponse['message'] ?? "My Posts fetched successfully",
          data: posts,
        );
      } else {
        return ApiResponse(
          status: decodedResponse['status']?.toString() ?? HttpStatus.BAD_REQUEST.name,
          message: decodedResponse['message'] ?? "Failed to fetch your posts",
        );
      }
    } catch (e) {
      return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.name,
        message: "Failed to connect to the server: $e",
      );
    }
  }

    // --- Notifications ---

  // Fetches all notifications for the current user
  Future<ApiResponse<List<NotificationModel>>> getUserNotifications() async {
    final url = Uri.parse('$_baseUrl/api/notifications'); // Matches GET /api/notifications
    try {
      final String? token = await getToken();
      if (token == null){
         return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "No authentication token found. Please log in.",
        );
      }

      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      final decodedResponse = json.decode(response.body);

      if (decodedResponse['status'] == 'OK' && decodedResponse['data'] != null) {
        final List<dynamic> jsonList = decodedResponse['data'];
        final List<NotificationModel> notifications = jsonList.map((n) => NotificationModel.fromJson(n)).toList();
        return ApiResponse(
            status: HttpStatus.OK.name,
            message: "Notifications fetched.",
            data: notifications
          );
      } else {
        return ApiResponse(
          status: decodedResponse['status'],
          message: decodedResponse['message']);
      }
    } catch (e) {
      return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.name,
        message: "Failed to get notifications: $e");
    }
  }

  // Fetches the count of unread notifications
  Future<ApiResponse<int>> getUnreadCount() async {
    final url = Uri.parse('$_baseUrl/api/notifications/unread-count'); // Matches GET /api/notifications/unread-count
    try {
      final String? token = await getToken();
      if (token == null){
         return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "No authentication token found. Please log in.",
        );
      }
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      final decodedResponse = json.decode(response.body);

      if (decodedResponse['status'] == 'OK' && decodedResponse['data'] != null) {
        // The data is a simple number (long in Java -> int in Dart)
        return ApiResponse(
            status: HttpStatus.OK.name,
            message: "Count fetched.",
            data:  decodedResponse['data'] as int
          );
      } else {
        return ApiResponse(
            status: decodedResponse['status'],
            message: decodedResponse['message']
          );
      }
    } catch (e) {
      return ApiResponse(
          status: HttpStatus.INTERNAL_SERVER_ERROR.name,
          message: "Failed to get unread count: $e"
        );
    }
  }

  // Marks a single notification as read
  Future<ApiResponse<NotificationModel>> markNotificationAsRead(String notificationId) async {
    final url = Uri.parse('$_baseUrl/api/notifications/$notificationId/read'); // Matches PATCH /api/notifications/{id}/read
    try {
      final String? token = await getToken();
      if (token == null){
         return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "No authentication token found. Please log in.",
        );
      }
      final response = await http.patch(url, headers: {'Authorization': 'Bearer $token'});
      final decodedResponse = json.decode(response.body);

      if (decodedResponse['status'] == 'OK' && decodedResponse['data'] != null) {
        final notification = NotificationModel.fromJson(decodedResponse['data']);
        return ApiResponse(
            status: HttpStatus.OK.name,
            message: "Notification marked as read.",
            data: notification
          );
      } else {
        return ApiResponse(
            status: decodedResponse['status'],
            message: decodedResponse['message']
          );
      }
    } catch (e) {
      return ApiResponse(
          status: HttpStatus.INTERNAL_SERVER_ERROR.name,
          message: "Failed to mark notification as read: $e"
        );
    }
  }

Future<ApiResponse<String>> markAllNotificationsAsRead() async {
  final url = Uri.parse('$_baseUrl/api/notifications/read-all');
  try {
    final String? token = await getToken();
    if (token == null){
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message:"Not logged in."
        );
    }

    final response = await http.post(url, headers: {'Authorization': 'Bearer $token'});
    final decodedResponse = json.decode(response.body);
    
    return ApiResponse.fromJson(decodedResponse, (json) => json.toString());
  } catch (e) {
    return ApiResponse(
        status: HttpStatus.INTERNAL_SERVER_ERROR.name,
        message: "Failed to mark all as read: $e"
      );
  }
}

 // Calls the POST /api/notifications/broadcast endpoint
  Future<ApiResponse<String>> sendBroadcastNotification({
    required String title,
    required String message,
  }) async {
    final url = Uri.parse('$_baseUrl/api/notifications/broadcast');
    try {
      final String? token = await getToken();
      if (token == null){ 
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message: "Not logged in."
        );
      }
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'title': title, 'message': message}),
      );
      final decodedResponse = json.decode(response.body);
      return ApiResponse.fromJson(decodedResponse, (json) => json.toString());
    } catch (e) {
      return ApiResponse(
          status: HttpStatus.INTERNAL_SERVER_ERROR.name,
          message:  "Failed to send notification: $e"
        );
    }
  }

  // Calls the POST /api/notifications/topic/{topicId} endpoint
  Future<ApiResponse<String>> sendTopicNotification({
    required String topicId,
    required String title,
    required String message,
  }) async {
    final url = Uri.parse('$_baseUrl/api/notifications/topic/$topicId');
    try {
      final String? token = await getToken();
      if (token == null){
        return ApiResponse(
          status: HttpStatus.UNAUTHORIZED.name,
          message:  "Not logged in."
        );
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'title': title, 'message': message}),
      );
      final decodedResponse = json.decode(response.body);
      return ApiResponse.fromJson(decodedResponse, (json) => json.toString());
    } catch (e) {
      return ApiResponse(
          status: HttpStatus.INTERNAL_SERVER_ERROR.name,
          message: "Failed to send notification: $e"
        );
    }
  }

}

// Helper class to hold paginated post data
// class PostSummaryPageResponse {
//   final List<Post> posts;
//   final bool isLastPage;

//   PostSummaryPageResponse({required this.posts, required this.isLastPage});
// }


