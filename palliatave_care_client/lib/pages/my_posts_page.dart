// In lib/pages/my_posts_page.dart

import 'package:flutter/material.dart';
import 'package:palliatave_care_client/l10n.dart';
import 'package:palliatave_care_client/models/api_response.dart';
import 'package:palliatave_care_client/models/post_summary.dart';
import 'package:palliatave_care_client/models/user_account.dart';
import 'package:palliatave_care_client/pages/all_topics_page.dart';
import 'package:palliatave_care_client/pages/chat_list_screen.dart';
import 'package:palliatave_care_client/pages/main_screen.dart';
import 'package:palliatave_care_client/pages/login_page.dart';
import 'package:palliatave_care_client/pages/post_details_page.dart';
import 'package:palliatave_care_client/pages/subbed_topics_page.dart';
import 'package:palliatave_care_client/pages/topic_search_results_page.dart';
import 'package:palliatave_care_client/services/api_service.dart';
import 'package:palliatave_care_client/util/http_status.dart';
import 'package:palliatave_care_client/widgets/app_sidebar.dart';
import 'package:palliatave_care_client/widgets/info_dialog.dart';
import 'package:palliatave_care_client/widgets/post_card.dart';
import 'package:palliatave_care_client/pages/create_post_page.dart';

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  final ApiService _apiService = ApiService();
  List<PostSummary> _myPosts = [];
  bool _isLoading = true;

  // State for sidebar data
  String _currentUserName = 'Loading...';
  String _currentUserRole = 'Loading...';
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadUserDataAndPosts();
  }

  Future<void> _loadUserDataAndPosts() async {
    // First, load the user profile
    UserAccount? userAccount = await _apiService.loadUserProfile();
    if (userAccount == null) {
      if (mounted) _logout();
      return;
    }
    
    if (mounted) {
      setState(() {
        _currentUserName = '${userAccount.firstName} ${userAccount.lastName}';
        _currentUserRole = userAccount.role;
        _currentUserId = userAccount.id;
      });
    }

    // Now, fetch the posts
    _fetchMyPosts();
  }

  Future<void> _fetchMyPosts() async {
    setState(() => _isLoading = true);

    // IMPORTANT: You will need to create this `getMyPosts` method in your ApiService
    final ApiResponse<List<PostSummary>> response = await _apiService.getMyPosts();

    if (!mounted) return;

    if (response.status == HttpStatus.OK.name && response.data != null) {
      setState(() {
        _myPosts = response.data!;
      });
    } else {
      await _showInfoDialog(context, response.message, title: tr(context, 'error_fetching_my_posts'), isError: true);
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    await _apiService.deleteToken();
    await _apiService.deleteUserProfile();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _showInfoDialog(BuildContext context, String message, {String title = 'Information', bool isError = false}) async {
    final dialogTitle = title == 'Information' ? tr(context, 'dialog_info_title') : title;
    return await showDialog(
      context: context,
      builder: (ctx) => InfoDialog(title: dialogTitle, message: message, isError: isError),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SidebarScaffold(
      sidebar: AppSidebar(
        currentUserName: _currentUserName,
        userRole: _currentUserRole,
        onLogout: _logout,
        selected: SidebarSection.myPosts, // This page is now the selected one
        onOpenForYou: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ForYouPage())),
        onOpenAllTopics: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AllTopicsPage(userRole: _currentUserRole))),
        onOpenMyPosts: () {}, // Already here, do nothing
        onOpenSubscribedTopics: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscribedTopicsPage(userRole: _currentUserRole))),
        onSearchSubmitted: (String query) {
        Navigator.push( // You can use push or pushReplacement
          context,
          MaterialPageRoute(
            builder: (context) => TopicSearchResultsPage(
              searchKeyword: query,
              userRole: _currentUserRole, // Pass the user role
            ),
          ),
        );
      },
        onOpenChat: (_currentUserRole == 'DOCTOR' || _currentUserRole == 'PATIENT') ? () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatListScreen()),
          );
        } : null,
      ),
      content: _buildMyPostsContent(),
      ),
       floatingActionButton: _currentUserRole == 'PATIENT'
        ? FloatingActionButton.extended(
            onPressed: () {
              // Navigate to the CreatePostPage with the specific QA Topic ID
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreatePostPage(
                    topicId: '68d4f9689432a68dd3b44d95', 
                    topicName: tr(context, 'qa_topic_title'),
                     isQA: true,
                  ),
                ),
              ).then((postWasCreated) {
                // If a post was successfully created, refresh the list
                if (postWasCreated == true) {
                  _fetchMyPosts();
                }
              });
            },
            icon: const Icon(Icons.add),
            label: Text(tr(context, 'sidebar_add_post_qa')), // Reusing this key
          )
        : null, // Don't show the button for doctors
    );
  }

  Widget _buildMyPostsContent() {
    return Container(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            toolbarHeight: 120,
            flexibleSpace: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    tr(context, 'my_posts_title'),
                    style: const TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_myPosts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  tr(context, 'no_posts_created_yet'),
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = _myPosts[index];
                    return PostCard(
                      authorName: '${post.author.firstName} ${post.author.lastName}',
                      authorRole: post.author.role,
                      timeAgo: _timeAgo(post.creationDate), // Reusing the timeAgo function
                      topicName: post.topicInfo.title,
                      title: post.title,
                      content: '', // Summary does not have content
                      commentCount: post.commentsCount,
                      imageUrl: post.imageUrl,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailPage(
                              postId: post.id,
                              userRole: _currentUserRole,
                              userId: _currentUserId,
                            ),
                          ),
                        ).then((didDelete) {
                          // If PostDetailPage returns true (meaning a post was deleted), refresh the list
                          if (didDelete == true) {
                            _fetchMyPosts();
                          }
                        });
                      },
                    );
                  },
                  childCount: _myPosts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper function for displaying time
  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final prefix = tr(context, 'time_ago_prefix');

    if (diff.inSeconds < 60) return '$prefix${diff.inSeconds}${tr(context, 'time_seconds_suffix')}';
    if (diff.inMinutes < 60) return '$prefix${diff.inMinutes}${tr(context, 'time_minutes_suffix')}';
    if (diff.inHours < 24) return '$prefix${diff.inHours}${tr(context, 'time_hours_suffix')}';
    if (diff.inDays < 7) return '$prefix${diff.inDays}${tr(context, 'time_days_suffix')}';

    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}