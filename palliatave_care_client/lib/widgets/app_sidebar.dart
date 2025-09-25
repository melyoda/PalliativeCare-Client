import 'package:flutter/material.dart';
import 'package:palliatave_care_client/l10n.dart';

enum SidebarSection { forYou, allTopics, myPosts, addPostQA, chat, qaRequests } // Added qaRequests

class AppSidebar extends StatefulWidget  {
  final String currentUserName;
  final String userRole; // "PATIENT" or "DOCTOR"
  final VoidCallback onLogout;

  final SidebarSection selected;

  // Navigation callbacks
  final VoidCallback onOpenForYou;
  final VoidCallback onOpenAllTopics;
  final VoidCallback onOpenMyPosts;
  final VoidCallback? onOpenAddPostQA; // PATIENT only
  final VoidCallback? onOpenChat;      // DOCTOR only
  final VoidCallback onOpenSubscribedTopics; // NEW: “View all subscribed topics →”
  final VoidCallback? onOpenQARequests;
  // Optional: search + topics list
  final ValueChanged<String>? onSearchSubmitted;
  final List<String> subscribedTopics; // NEW: bullets under the heading

  const AppSidebar({
    super.key,
    required this.currentUserName,
    required this.userRole,
    required this.onLogout,
    required this.selected,
    required this.onOpenForYou,
    required this.onOpenAllTopics,
    required this.onOpenMyPosts,
    required this.onOpenSubscribedTopics,
    this.onOpenAddPostQA,
    this.onOpenChat,
    this.onSearchSubmitted,
    this.subscribedTopics = const [],
    this.onOpenQARequests,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

  class _AppSidebarState extends State<AppSidebar> {
    // ✅ 2. Add a TextEditingController
    final _searchController = TextEditingController();

    // ✅ 3. Add the dispose method to prevent memory leaks
    @override
    void dispose() {
      _searchController.dispose();
      super.dispose();
    }

    // ✅ 4. Create a helper function to trigger the search
    void _triggerSearch() {
      // Only trigger if the callback exists and text is not empty
      if (widget.onSearchSubmitted != null && _searchController.text.trim().isNotEmpty) {
        widget.onSearchSubmitted!(_searchController.text.trim());
      }
    }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                          color: Theme.of(context).primaryColor, size: 30.0),
                      const SizedBox(width: 8.0),
                      Text(
                        tr(context, 'app_title'),
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30.0),

                  TextFormField(
                    controller: _searchController, // Link the controller
                    decoration: InputDecoration(
                      labelText: tr(context, 'search_topics_hint'),
                      // Use a clickable suffixIcon instead of prefixIcon
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _triggerSearch, // Call search on tap
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    onFieldSubmitted: (value) => _triggerSearch(), // Call search on submit
                  ),
                  const SizedBox(height: 30.0),

                  _SidebarNavItem(
                    icon: Icons.star_border,
                     title: tr(context, 'for_you_title'),
                    isSelected: widget.selected == SidebarSection.forYou,
                    onTap:  widget.onOpenForYou,
                  ),
                  _SidebarNavItem(
                    icon: Icons.grid_view,
                    title: tr(context, 'all_topics_title'),
                    isSelected: widget.selected == SidebarSection.allTopics,
                    onTap: widget.onOpenAllTopics,
                  ),
                  if (widget.userRole == 'PATIENT')
                    _SidebarNavItem(
                      icon: Icons.my_library_books,
                      title: tr(context, 'my_posts_title'), // Using the page title key
                      isSelected: widget.selected == SidebarSection.myPosts,
                      onTap: widget.onOpenMyPosts,
                  ),

                   if (widget.userRole == 'DOCTOR' && widget.onOpenQARequests != null)
                    _SidebarNavItem(
                      icon: Icons.question_answer_outlined,
                      title: tr(context, 'sidebar_qa_requests'),
                      isSelected: widget.selected == SidebarSection.qaRequests,
                      onTap: widget.onOpenQARequests!,
                    ),
                  // _SidebarNavItem(
                  //   icon: Icons.my_library_books,
                  //    title: tr(context, 'sidebar_my_posts'),
                  //   isSelected: widget.selected == SidebarSection.myPosts,
                  //   onTap: widget.onOpenMyPosts,
                  // ),
                  // if (widget.userRole == 'PATIENT' && widget.onOpenAddPostQA != null)
                  //   _SidebarNavItem(
                  //     icon: Icons.post_add,
                  //      title: tr(context, 'sidebar_add_post_qa'),
                  //     isSelected: widget.selected == SidebarSection.addPostQA,
                  //     onTap: widget.onOpenAddPostQA!,
                  //   ),
                  if ((widget.userRole == 'DOCTOR' || widget.userRole == 'PATIENT') && widget.onOpenChat != null)
                  _SidebarNavItem(
                    icon: Icons.chat_bubble_outline,
                    title: tr(context, 'sidebar_chat'),
                      isSelected: widget.selected == SidebarSection.chat,
                      onTap: widget.onOpenChat!,
                  ),

                    const SizedBox(height: 30.0),
                    Text(
                      tr(context, 'sidebar_subscribed_topics'),
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10.0),

                    // Bulleted list (optional)
                    ...widget.subscribedTopics.map((t) => _SidebarTopicItem(
                      topicName: t,
                      onTap: () {}, // hook up if you want per-topic navigation
                    )),

                    // “View all subscribed topics →”
                    TextButton(
                      onPressed: widget.onOpenSubscribedTopics,
                      child: Text(
                         tr(context, 'sidebar_view_all_subscribed'),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 14,
                        ),
                      ),
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
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(color: Colors.grey[300], height: 1),
                  const SizedBox(height: 10),
                  Text(
                    widget.currentUserName,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onLogout,
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700]),
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
          backgroundColor:
              isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _SidebarTopicItem extends StatelessWidget {
  final String topicName;
  final VoidCallback onTap;
  const _SidebarTopicItem({required this.topicName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 15.0),
      child: InkWell(
        onTap: onTap,
        child: Text(
          '• $topicName',
          style: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
        ),
      ),
    );
  }
}

class SidebarScaffold extends StatelessWidget {
  final Widget sidebar;
  final Widget content;
  const SidebarScaffold({super.key, required this.sidebar, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(flex: 1, child: sidebar),
          Expanded(flex: 3, child: content),
        ],
      ),
    );
  }
}
