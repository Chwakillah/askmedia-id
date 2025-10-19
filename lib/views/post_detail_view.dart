import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../controllers/post_controller.dart';
import '../../../controllers/comment_controller.dart';
import '../../../models/post_model.dart';
import '../../../models/comment_model.dart';
import '../themes/app_collors.dart';
import '../widget/comment_card.dart';

class PostDetailView extends StatefulWidget {
  final PostModel post;
  final VoidCallback onPostUpdated;
  final VoidCallback onPostDeleted;

  const PostDetailView({
    super.key,
    required this.post,
    required this.onPostUpdated,
    required this.onPostDeleted,
  });

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  final _postController = PostController();
  final _commentController = CommentController();
  final _inputController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  bool _isLoadingComments = true;
  bool _isSubmittingComment = false;
  List<CommentModel> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostContent(),
                  const SizedBox(height: 24),
                  _buildCommentSection(),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user?.uid == widget.post.userId;

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
        icon: Icon(
          Icons.arrow_back_ios,
          color: Colors.grey[600],
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (isOwner) _buildPostMenu(),
      ],
    );
  }

  Widget _buildPostMenu() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Colors.grey[600],
      ),
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
    );
  }

  Widget _buildPostContent() {
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
          _buildPostDescription(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    final date = DateTime.fromMillisecondsSinceEpoch(widget.post.timestamp);
    final formattedDate = _formatPostDate(date);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.article_outlined,
            size: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.post.authorEmail.split('@').first,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                formattedDate,
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
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        height: 1.3,
      ),
    );
  }

  Widget _buildPostDescription() {
    return Text(
      widget.post.content,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[700],
        height: 1.6,
      ),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentHeader(),
        const SizedBox(height: 16),
        _buildCommentList(),
      ],
    );
  }

  Widget _buildCommentHeader() {
    return Row(
      children: [
        Icon(
          Icons.chat_bubble_outline,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          "Komentar (${_comments.length})",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentList() {
    if (_isLoadingComments) {
      return _buildLoadingIndicator();
    }

    if (_comments.isEmpty) {
      return _buildEmptyComments();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return CommentCard(comment: _comments[index]);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyComments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            "Belum ada komentar",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Jadilah yang pertama berkomentar!",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.inputBackground.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    hintText: "Tulis komentar...",
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  validator: _validateComment,
                ),
              ),
              const SizedBox(width: 12),
              _buildSendButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: _isSubmittingComment ? null : _submitComment,
        icon: _isSubmittingComment
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
      ),
    );
  }

  String? _validateComment(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Komentar tidak boleh kosong";
    }
    return null;
  }

  String _formatPostDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return "${date.day}/${date.month}/${date.year}";
    } else if (difference.inDays > 0) {
      return "${difference.inDays} hari lalu";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} jam lalu";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} menit lalu";
    } else {
      return "Baru saja";
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
    } catch (error) {
      if (mounted) {
        setState(() => _isLoadingComments = false);
        _showErrorMessage("Gagal memuat komentar");
      }
    }
  }

  Future<void> _submitComment() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorMessage("Anda harus login untuk berkomentar");
      return;
    }

    setState(() => _isSubmittingComment = true);

    try {
      // Assuming you have a way to get user nickname, 
      // for now using email prefix as nickname
      final nickname = user.displayName ?? user.email?.split('@').first ?? 'Anonim';
      
      final comment = CommentModel(
        id: '',
        userId: user.uid,
        userNickname: nickname,
        content: _inputController.text.trim(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await _commentController.addComment(widget.post.id, comment);
      
      if (mounted) {
        _inputController.clear();
        await _loadComments();
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (error) {
      _showErrorMessage("Gagal mengirim komentar");
    } finally {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'edit':
        _handleEditPost();
        break;
      case 'delete':
        _handleDeletePost();
        break;
    }
  }

  void _handleEditPost() {
    // TODO: Implement edit functionality
    _showInfoMessage("Fitur edit akan segera tersedia");
  }

  Future<void> _handleDeletePost() async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    try {
      final success = await _postController.deletePost(widget.post.id);
      
      if (success && mounted) {
        widget.onPostDeleted();
        Navigator.pop(context);
        _showSuccessMessage("Postingan berhasil dihapus");
      } else {
        _showErrorMessage("Gagal menghapus postingan");
      }
    } catch (error) {
      _showErrorMessage("Terjadi kesalahan saat menghapus postingan");
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              "Hapus Postingan",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin menghapus postingan ini? Tindakan ini tidak dapat dibatalkan.",
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
    ) ?? false;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}