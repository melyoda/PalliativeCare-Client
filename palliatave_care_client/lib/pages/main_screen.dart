
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
    return Scaffold(
      body: Row(
        children: [
          // Left Pane (Sidebar)
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFFF8F8F8), // Light grey background for sidebar
              child: Stack(
                children: [
                  // Scrollable content of the sidebar
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // App Logo and Title
                          Row(
                            children: [
                              Icon(Icons.favorite_border, color: Theme.of(context).primaryColor, size: 30.0),
                              const SizedBox(width: 8.0),
                              Text(
                                'PalliativeCare',
                                style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30.0),

                          // Search Topics
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Search topics...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                            ),
                            onFieldSubmitted: (value) {
                              // TODO: Implement topic search functionality
                              print('Searching for topic: $value');
                            },
                          ),
                          const SizedBox(height: 30.0),

                          // Main Navigation
                          _buildSidebarNavItem(context, Icons.star_border, 'For You', isSelected: true, onTap: () {
                            // Already on For You Page, simply close any other open pages
                            // Navigator.popUntil(context, (route) => route.isFirst); // Example for complex navigation
                          }),
                          _buildSidebarNavItem(context, Icons.grid_view, 'All Topics', onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => AllTopicsPage(userRole: _currentUserRole)));
                          }),
                          _buildSidebarNavItem(context, Icons.my_library_books, 'My Posts'),

                          // Role-based tabs
                          if (_currentUserRole == 'PATIENT')
                            _buildSidebarNavItem(context, Icons.post_add, 'Add Post to QA'), // Patient specific tab
                          if (_currentUserRole == 'DOCTOR')
                            _buildSidebarNavItem(context, Icons.chat_bubble_outline, 'Chat'), // Doctor specific tab

                          const SizedBox(height: 30.0),

                          // Subscribed Topics Section
                          const Text(
                            'Subscribed Topics',
                            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 10.0),
                          _buildSidebarTopicItem(context, 'Pain Management'), // Example subscribed topic
                          _buildSidebarTopicItem(context, 'Mindfulness & Meditation'), // Example subscribed topic
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscribedTopicsPage()));
                            },
                            child: Text(
                              'View all subscribed topics →', // Changed text for clarity
                              style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 80), // Provide space for the sticky bottom bar
                        ],
                      ),
                    ),
                  ),
                  // Sticky Bottom User Info and Logout
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, -3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Wrap content height
                        children: [
                          Divider(color: Colors.grey[300], height: 1),
                          const SizedBox(height: 10),
                          Text(
                            _currentUserName, // Display current user's name
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity, // Make button fill width
                            child: ElevatedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout, size: 20),
                              label: const Text('Logout'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent, // Red color for logout
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right Pane (Posts Feed)
          Expanded(
            flex: 3, // Give more space to the content
            child: Container(
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(BuildContext context, IconData icon, String title, {bool isSelected = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextButton.icon(
        onPressed: onTap, // Use the provided onTap callback
        icon: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700]),
        label: Text(
          title,
          style: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          backgroundColor: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildSidebarTopicItem(BuildContext context, String topicName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 15.0),
      child: InkWell(
        onTap: () {
          print('Topic "$topicName" pressed!');
          // TODO: Implement navigation to topic-specific feed
        },
        child: Text(
          '• $topicName',
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
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