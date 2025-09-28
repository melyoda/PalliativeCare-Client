import 'package:flutter/material.dart';
import 'package:palliatave_care_client/l10n.dart';
import 'package:palliatave_care_client/models/post_summary_page_response.dart';
import 'package:palliatave_care_client/pages/my_posts_page.dart';
import 'package:palliatave_care_client/pages/send_notification_page.dart';
// import 'package:palliatave_care_client/pages/topic_detail_page.dart';
import 'package:palliatave_care_client/pages/topic_search_results_page.dart';
import 'package:palliatave_care_client/services/api_service.dart';
import 'package:palliatave_care_client/models/api_response.dart'; 
import 'package:palliatave_care_client/widgets/info_dialog.dart';
import 'package:palliatave_care_client/pages/login_page.dart';
// import 'package:palliatave_care_client/models/enriched_post.dart';
// import 'package:palliatave_care_client/models/post.dart';
import 'package:palliatave_care_client/pages/post_details_page.dart';
import 'package:palliatave_care_client/models/post_summary.dart';
import 'package:palliatave_care_client/widgets/post_card.dart';
import 'package:palliatave_care_client/util/http_status.dart'; // Import HttpStatus
import '../models/user_account.dart';
import '../pages/subbed_topics_page.dart';
import '../pages/all_topics_page.dart';
import 'package:palliatave_care_client/widgets/app_sidebar.dart';
import 'package:palliatave_care_client/pages/chat_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:palliatave_care_client/services/notification_service.dart';
import 'package:palliatave_care_client/util/app_navigator.dart';

class ForYouPage extends StatefulWidget {
  const ForYouPage({super.key});

  @override
  State<ForYouPage> createState() => _ForYouPageState();
}

class _ForYouPageState extends State<ForYouPage> {
  final ApiService _apiService = ApiService();
  final List<PostSummary> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();

  String _currentUserName = 'Loading User...';
  String _currentUserRole = 'Loading Role...';
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _loadCurrentUserData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 && _hasMore && !_isLoading) {
        _fetchPosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserData() async {
    UserAccount? userAccount = await _apiService.loadUserProfile();

    if (mounted && userAccount != null) {
      setState(() {
        _currentUserName = '${userAccount.firstName} ${userAccount.lastName}';
        _currentUserRole = userAccount.role;
        _currentUserId = userAccount.id;
      });
    } else if (mounted) {
      _logout();
    }
  }

  Future<void> _fetchPosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    final ApiResponse<PostSummaryPageResponse> apiResponse = await _apiService.getPostsFromSubscribedTopicsPaged(
      _currentPage,
      _pageSize,
    );

    if (!mounted) return;

    if (apiResponse.status == HttpStatus.OK.name && apiResponse.data != null) {
      setState(() {
        _posts.addAll(apiResponse.data!.posts);
        _currentPage++;
        if (apiResponse.data!.isLastPage) {
          _hasMore = false;
        }
        _isLoading = false;
      });
    } else if (apiResponse.status == HttpStatus.UNAUTHORIZED.name) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      if (mounted) {
        await _showInfoDialog(context, apiResponse.message, title: tr(context, 'auth_required'), isError: true); // <-- Changed
        _logout();
      }
    } else {
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      if (mounted) {
        await _showInfoDialog(context, apiResponse.message, title: tr(context, 'error_fetching_posts'), isError: true); // <-- Changed
      }
    }
  }

  Future<void> _showInfoDialog(BuildContext context, String message, {String title = 'Information', bool isError = false}) async {
    final dialogTitle = title == 'Information' ? tr(context, 'dialog_info_title') : title;
    return await showDialog(
      context: context,
      builder: (ctx) => InfoDialog(title: dialogTitle, message: message, isError: isError),
    );
  }

  Future<void> _logout() async {
    Provider.of<NotificationService>(context, listen: false).disconnect();

    await _apiService.deleteToken();
    await _apiService.deleteUserProfile();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return SidebarScaffold(
      sidebar: AppSidebar(
        currentUserName: _currentUserName,
        userRole: _currentUserRole,
        onLogout: _logout,
        selected: SidebarSection.forYou,
        onOpenForYou: () {},
        onOpenAllTopics: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AllTopicsPage(userRole: _currentUserRole)),
          );
          _refreshForYou();
        },
        onOpenMyPosts: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyPostsPage()),
        );
      },
          onOpenQARequests: () => AppNavigator.navigateToQATopic(context, _currentUserRole),
        onOpenChat: (_currentUserRole == 'DOCTOR' || _currentUserRole == 'PATIENT') ? () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatListScreen()),
          );
        } : null,
        onOpenSubscribedTopics: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SubscribedTopicsPage(userRole: _currentUserRole)),
          );
          _refreshForYou();
        },
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
      onOpenSendNotification: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SendNotificationPage()));
      },
      ),
      content: _buildForYouContent(context),
    );
  }

  Widget _buildForYouContent(BuildContext context) {
    return Container(
      color: Colors.white,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 120,
            backgroundColor: Colors.white,
            flexibleSpace: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    tr(context, 'for_you_title'), // <-- Changed
                    style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 5.0),
                  Text(
                    tr(context, 'for_you_subtitle'), // <-- Changed
                    style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < _posts.length) {
                    final s = _posts[index];
                    return PostCard(
                      authorName: '${s.author.firstName} ${s.author.lastName}',
                      authorRole: s.author.role,
                      timeAgo: _timeAgo(s.creationDate), // Uses the localized function below
                      topicName: s.topicInfo.title,
                      title: s.title,
                      content: '',
                      commentCount: s.commentsCount,
                      imageUrl: s.imageUrl,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailPage(
                              postId: s.id,
                              userRole: _currentUserRole,
                              userId: _currentUserId,
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : _hasMore
                              ? ElevatedButton(
                                  onPressed: _fetchPosts,
                                  child: Text(tr(context, 'load_more_posts')), // <-- Changed
                                )
                              : Text(tr(context, 'no_more_posts')), // <-- Changed
                    ),
                  );
                },
                childCount: _posts.length + (_hasMore || _isLoading ? 1 : 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshForYou() {
    setState(() {
      _posts.clear();
      _currentPage = 0;
      _hasMore = true;
    });
    _fetchPosts();
  }

  // This function now uses your tr() helper for localization
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

//   Future<void> _navigateToQATopic(BuildContext context) async {
//   // Show a loading indicator
//   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Finding QA Topic...')));

//   // Call your existing ApiService function
//   final response = await _apiService.getAllTopics();
  
//   if (!mounted) return;
//   ScaffoldMessenger.of(context).hideCurrentSnackBar();

//   if (response.status == HttpStatus.OK.name && response.data != null) {
//     // Assuming the Q&A topic has a known fixed ID
//     const qaTopicId = '68d4f9689432a68dd3b44d95';
    
//     try {
//       // Find the topic with the matching ID
//       final qaTopic = response.data!.firstWhere((topic) => topic.id == qaTopicId);
      
//       // Navigate to the standard TopicDetailPage
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => TopicDetailPage(
//             topic: qaTopic,
//             userRole: _currentUserRole,
//           ),
//         ),
//       );
//     } catch (e) {
//       // This error happens if the topic ID wasn't found in the list
//       _showInfoDialog(context, 'The Q&A topic could not be found. Please contact support.', title: 'Error', isError: true);
//     }
//   } else {
//     // Handle API error
//     _showInfoDialog(context, response.message, title: 'Error Fetching Topics', isError: true);
//   }
// }
}