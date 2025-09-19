
// Mock Main Screen - typically in `lib/pages/main_screen.dart`
import 'package:flutter/material.dart';
import 'package:palliatave_care_client/models/post_summary_page_response.dart';
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

  // State variable to hold the current user's name and role
  String _currentUserName = 'Loading User...';
  String _currentUserRole = 'Loading Role...'; // New state for user role
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _loadCurrentUserData(); // Load user name and role when the page initializes
    _scrollController.addListener(() {
      // Check if user has scrolled to the bottom AND there's more data to load AND not currently loading
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 && _hasMore && !_isLoading) { // Trigger slightly before end
        _fetchPosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Method to load the current user's data (name and role) from secure storage
Future<void> _loadCurrentUserData() async {
  UserAccount? userAccount = await _apiService.loadUserProfile();
  if (userAccount != null) {
    setState(() {
      _currentUserName = '${userAccount.firstName} ${userAccount.lastName}';
      _currentUserRole = userAccount.role;

      // ✅ NEW: Keep track of the userId for PostDetailPage
      _currentUserId = userAccount.id;

      print('ForYouPage: User Role Loaded: $_currentUserRole, User ID: $_currentUserId');
    });
  } else {
    // Handle case where user profile is not found (e.g., redirect to login)
    print('ForYouPage: User profile not found in secure storage. Redirecting to login.');
    _logout();
  }
}


  Future<void> _fetchPosts() async {
    if (_isLoading || !_hasMore) return; // Prevent multiple simultaneous fetches or fetching when no more data

    setState(() {
      _isLoading = true;
    });

// CHANGE 1: Correctly type the apiResponse to expect a PostPageResponse
    final ApiResponse<PostSummaryPageResponse> apiResponse = await _apiService.getPostsFromSubscribedTopicsPaged(
      _currentPage,
      _pageSize,
    );

    if (apiResponse.status == HttpStatus.OK.name && apiResponse.data != null) {
      setState(() {
        // CHANGE 2: Access the list of posts from the '.posts' property
        _posts.addAll(apiResponse.data!.posts);
        _currentPage++;

        // CHANGE 3: Use the 'isLastPage' boolean from the API for more reliable pagination logic
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
      await _showInfoDialog(context, apiResponse.message, title: "Authentication Required", isError: true);
      _logout();
    } else {
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      await _showInfoDialog(context, apiResponse.message, title: "Error Fetching Posts", isError: true);
    }
  }

  Future<void> _showInfoDialog(BuildContext context, String message, {String title = 'Information', bool isError = false}) async {
    return await showDialog(
      context: context,
      builder: (ctx) => InfoDialog(title: title, message: message, isError: isError),
    );
  }

  Future<void> _logout() async {
    await _apiService.deleteToken(); // Delete the token on logout
    await _apiService.deleteUserProfile(); // Delete the user profile on logout
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
          // 👇 when back, refresh subscribed posts
          _refreshForYou();
        },
        onOpenMyPosts: () {},
        onOpenAddPostQA: _currentUserRole == 'PATIENT' ? () {} : null,
        onOpenChat: (_currentUserRole == 'DOCTOR' || _currentUserRole == 'PATIENT')
                 ? () {
                  // This is the navigation code
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
        // optionally show bullets:
        // subscribedTopics: const ['Pain Management', 'Mindfulness & Meditation'],
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
                    pinned: true, // Makes the AppBar sticky
                    toolbarHeight: 120, // Height for title and subtitle
                    backgroundColor: Colors.white,
                    flexibleSpace: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'For You',
                            style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 5.0),
                          Text(
                            'Recent posts from your subscribed topics',
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
                          // Render posts
                          if (index < _posts.length) {
                            final s = _posts[index]; // <-- s is a PostSummary
                            return PostCard(
                              authorName: '${s.author.firstName} ${s.author.lastName}',
                              authorRole: s.author.role,
                              timeAgo: _timeAgo(s.creationDate),
                              topicName: s.topicInfo.title,
                              title: s.title,
                              content: '',              // PostSummary has no content/excerpt
                              commentCount: s.commentsCount,
                              imageUrl: s.imageUrl,
                              onTap: () {
                                 Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PostDetailPage(
                                      postId: s.id,
                                      userRole: _currentUserRole, // Doctor/Patient badge, controls edit/delete
                                      userId: _currentUserId,     // so details page can check author
                                    ),
                                  ),
                                );
                              },
                            );
                          }

                          // The loading indicator / "Load more" / end message
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: _isLoading
                                  ? const CircularProgressIndicator()
                                  : _hasMore
                                      ? ElevatedButton(
                                          onPressed: _fetchPosts,
                                          child: const Text('Load More Posts'),
                                        )
                                      : const Text('No more posts to load.'),
                            ),
                          );
                        },
                        // +1 for the tail loader/button if needed
                        childCount: _posts.length + (_hasMore ? 1 : 0),
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

}

String _timeAgo(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24)   return '${diff.inHours}h ago';
  if (diff.inDays < 7)     return '${diff.inDays}d ago';

  return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
}