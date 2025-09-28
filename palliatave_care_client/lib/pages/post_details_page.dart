import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:palliatave_care_client/l10n.dart';
// --- Model, Service, and Utility Imports ---
import 'package:palliatave_care_client/models/api_response.dart';
import 'package:palliatave_care_client/models/enriched_post.dart';
import 'package:palliatave_care_client/models/comment_dto.dart';
import 'package:palliatave_care_client/pages/chat_list_screen.dart';
import 'package:palliatave_care_client/pages/my_posts_page.dart';
import 'package:palliatave_care_client/pages/send_notification_page.dart';
import 'package:palliatave_care_client/pages/topic_search_results_page.dart';
import 'package:palliatave_care_client/services/api_service.dart';
import 'package:palliatave_care_client/util/http_status.dart';

// --- Widget Imports ---
import 'package:palliatave_care_client/widgets/info_dialog.dart';
import 'package:palliatave_care_client/widgets/resource_card.dart';
import 'package:palliatave_care_client/widgets/comment_card.dart';
// ✅ 1. Import the AppSidebar and SidebarScaffold
import 'package:palliatave_care_client/widgets/app_sidebar.dart';

// --- Page Imports (for navigation) ---
import 'package:palliatave_care_client/pages/login_page.dart';
import 'package:palliatave_care_client/pages/main_screen.dart'; 
import 'package:palliatave_care_client/pages/all_topics_page.dart';
import 'package:palliatave_care_client/pages/subbed_topics_page.dart';
import 'package:palliatave_care_client/util/app_navigator.dart';

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

  String _currentUserName = 'Loading User...';
  String _currentUserRole = 'Loading Role...';

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
    final ApiResponse<EnrichedPost> apiResponse = await _apiService.getEnrichedPost(widget.postId);

    if (!mounted) return;

    if (apiResponse.status == HttpStatus.OK.name && apiResponse.data != null) {
      setState(() {
        _enrichedPost = apiResponse.data!;
        _isLoading = false;
      });
    } else {
      await _showInfoDialog(context, apiResponse.message, title: tr(context, 'error_fetching_post'), isError: true); // <-- Changed
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmittingComment = true);

    final resp = await _apiService.addComment(widget.postId, CommentDTO(text: text));

    if (!mounted) return;

    if (resp.status == HttpStatus.CREATED.name || resp.status == HttpStatus.OK.name) {
      _commentCtrl.clear();
      await _fetchPostDetails();
    } else if (resp.status == HttpStatus.UNAUTHORIZED.name) {
      await _showInfoDialog(context, resp.message, title: tr(context, 'auth_required'), isError: true); // <-- Changed
      _logout();
    } else {
      await _showInfoDialog(context, resp.message, title: tr(context, 'failed_add_comment'), isError: true); // <-- Changed
    }

    if (mounted) setState(() => _isSubmittingComment = false);
  }

  Future<void> _handleDeletePost() async {
    final bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(tr(context, 'confirm_deletion_title')), // <-- Changed
            content: Text(tr(context, 'confirm_deletion_body')), // <-- Changed
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr(context, 'cancel'))), // <-- Changed
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  tr(context, 'delete'), // <-- Changed
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    final ApiResponse<String> apiResponse = await _apiService.deletePost(widget.postId);

    if (!mounted) return;

    if (apiResponse.status == HttpStatus.OK.name) {
      await _showInfoDialog(context, tr(context, 'post_deleted_success'), title: tr(context, 'success_title')); // <-- Changed
      Navigator.of(context).pop();
    } else {
      await _showInfoDialog(context, apiResponse.message, title: tr(context, 'deletion_failed_title'), isError: true); // <-- Changed
    }
  }

  Future<void> _handleUpdatePost() async {
    await _showInfoDialog(
      context,
      tr(context, 'update_not_implemented'), // <-- Changed
      title: tr(context, 'coming_soon_title'), // <-- Changed
    );
  }

  Future<void> _showInfoDialog(BuildContext context, String message, {String title = 'Information', bool isError = false}) async {
    final dialogTitle = title == 'Information' ? tr(context, 'dialog_info_title') : title;
    return await showDialog(
      context: context,
      builder: (ctx) => InfoDialog(title: dialogTitle, message: message, isError: isError),
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

  @override
  Widget build(BuildContext context) {
    return SidebarScaffold(
      sidebar: AppSidebar(
        currentUserName: _currentUserName,
        userRole: _currentUserRole,
        onLogout: _logout,
        selected: SidebarSection.forYou,
        onOpenForYou: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ForYouPage()),
          );
        },
        onOpenAllTopics: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AllTopicsPage(userRole: _currentUserRole),
            ),
          );
        },
        onOpenMyPosts: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyPostsPage()),
          );
      },
       onOpenQARequests: () => AppNavigator.navigateToQATopic(context, _currentUserRole),
        onOpenSubscribedTopics: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubscribedTopicsPage(userRole: _currentUserRole),
            ),
          );
        },
        // onOpenAddPostQA: _currentUserRole == 'PATIENT' ? () {} : null,
        onOpenChat: (_currentUserRole == 'DOCTOR' || _currentUserRole == 'PATIENT') ? () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatListScreen()),
          );
        } : null,
        subscribedTopics: [
          // tr(context, 'example_topic_pain'), // <-- Changed
          // tr(context, 'example_topic_mindfulness'), // <-- Changed
        ],
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
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    final bool isAuthor = _enrichedPost != null && _enrichedPost!.author.id == widget.userId;

    return Container(
      color: Colors.white,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enrichedPost == null
              ? Center(
                  child: Text(tr(context, 'post_not_found'), style: const TextStyle(fontSize: 16)), // <-- Changed
                )
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
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _enrichedPost!.topicInfo.title,
                                    style: const TextStyle(fontSize: 16.0, color: Colors.blueGrey),
                                  ),
                                  const Spacer(),
                                  if (isAuthor) ...[
                                    // IconButton(
                                    //   icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                    //   onPressed: _handleUpdatePost,
                                    //   tooltip: tr(context, 'edit_post_tooltip'), // <-- Changed
                                    // ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: _handleDeletePost,
                                      tooltip: tr(context, 'delete_post_tooltip'), // <-- Changed
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
                                // <-- Logic for dynamic author string
                                () {
                                  final author = _enrichedPost!.author;
                                  final when = DateFormat.yMMMd().add_jm().format(_enrichedPost!.creationDate);
                                  // Constructing the string with translated "by"
                                  return '${tr(context, 'post_author_by')} ${author.firstName} ${author.lastName} (${author.role}) • $when';
                                }(),
                                style: TextStyle(fontSize: 13.0, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20.0),
                            Text(
                              _enrichedPost!.content,
                              style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                            ),
                            if (_enrichedPost!.resources.isNotEmpty) ...[
                              const SizedBox(height: 30),
                              Text(tr(context, 'resources_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), // <-- Changed
                              const SizedBox(height: 15),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 3 / 1.5,
                                  crossAxisSpacing: 16.0,
                                  mainAxisSpacing: 16.0,
                                ),
                                itemCount: _enrichedPost!.resources.length,
                                itemBuilder: (context, index) {
                                  return ResourceCard(resource: _enrichedPost!.resources[index]);
                                },
                              ),
                            ],
                            const SizedBox(height: 30),
                            Text(tr(context, 'add_comment_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // <-- Changed
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _commentCtrl,
                                    minLines: 1,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      hintText: tr(context, 'comment_hint_text'), // <-- Changed
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: _isSubmittingComment ? null : _submitComment,
                                  icon: _isSubmittingComment
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.send),
                                  label: Text(tr(context, 'post_comment_button')), // <-- Changed
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(tr(context, 'comments_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), // <-- Changed
                                Text(
                                  '${_enrichedPost!.comments.length}',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (_enrichedPost!.comments.isEmpty)
                              Text(
                                tr(context, 'no_comments_yet'), // <-- Changed
                                style: TextStyle(color: Colors.grey[600]),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _enrichedPost!.comments.length,
                                itemBuilder: (context, i) {
                                  return CommentCard(comment: _enrichedPost!.comments[i]);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40.0)),
                  ],
                ),
    );
  }
}