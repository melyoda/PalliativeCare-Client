import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:palliatave_care_client/l10n.dart'; 
import 'package:palliatave_care_client/models/api_response.dart';
import 'package:palliatave_care_client/models/post_summary.dart';
// import 'package:palliatave_care_client/models/resource.dart';
import 'package:palliatave_care_client/models/topic.dart';
import 'package:palliatave_care_client/models/user_account.dart';
import 'package:palliatave_care_client/pages/chat_list_screen.dart';
import 'package:palliatave_care_client/pages/login_page.dart';
import 'package:palliatave_care_client/pages/main_screen.dart';
import 'package:palliatave_care_client/pages/my_posts_page.dart';
import 'package:palliatave_care_client/pages/send_notification_page.dart';
import 'package:palliatave_care_client/pages/subbed_topics_page.dart';
import 'package:palliatave_care_client/pages/topic_search_results_page.dart';
import 'package:palliatave_care_client/services/api_service.dart';
import 'package:palliatave_care_client/util/http_status.dart';
import 'package:palliatave_care_client/widgets/info_dialog.dart';
import 'package:palliatave_care_client/widgets/post_card.dart';
import 'package:palliatave_care_client/models/post_summary_page_response.dart';
import 'package:palliatave_care_client/widgets/resource_card.dart';
import 'package:palliatave_care_client/pages/create_post_page.dart';
import 'package:palliatave_care_client/widgets/app_sidebar.dart';
import 'package:palliatave_care_client/pages/edit_topic_page.dart';
import 'package:palliatave_care_client/pages/post_details_page.dart';
import 'package:palliatave_care_client/util/app_navigator.dart';

class TopicDetailPage extends StatefulWidget {
  final Topic topic;
  final String userRole;

  const TopicDetailPage({super.key, required this.topic, required this.userRole});

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage> {
  final ApiService _apiService = ApiService();
  String _currentUserName = 'Loading User...';
  String _currentUserRole = 'Loading Role...'; // New state for user role

  String _currentUserId = '';

  bool _isSubscribed = false;

  // Pagination State
  final ScrollController _scrollController = ScrollController();
  final List<PostSummary> _topicPosts = [];
  int _currentPage = 0;
  bool _isLoadingPosts = false;
  bool _hasMorePosts = true;
  bool _isFirstLoad = true;
  static const int _pageSize = 10;


  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
    _checkSubscriptionStatus();
    _fetchTopicPosts();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 &&
          !_isLoadingPosts &&
          _hasMorePosts) {
        _fetchTopicPosts();
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
    if (userAccount != null) {
      if (mounted) {
        setState(() {
          _currentUserName = '${userAccount.firstName} ${userAccount.lastName}';
          _currentUserRole = userAccount.role;
          // ✅ NEW: stash id for PostDetailPage
          _currentUserId = userAccount.id;
        });
      }
    } else {
      _logout();
    }
  }

  Future<void> _fetchTopicPosts() async {
    if (_isLoadingPosts || !_hasMorePosts) return;

    setState(() {
      _isLoadingPosts = true;
    });

    final ApiResponse<PostSummaryPageResponse> apiResponse =
        await _apiService.getPostsByTopic(widget.topic.id, _currentPage, _pageSize);

    if (mounted) {
      if (apiResponse.status == HttpStatus.OK.name && apiResponse.data != null) {
        setState(() {
          _topicPosts.addAll(apiResponse.data!.posts);
          _hasMorePosts = !apiResponse.data!.isLastPage;
          _currentPage++;
          _isFirstLoad = false;
        });
      } else {
        await _showInfoDialog(context, apiResponse.message, title: "Error Fetching Posts", isError: true);
        setState(() {
          _isFirstLoad = false;
        });
      }
      setState(() {
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    final ApiResponse<List<String>> apiResponse = await _apiService.getSubscribedTopicIds();
    if (!mounted) return;

    if (apiResponse.status == HttpStatus.OK.name && apiResponse.data != null) {
      setState(() {
        _isSubscribed = apiResponse.data!.contains(widget.topic.id);
      });
    } else {
      // ignore: avoid_print
      print('TopicDetailPage: Failed to check subscription status: ${apiResponse.message}');
    }
  }

  Future<void> _handleSubscribe() async {
    final ApiResponse<String> apiResponse = await _apiService.registerToTopic(widget.topic.id);
    if (!mounted) return;

    if (apiResponse.status == HttpStatus.OK.name) {
      await _showInfoDialog(context, apiResponse.message, title: "Subscribed Successfully!");
      setState(() {
        _isSubscribed = true;
      });
    } else {
      await _showInfoDialog(context, apiResponse.message, title: "Subscription Failed", isError: true);
    }
  }

  Future<void> _handleUnsubscribe() async {
    final ApiResponse<String> apiResponse = await _apiService.unregisterFromTopic(widget.topic.id);
    if (!mounted) return;

    if (apiResponse.status == HttpStatus.OK.name) {
      await _showInfoDialog(context, apiResponse.message, title: "Unsubscribed Successfully!");
      setState(() {
        _isSubscribed = false;
      });
    } else {
      await _showInfoDialog(context, apiResponse.message, title: "Unsubscription Failed", isError: true);
    }
  }

  Future<void> _showInfoDialog(BuildContext context, String message, {String title = 'Information', bool isError = false}) async {
    return await showDialog(
      context: context,
      builder: (ctx) => InfoDialog(title: title, message: message, isError: isError),
    );
  }

  Future<void> _logout() async {
    await _apiService.deleteToken();
    await _apiService.deleteUserProfile();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
    }
  }


  String _formatTimeAgo(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 365) {
      return DateFormat.yMMMd().format(dateTime);
    }
    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    }
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'just now';
  }

  // ✅ NEW: simple helper to open the full post by id
  void _openPostDetail(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailPage(
          postId: postId,
          userRole: widget.userRole, // you already have this in TopicDetailPage
          userId: _currentUserId,    // pulled from secure storage
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
  // Navigate to the new EditTopicPage and wait for a result
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditTopicPage(topic: widget.topic),
    ),
  );

  // If the edit page returns `true`, it means the topic was updated, so we refresh.
  if (result == true) {
    // You will need to implement a refresh method, or simply pop
    // For now, we just pop to the previous screen
    Navigator.pop(context, true); // Pop and signal a refresh
  }
}

Future<void> _handleDelete() async {
  final bool? confirm = await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tr(context, 'confirm_deletion_title')),
      content: Text(tr(context, 'confirm_deletion_body')),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr(context, 'cancel'))),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(tr(context, 'delete'), style: const TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  // ✅ THIS PART WAS MISSING
  if (confirm != true) return; // Exit if the user cancelled

  // Show a loading indicator
  // You might want to add a state variable like `_isDeleting` to show a spinner

  final ApiResponse<String> response = await _apiService.deleteTopic(widget.topic.id);

  if (!mounted) return;

  if (response.status == HttpStatus.OK.name) {
    await _showInfoDialog(context, response.message, title: tr(context, 'success_title'));
    Navigator.pop(context, true); // Pop the page and signal to the previous page to refresh
  } else {
    await _showInfoDialog(context, response.message, title: tr(context, 'deletion_failed_title'), isError: true);
  }
}

  @override
Widget build(BuildContext context) {
  return SidebarScaffold(
    sidebar: AppSidebar(
      currentUserName: _currentUserName,
      userRole: _currentUserRole,
      onLogout: _logout,
      selected: SidebarSection.forYou,
      onOpenForYou: () => Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const ForYouPage())),
      onOpenAllTopics: () => Navigator.pop(context), // already “on” topics
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
      onOpenSubscribedTopics: () {
        Navigator.push(context,
          MaterialPageRoute(builder: (_) => SubscribedTopicsPage(userRole: _currentUserRole)));
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
                  toolbarHeight: 180,
                  backgroundColor: Colors.white,
                  automaticallyImplyLeading: true,
                     actions: [
                      if (widget.userRole == 'DOCTOR' && widget.topic.createdBy == _currentUserId) ...[
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: tr(context, 'edit_topic_tooltip'),
                          onPressed: _handleUpdate,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          tooltip: tr(context, 'delete_topic_tooltip'),
                          onPressed: _handleDelete,
                        ),
                      ],
                    ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.fromLTRB(70.0, 20.0, 90.0, 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.topic.logoUrl != null && widget.topic.logoUrl!.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12.0),
                                  child: Image.network(
                                    widget.topic.logoUrl!,
                                    height: 80, width: 80, fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(height: 80, width: 80, color: Colors.grey[200], alignment: Alignment.center, child: Icon(Icons.category, size: 40, color: Colors.grey[400])),
                                  ),
                                )
                              else
                                Container(height: 80, width: 80, color: Colors.grey[200], alignment: Alignment.center, child: Icon(Icons.category, size: 40, color: Colors.grey[400])),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.topic.title, style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    const SizedBox(height: 5.0),
                                    Text(widget.topic.description, style: TextStyle(fontSize: 16.0, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         SizedBox(
                                height: 40,
                                child: _isSubscribed
                                    ? ElevatedButton.icon(onPressed: _handleUnsubscribe, icon: const Icon(Icons.favorite_border, size: 18), label: const Text('Unsubscribe'), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16), textStyle: const TextStyle(fontSize: 14)))
                                    : ElevatedButton.icon(onPressed: _handleSubscribe, icon: const Icon(Icons.favorite, size: 18), label: const Text('Subscribe'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16), textStyle: const TextStyle(fontSize: 14))),
                              ),
                        if (widget.topic.resources.isNotEmpty) ...[
                          const Text('Topic Resources', style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 15.0),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 3 / 1.5, crossAxisSpacing: 16.0, mainAxisSpacing: 16.0),
                            itemCount: widget.topic.resources.length,
                           itemBuilder: (context, index) {
                              return ResourceCard(resource: widget.topic.resources[index]);
                            },
                          ),
                          const SizedBox(height: 30.0),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Recent Posts', style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.black87)),
                            if (widget.userRole == 'DOCTOR')
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final created = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CreatePostPage(
                                        topicId: widget.topic.id,
                                        topicName: widget.topic.title,
                                      ),
                                    ),
                                  );
                                  // if a post was created, refresh posts list
                                  if (created == true) {
                                    _currentPage = 0;
                                    _topicPosts.clear();
                                    _hasMorePosts = true;
                                    _isFirstLoad = true;
                                    await _fetchTopicPosts();
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Create Post'),
                                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), textStyle: const TextStyle(fontSize: 16)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 15.0),
                      ],
                    ),
                  ),
                ),
                if (_isFirstLoad)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_topicPosts.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text('No posts available for this topic yet.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < _topicPosts.length) {
                          final post = _topicPosts[index];
                          return PostCard(
                            authorName: '${post.author.firstName} ${post.author.lastName}',
                            authorRole: post.author.role,
                            timeAgo: _formatTimeAgo(post.creationDate),
                            topicName: post.topicInfo.title,
                            title: post.title,
                            content: "Click to read more...",
                            commentCount: post.commentsCount,
                            imageUrl: post.imageUrl,
                            // ✅ NEW: open details by id
                            onTap: () => _openPostDetail(post.id),
                          );
                        } else {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                      },
                      childCount: _topicPosts.length + (_hasMorePosts ? 1 : 0),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40.0)),
              ],
    ),
  );
}

}
