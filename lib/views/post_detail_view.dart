import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../controllers/post_controller.dart';
import '../../../controllers/comment_controller.dart';
import '../../../controllers/bookmark_controller.dart';
import '../../../controllers/notification_controller.dart';
import '../../../controllers/user_controller.dart';
import '../../../models/post_model.dart';
import '../../../models/comment_model.dart';
import '../themes/app_collors.dart';
import '../widget/comment_card.dart';
import '../widget/markdown_text.dart';
import 'edit_post_view.dart';

class PostDetailView extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onPostUpdated;
  final VoidCallback? onPostDeleted;

  const PostDetailView({
    super.key,
    required this.post,
    this.onPostUpdated,
    this.onPostDeleted,
  });

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  final PostController _postController = PostController();
  final CommentController _commentController = CommentController();
  final BookmarkController _bookmarkController = BookmarkController();
  final NotificationController _notificationController = NotificationController();
  final UserController _userController = UserController();
  final TextEditingController _commentTextController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();

  List<CommentModel> _comments = [];
  bool _isLoadingComments = true;
  bool _isSubmittingComment = false;
  bool _isBookmarked = false;
  bool _isLoadingBookmark = true;
  bool _isTogglingBookmark = false;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _checkBookmarkStatus();
    _loadCurrentUserName();
  }

  @override
  void dispose() {
    _commentTextController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserName() async {
    final user = await _userController.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUserName = user?.name ?? 'User';
      });
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final comments = await _commentController.getComments(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingComments = false);
        _showErrorMessage("Gagal memuat komentar");
      }
    }
  }

  Future<void> _checkBookmarkStatus() async {
    final isBookmarked = await _bookmarkController.isBookmarked(widget.post.id);
    if (mounted) {
      setState(() {
        _isBookmarked = isBookmarked;
        _isLoadingBookmark = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isTogglingBookmark) return;

    setState(() => _isTogglingBookmark = true);

    try {
      final newStatus = await _bookmarkController.toggleBookmark(widget.post.id);
      if (mounted) {
        setState(() {
          _isBookmarked = newStatus;
          _isTogglingBookmark = false;
        });

        _showSuccessMessage(
          newStatus ? 'Ditambahkan ke tersimpan' : 'Dihapus dari tersimpan',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTogglingBookmark = false);
        _showErrorMessage('Gagal mengubah status bookmark');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildCommentInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAuthor = currentUser?.uid == widget.post.userId;

    return AppBar(
      title: const Text(
        'Detail Postingan',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      backgroundColor: AppColors.cardBackground,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.grey[600], size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Bookmark button
        _buildAppBarBookmarkButton(),
        // More menu (only for author)
        if (isAuthor)
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
                    const Text("Edit Postingan"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    const SizedBox(width: 12),
                    const Text(
                      "Hapus Postingan",
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

  Widget _buildAppBarBookmarkButton() {
    if (_isLoadingBookmark) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return IconButton(
      icon: _isTogglingBookmark
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? AppColors.primary : Colors.grey[600],
            ),
      onPressed: _isTogglingBookmark ? null : _toggleBookmark,
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadComments,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostCard(),
            const SizedBox(height: 24),
            _buildCommentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.inputBackground.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(),
          const SizedBox(height: 16),
          _buildPostTitle(),
          const SizedBox(height: 12),
          _buildPostContent(),
          const SizedBox(height: 16),
          _buildPostMeta(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
  // Gunakan authorName, fallback ke email jika kosong
  final displayName = widget.post.authorName.isNotEmpty 
      ? widget.post.authorName 
      : widget.post.authorEmail;
  
  return Row(
    children: [
      Container(
        width: 40,
        height: 40,
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
        ),
        child: Center(
          child: Text(
            displayName.substring(0, 1).toUpperCase(), // ✅ Gunakan displayName
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              widget.post.formattedTime,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildPostTitle() {
    return Text(
      widget.post.title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        height: 1.3,
      ),
    );
  }

  Widget _buildPostContent() {
    return MarkdownText(
      text: widget.post.content,
      baseStyle: TextStyle(
        fontSize: 15,
        color: Colors.grey[800],
        height: 1.6,
      ),
    );
  }

  Widget _buildPostMeta() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.comment_outlined,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '${_comments.length} Komentar',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_isBookmarked) ...[
            Icon(
              Icons.bookmark,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Tersimpan',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Komentar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_comments.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoadingComments
            ? _buildLoadingComments()
            : _comments.isEmpty
                ? _buildEmptyComments()
                : _buildCommentsList(),
      ],
    );
  }

  Widget _buildLoadingComments() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildEmptyComments() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.comment_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada komentar',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Jadilah yang pertama berkomentar',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        return CommentCard(comment: _comments[index]);
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentTextController,
                focusNode: _commentFocus,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitComment(),
                decoration: InputDecoration(
                  hintText: 'Tulis komentar...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _isSubmittingComment
                ? SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: _submitComment,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitComment() async {
  final content = _commentTextController.text.trim();
  if (content.isEmpty || _isSubmittingComment) return;

  setState(() => _isSubmittingComment = true);

  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorMessage("Silakan login terlebih dahulu");
      return;
    }

    final comment = CommentModel(
      id: '',
      userId: currentUser.uid,
      userNickname: _currentUserName ?? 'User',
      content: content,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await _commentController.addComment(widget.post.id, comment);

    // Create notification for post author
    await _notificationController.createCommentNotification(
      postId: widget.post.id,
      postTitle: widget.post.title,
      postAuthorId: widget.post.userId,
      commenterId: currentUser.uid,
      commenterName: _currentUserName ?? 'User',
    );

    await _notificationController.createBookmarkCommentNotification(
      postId: widget.post.id,
      postTitle: widget.post.title,
      commenterId: currentUser.uid,
      commenterName: _currentUserName ?? 'User',
    );

    _commentTextController.clear();
    _commentFocus.unfocus();
    await _loadComments();

    if (mounted) {
      _showSuccessMessage('Komentar berhasil ditambahkan');
    }
  } catch (e) {
    _showErrorMessage('Gagal menambahkan komentar');
  } finally {
    if (mounted) {
      setState(() => _isSubmittingComment = false);
    }
  }
}

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'edit':
        _navigateToEditPost();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  Future<void> _navigateToEditPost() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditPostView(post: widget.post),
      ),
    );

    if (result == true) {
      widget.onPostUpdated?.call();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Hapus Postingan?",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          "Postingan akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.",
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
              "Hapus",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePost();
    }
  }

  Future<void> _deletePost() async {
    try {
      final success = await _postController.deletePost(widget.post.id);
      if (success && mounted) {
        widget.onPostDeleted?.call();
        Navigator.pop(context);
        _showSuccessMessage('Postingan berhasil dihapus');
      } else {
        _showErrorMessage('Gagal menghapus postingan');
      }
    } catch (e) {
      _showErrorMessage('Terjadi kesalahan saat menghapus postingan');
    }
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
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