import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:palliatave_care_client/models/api_response.dart';
import 'package:palliatave_care_client/models/enriched_post.dart';
import 'package:palliatave_care_client/models/comment_dto.dart';
import 'package:palliatave_care_client/services/api_service.dart';
import 'package:palliatave_care_client/util/http_status.dart';
import 'package:palliatave_care_client/widgets/info_dialog.dart';
import 'package:palliatave_care_client/widgets/resource_card.dart';
import 'package:palliatave_care_client/widgets/comment_card.dart';

import 'package:palliatave_care_client/pages/login_page.dart';
import 'package:palliatave_care_client/pages/main_screen.dart';
import 'package:palliatave_care_client/pages/all_topics_page.dart';
import 'package:palliatave_care_client/pages/subbed_topics_page.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  final String userRole;
  final String userId;

  const PostDetailPage({
    super.key,
    required this.postId,
    required this.userRole,
    required this.userId,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final ApiService _apiService = ApiService();
  EnrichedPost? _enrichedPost;
  bool _isLoading = true;

  // sidebar footer
  String _currentUserName = 'Loading User...';
  String _currentUserRole = 'Loading Role...';

  // --- comments composer ---
  final TextEditingController _commentCtrl = TextEditingController();
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
    _fetchPostDetails();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserData() async {
    final userAccount = await _apiService.loadUserProfile();
    if (!mounted) return;
    if (userAccount != null) {
      setState(() {
        _currentUserName = '${userAccount.firstName} ${userAccount.lastName}';
        _currentUserRole = userAccount.role;
      });
    } else {
      _logout();
    }
  }

  Future<void> _fetchPostDetails() async {
    setState(() => _isLoading = true);
    final ApiResponse<EnrichedPost> apiResponse =
        await _apiService.getEnrichedPost(widget.postId);

    if (!mounted) return;

    if (apiResponse.status == HttpStatus.OK.name && apiResponse.data != null) {
      setState(() {
        _enrichedPost = apiResponse.data!;
        _isLoading = false;
      });
    } else {
      await _showInfoDialog(context, apiResponse.message,
          title: "Error Fetching Post", isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmittingComment = true);

    final resp = await _apiService.addComment(
      widget.postId,
      CommentDTO(text: text),
    );

    if (!mounted) return;

    if (resp.status == HttpStatus.CREATED.name || resp.status == HttpStatus.OK.name) {
      // clear field, refetch enriched post to get fresh comments
      _commentCtrl.clear();
      await _fetchPostDetails();
    } else if (resp.status == HttpStatus.UNAUTHORIZED.name) {
      await _showInfoDialog(context, resp.message,
          title: "Authentication Required", isError: true);
      _logout();
    } else {
      await _showInfoDialog(context, resp.message,
          title: "Failed to add comment", isError: true);
    }

    if (mounted) setState(() => _isSubmittingComment = false);
  }

  Future<void> _handleDeletePost() async {
    final bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text(
                'Are you sure you want to delete this post? This action cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    final ApiResponse<String> apiResponse =
        await _apiService.deletePost(widget.postId);

    if (!mounted) return;

    if (apiResponse.status == HttpStatus.OK.name) {
      await _showInfoDialog(context, 'Post deleted successfully.',
          title: 'Success');
      Navigator.of(context).pop();
    } else {
      await _showInfoDialog(context, apiResponse.message,
          title: 'Deletion Failed', isError: true);
    }
  }

  Future<void> _handleUpdatePost() async {
    await _showInfoDialog(
      context,
      'Update functionality is not yet implemented.',
      title: 'Coming Soon',
    );
  }

  Future<void> _showInfoDialog(BuildContext context, String message,
      {String title = 'Information', bool isError = false}) async {
    return await showDialog(
      context: context,
      builder: (ctx) =>
          InfoDialog(title: title, message: message, isError: isError),
    );
  }

  Future<void> _logout() async {
    await _apiService.deleteToken();
    await _apiService.deleteUserProfile();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // Sidebar helpers
  Widget _buildSidebarNavItem(BuildContext context, IconData icon, String title,
      {bool isSelected = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon,
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[700]),
        label: Text(
          title,
          style: TextStyle(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          backgroundColor: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildSidebarTopicItem(BuildContext context, String topicName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 15.0),
      child: InkWell(
        onTap: () {},
        child: Text(
          '• $topicName',
          style: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAuthor = _enrichedPost != null &&
        _enrichedPost!.author.id == widget.userId;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFFF8F8F8),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.favorite_border,
                                  color: Theme.of(context).primaryColor,
                                  size: 30.0),
                              const SizedBox(width: 8.0),
                              Text('PalliativeCare',
                                  style: TextStyle(
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor)),
                            ],
                          ),
                          const SizedBox(height: 30.0),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Search topics...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.grey[200],
                            ),
                            onFieldSubmitted: (_) {},
                          ),
                          const SizedBox(height: 30.0),
                          _buildSidebarNavItem(context, Icons.star_border,
                              'For You', onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ForYouPage()),
                            );
                          }),
                          _buildSidebarNavItem(context, Icons.grid_view,
                              'All Topics', onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      AllTopicsPage(userRole: _currentUserRole)),
                            );
                          }),
                          _buildSidebarNavItem(
                              context, Icons.my_library_books, 'My Posts'),
                          if (widget.userRole == 'PATIENT')
                            _buildSidebarNavItem(
                                context, Icons.post_add, 'Add Post to QA'),
                          if (widget.userRole == 'DOCTOR')
                            _buildSidebarNavItem(
                                context, Icons.chat_bubble_outline, 'Chat'),
                          const SizedBox(height: 30.0),
                          const Text('Subscribed Topics',
                              style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          const SizedBox(height: 10.0),
                          _buildSidebarTopicItem(context, 'Pain Management'),
                          _buildSidebarTopicItem(
                              context, 'Mindfulness & Meditation'),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SubscribedTopicsPage()),
                              );
                            },
                            child: Text('View all subscribed topics →',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 14)),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 20.0),
                      decoration: BoxDecoration(color: Colors.white, boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, -3)),
                      ]),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Divider(color: Colors.grey[300], height: 1),
                          const SizedBox(height: 10),
                          Text(_currentUserName,
                              style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout, size: 20),
                              label: const Text('Logout'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
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

          // Content
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _enrichedPost == null
                      ? const Center(
                          child: Text('Post not found.',
                              style: TextStyle(fontSize: 16)))
                      : CustomScrollView(
                          slivers: [
                            SliverAppBar(
                              pinned: true,
                              toolbarHeight: 168,
                              backgroundColor: Colors.white,
                              leading: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              flexibleSpace: SafeArea(
                                bottom: false,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            _enrichedPost!.topicInfo.title,
                                            style: const TextStyle(
                                                fontSize: 16.0,
                                                color: Colors.blueGrey),
                                          ),
                                          const Spacer(),
                                          if (isAuthor) ...[
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  color: Colors.blueGrey),
                                              onPressed: _handleUpdatePost,
                                              tooltip: 'Edit Post',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.redAccent),
                                              onPressed: _handleDeletePost,
                                              tooltip: 'Delete Post',
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6.0),
                                      Text(
                                        _enrichedPost!.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 28.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6.0),
                                      Text(
                                        () {
                                          final a = _enrichedPost!.author;
                                          final when = DateFormat.yMMMd()
                                              .add_jm()
                                              .format(_enrichedPost!
                                                  .creationDate);
                                          return 'by ${a.firstName} ${a.lastName} (${a.role}) • $when';
                                        }(),
                                        style: TextStyle(
                                            fontSize: 13.0,
                                            color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // content + resources + comments
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20.0),
                                    Text(
                                      _enrichedPost!.content,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          height: 1.5,
                                          color: Colors.black87),
                                    ),

                                    // resources
                                    if (_enrichedPost!.resources.isNotEmpty) ...[
                                      const SizedBox(height: 30),
                                      const Text(
                                        'Resources',
                                        style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 15),
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 3 / 1.5,
                                          crossAxisSpacing: 16.0,
                                          mainAxisSpacing: 16.0,
                                        ),
                                        itemCount:
                                            _enrichedPost!.resources.length,
                                        itemBuilder: (context, index) {
                                          return ResourceCard(
                                            resource: _enrichedPost!
                                                .resources[index],
                                          );
                                        },
                                      ),
                                    ],

                                    const SizedBox(height: 30),

                                    // --- ADD COMMENT composer ---
                                    const Text(
                                      'Add a comment',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _commentCtrl,
                                            minLines: 1,
                                            maxLines: 4,
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Write your comment...',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton.icon(
                                          onPressed: _isSubmittingComment
                                              ? null
                                              : _submitComment,
                                          icon: _isSubmittingComment
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.white),
                                                  ),
                                                )
                                              : const Icon(Icons.send),
                                          label: const Text('Post'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(context)
                                                .primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 14),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // comments list
                                    const SizedBox(height: 30),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Comments',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${_enrichedPost!.comments.length}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (_enrichedPost!.comments.isEmpty)
                                      Text(
                                        'No comments yet. Be the first to comment!',
                                        style: TextStyle(
                                            color: Colors.grey[600]),
                                      )
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount:
                                            _enrichedPost!.comments.length,
                                        itemBuilder: (context, i) {
                                          final c = _enrichedPost!.comments[i];
                                          return CommentCard(comment: c);
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                                child: SizedBox(height: 40.0)),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
