import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../controllers/user_controller.dart';
import '../../../controllers/post_controller.dart';
import '../../../controllers/bookmark_controller.dart';
import '../../../controllers/event_controller.dart';
import '../../../controllers/event_bookmark_controller.dart';
import '../../../models/user_model.dart';
import '../../../models/post_model.dart';
import '../../../models/event_model.dart';
import '../themes/app_collors.dart';
import '../widget/post_card.dart';
import '../widget/event_card.dart';
import 'edit_profile_view.dart';
import 'post_detail_view.dart';
import 'event_detail_view.dart';
import 'login_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  final UserController _userController = UserController();
  final PostController _postController = PostController();
  final BookmarkController _bookmarkController = BookmarkController();
  final EventController _eventController = EventController();
  final EventBookmarkController _eventBookmarkController = EventBookmarkController();

  late TabController _tabController;
  UserModel? _currentUser;
  List<PostModel> _userPosts = [];
  List<PostModel> _bookmarkedPosts = [];
  List<EventModel> _bookmarkedEvents = [];
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); 
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
        });
      }
    });
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Try to get current user
      var user = await _userController.getCurrentUser();
      
      if (user == null) {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          await _userController.ensureUserDocument(firebaseUser);
          user = await _userController.getCurrentUser();
        }
      }
      
      if (user == null) {
        if (mounted) {
          _showErrorMessage("User tidak ditemukan");
          setState(() => _isLoading = false);
        }
        return;
      }

      final String userId = user.id;
      final String userName = user.name;
      final String userEmail = user.email;
      final String userBio = user.bio;
      final int userCreatedAt = user.createdAt;
      final int userUpdatedAt = user.updatedAt;

      final allPosts = await _postController.fetchPosts();
      final bookmarkedIds = await _bookmarkController.getBookmarkedPostIds();
      
      final allEvents = await _eventController.fetchEvents();
      final bookmarkedEventIds = await _eventBookmarkController.getBookmarkedEventIds();

      if (mounted) {
        setState(() {
          _currentUser = UserModel(
            id: userId,
            name: userName,
            email: userEmail,
            bio: userBio,
            createdAt: userCreatedAt,
            updatedAt: userUpdatedAt,
          );
          
          _userPosts = allPosts
              .where((post) => post.userId == userId)
              .toList();
          
          _bookmarkedPosts = allPosts
              .where((post) => bookmarkedIds.contains(post.id))
              .toList();
          
          // TAMBAHKAN: Filter bookmarked events
          _bookmarkedEvents = allEvents
              .where((event) => bookmarkedEventIds.contains(event.id))
              .toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorMessage("Gagal memuat data profil");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading ? _buildLoadingState() : _buildBody(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Memuat profil...",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        _buildProfileHeader(),
        _buildTabBar(),
        _buildTabContent(),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.cardBackground,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.grey[600], size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  const Text("Edit Profil"),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 18, color: Colors.red),
                  const SizedBox(width: 12),
                  const Text(
                    "Keluar",
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(
            bottom: BorderSide(
              color: AppColors.inputBackground.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Avatar with initial
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _currentUser?.name.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              _currentUser?.name ?? 'User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            // Email
            Text(
              _currentUser?.email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (_currentUser?.bio.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              // Bio
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.inputBackground.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  _currentUser!.bio,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Stats - TAMBAHKAN EVENT BOOKMARKS
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    label: 'Postingan Saya',
                    value: _userPosts.length.toString(),
                    icon: Icons.article_outlined,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  _buildStatItem(
                    label: 'Post Disimpan',
                    value: _bookmarkedPosts.length.toString(),
                    icon: Icons.bookmark_outline,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  _buildStatItem(
                    label: 'Event Disimpan',
                    value: _bookmarkedEvents.length.toString(),
                    icon: Icons.event_available_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Postingan Saya'),
            Tab(text: 'Post Disimpan'),
            Tab(text: 'Event Disimpan'), 
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTab == 0) {
      // Postingan Saya
      if (_userPosts.isEmpty) {
        return SliverFillRemaining(child: _buildEmptyState(0));
      }
      
      return SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PostCard(
                  post: _userPosts[index],
                  onTap: () => _navigateToPostDetail(_userPosts[index]),
                ),
              );
            },
            childCount: _userPosts.length,
          ),
        ),
      );
    } else if (_selectedTab == 1) {
      // Post Tersimpan
      if (_bookmarkedPosts.isEmpty) {
        return SliverFillRemaining(child: _buildEmptyState(1));
      }
      
      return SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PostCard(
                  post: _bookmarkedPosts[index],
                  onTap: () => _navigateToPostDetail(_bookmarkedPosts[index]),
                ),
              );
            },
            childCount: _bookmarkedPosts.length,
          ),
        ),
      );
    } else {
      // Event Tersimpan
      if (_bookmarkedEvents.isEmpty) {
        return SliverFillRemaining(child: _buildEmptyState(2));
      }
      
      return SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: EventCard(
                  event: _bookmarkedEvents[index],
                  onTap: () => _navigateToEventDetail(_bookmarkedEvents[index]),
                ),
              );
            },
            childCount: _bookmarkedEvents.length,
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState(int tabIndex) {
    IconData icon;
    String title;
    String subtitle;
    
    switch (tabIndex) {
      case 0:
        icon = Icons.article_outlined;
        title = "Belum ada postingan";
        subtitle = "Mulai berbagi pengetahuan Anda dengan komunitas";
        break;
      case 1:
        icon = Icons.bookmark_outline;
        title = "Belum ada postingan tersimpan";
        subtitle = "Simpan postingan menarik untuk dibaca nanti";
        break;
      case 2:
        icon = Icons.event_available_outlined;
        title = "Belum ada event tersimpan";
        subtitle = "Simpan event menarik untuk diikuti nanti";
        break;
      default:
        icon = Icons.inbox_outlined;
        title = "Kosong";
        subtitle = "";
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'edit':
        _navigateToEditProfile();
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_currentUser == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileView(user: _currentUser!),
      ),
    );

    if (result == true) {
      _loadUserData();
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Keluar",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          "Apakah Anda yakin ingin keluar?",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Batal",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Keluar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirebaseAuth.instance.signOut();
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginView()),
            (route) => false,
          );
        }
      } catch (e) {
        print('❌ Error during logout: $e');
        _showErrorMessage("Gagal keluar. Silakan coba lagi.");
      }
    }
  }

  Future<void> _navigateToPostDetail(PostModel post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailView(
          post: post,
          onPostUpdated: _loadUserData,
          onPostDeleted: _loadUserData,
        ),
      ),
    );
  }

  Future<void> _navigateToEventDetail(EventModel event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailView(
          event: event,
          onEventUpdated: _loadUserData,
          onEventDeleted: _loadUserData,
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.cardBackground,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}