import 'package:flutter/material.dart';

enum SidebarSection { forYou, allTopics, myPosts, addPostQA, chat }

class AppSidebar extends StatelessWidget {
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
  });

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
                    onFieldSubmitted: onSearchSubmitted,
                  ),
                  const SizedBox(height: 30.0),

                  _SidebarNavItem(
                    icon: Icons.star_border,
                    title: 'For You',
                    isSelected: selected == SidebarSection.forYou,
                    onTap: onOpenForYou,
                  ),
                  _SidebarNavItem(
                    icon: Icons.grid_view,
                    title: 'All Topics',
                    isSelected: selected == SidebarSection.allTopics,
                    onTap: onOpenAllTopics,
                  ),
                  _SidebarNavItem(
                    icon: Icons.my_library_books,
                    title: 'My Posts',
                    isSelected: selected == SidebarSection.myPosts,
                    onTap: onOpenMyPosts,
                  ),
                  if (userRole == 'PATIENT' && onOpenAddPostQA != null)
                    _SidebarNavItem(
                      icon: Icons.post_add,
                      title: 'Add Post to QA',
                      isSelected: selected == SidebarSection.addPostQA,
                      onTap: onOpenAddPostQA!,
                    ),
                  if ((userRole == 'DOCTOR' || userRole == 'PATIENT') && onOpenChat != null)
                  _SidebarNavItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'Chat',
                    isSelected: selected == SidebarSection.chat,
                    onTap: onOpenChat!,
                  ),

                    const SizedBox(height: 30.0),
                    const Text(
                      'Subscribed Topics',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10.0),

                    // Bulleted list (optional)
                    ...subscribedTopics.map((t) => _SidebarTopicItem(
                      topicName: t,
                      onTap: () {}, // hook up if you want per-topic navigation
                    )),

                    // “View all subscribed topics →”
                    TextButton(
                      onPressed: onOpenSubscribedTopics,
                      child: Text(
                        'View all subscribed topics →',
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
                    color: Colors.grey.withOpacity(0.1),
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
                    currentUserName,
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
                      onPressed: onLogout,
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
