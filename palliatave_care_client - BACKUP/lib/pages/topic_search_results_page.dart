// In lib/pages/topic_search_results_page.dart

import 'package:flutter/material.dart';
import 'package:palliatave_care_client/models/api_response.dart';
import 'package:palliatave_care_client/models/topic.dart';
import 'package:palliatave_care_client/models/user_account.dart';
import 'package:palliatave_care_client/pages/login_page.dart';
import 'package:palliatave_care_client/pages/topic_detail_page.dart';
import 'package:palliatave_care_client/services/api_service.dart';
import 'package:palliatave_care_client/util/http_status.dart';
import 'package:palliatave_care_client/widgets/app_sidebar.dart';
import 'package:palliatave_care_client/widgets/info_dialog.dart';

class TopicSearchResultsPage extends StatefulWidget {
  final String searchKeyword;
  final String userRole;

  const TopicSearchResultsPage({
    super.key,
    required this.searchKeyword,
    required this.userRole,
  });

  @override
  State<TopicSearchResultsPage> createState() => _TopicSearchResultsPageState();
}

class _TopicSearchResultsPageState extends State<TopicSearchResultsPage> {
  final ApiService _apiService = ApiService();
  List<Topic> _foundTopics = [];
  bool _isLoading = true;
  String _currentUserName = 'Loading...';
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
    _performSearch();
  }
  
  Future<void> _loadCurrentUserData() async {
    UserAccount? userAccount = await _apiService.loadUserProfile();
    if (userAccount != null && mounted) {
      setState(() {
        _currentUserName = '${userAccount.firstName} ${userAccount.lastName}';
        _currentUserId = userAccount.id;
      });
    } else {
      _logout();
    }
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    final ApiResponse<List<Topic>> response = await _apiService.searchTopics(widget.searchKeyword);

    if (mounted) {
      if (response.status == HttpStatus.OK.name && response.data != null) {
        setState(() {
          _foundTopics = response.data!;
          _isLoading = false;
        });
      } else {
        await showDialog(
          context: context,
          builder: (ctx) => InfoDialog(
            title: "Search Error",
            message: response.message,
            isError: true,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
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
  
  void _navigateToTopicDetail(Topic topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicDetailPage(
          topic: topic,
          userRole: widget.userRole,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SidebarScaffold(
      sidebar: AppSidebar(
        currentUserName: _currentUserName,
        userRole: widget.userRole,
        onLogout: _logout,
        selected: SidebarSection.allTopics,
        onOpenForYou: () { /* TODO */ },
        onOpenAllTopics: () => Navigator.pop(context),
        onOpenMyPosts: () { /* TODO */ },
        onOpenSubscribedTopics: () { /* TODO */ },
        onSearchSubmitted: (query) {
          if (query.trim().isNotEmpty) {
            Navigator.pushReplacement( // Use pushReplacement to avoid stacking search pages
              context,
              MaterialPageRoute(
                builder: (_) => TopicSearchResultsPage(
                  searchKeyword: query.trim(),
                  userRole: widget.userRole,
                ),
              ),
            );
          }
        },
      ),
      content: _buildResultsContent(),
    );
  }

  Widget _buildResultsContent() {
    return Container(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            title: Text(
              'Results for "${widget.searchKeyword}"',
              style: const TextStyle(color: Colors.black87),
            ),
            iconTheme: const IconThemeData(color: Colors.black87),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_foundTopics.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No topics found matching your search.'),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final topic = _foundTopics[index];
                  return ListTile(
                    leading: topic.logoUrl != null
                        ? CircleAvatar(backgroundImage: NetworkImage(topic.logoUrl!))
                        : const CircleAvatar(child: Icon(Icons.category)),
                    title: Text(topic.title),
                    subtitle: Text(topic.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => _navigateToTopicDetail(topic),
                  );
                },
                childCount: _foundTopics.length,
              ),
            ),
        ],
      ),
    );
  }
}