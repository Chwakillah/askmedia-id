import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../controllers/post_controller.dart';
import '../../../controllers/comment_controller.dart';
import '../../../controllers/bookmark_controller.dart';
import '../../../controllers/notification_controller.dart';
import '../../../models/post_model.dart';
import '../../../models/comment_model.dart';
import '../themes/app_collors.dart';
import '../widget/comment_card.dart';
import '../widget/markdown_text.dart';
import 'edit_post_view.dart';

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
  final _focusNode = FocusNode();
  
  bool _isLoadingComments = true;
  bool _isSubmittingComment = false;
  bool _showFormattingTools = false;
  bool _isExpanded = false;
  List<CommentModel> _comments = [];
  late PostModel _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _loadComments();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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
    final isOwner = user?.uid == _currentPost.userId;

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
    final date = DateTime.fromMillisecondsSinceEpoch(_currentPost.timestamp);
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
                _currentPost.authorEmail.split('@').first,
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
      _currentPost.title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        height: 1.3,
      ),
    );
  }

  Widget _buildPostDescription() {
    return MarkdownText(
      text: _currentPost.content,
      baseStyle: TextStyle(
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showFormattingTools) _buildFormattingToolbar(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Format button
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: _showFormattingTools 
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _showFormattingTools = !_showFormattingTools;
                              });
                            },
                            icon: Icon(
                              _showFormattingTools 
                                  ? Icons.keyboard_hide 
                                  : Icons.text_format,
                              color: _showFormattingTools 
                                  ? AppColors.primary 
                                  : Colors.grey[600],
                            ),
                            tooltip: _showFormattingTools 
                                ? 'Sembunyikan Format' 
                                : 'Tampilkan Format',
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Text input
                        Expanded(
                          child: Container(
                            constraints: BoxConstraints(
                              minHeight: 50,
                              maxHeight: _isExpanded ? 200 : 120,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _focusNode.hasFocus
                                    ? AppColors.primary.withOpacity(0.3)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: TextFormField(
                              controller: _inputController,
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                hintText: "Tulis komentar Anda...",
                                hintStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                                filled: false,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                suffixIcon: _inputController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.grey[600],
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _inputController.clear();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              maxLines: null,
                              minLines: 1,
                              maxLength: 2000,
                              validator: _validateComment,
                              onChanged: (value) {
                                setState(() {});
                              },
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Send button
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          child: _buildSendButton(),
                        ),
                      ],
                    ),
                    // Expand/collapse button
                    if (_inputController.text.length > 100)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          icon: Icon(
                            _isExpanded 
                                ? Icons.unfold_less 
                                : Icons.unfold_more,
                            size: 16,
                          ),
                          label: Text(
                            _isExpanded ? 'Kecilkan' : 'Perbesar',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
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
    );
  }

  Widget _buildFormattingToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: AppColors.inputBackground.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                "Format Teks",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildToolButton(
                  icon: Icons.format_bold,
                  label: 'Bold',
                  onPressed: () => _insertMarkdown('**', '**'),
                ),
                _buildToolButton(
                  icon: Icons.format_italic,
                  label: 'Italic',
                  onPressed: () => _insertMarkdown('*', '*'),
                ),
                _buildToolButton(
                  icon: Icons.format_underlined,
                  label: 'Underline',
                  onPressed: () => _insertMarkdown('__', '__'),
                ),
                _buildToolButton(
                  icon: Icons.code,
                  label: 'Code',
                  onPressed: () => _insertMarkdown('`', '`'),
                ),
                _buildToolButton(
                  icon: Icons.format_list_bulleted,
                  label: 'List',
                  onPressed: () => _insertLinePrefix('- '),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.inputBackground.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final hasText = _inputController.text.trim().isNotEmpty;
    
    return Material(
      color: hasText 
          ? AppColors.primary 
          : Colors.grey[300],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: (_isSubmittingComment || !hasText) ? null : _submitComment,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isSubmittingComment
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : Icon(
                  Icons.send_rounded,
                  color: hasText ? Colors.white : Colors.grey[500],
                  size: 22,
                ),
        ),
      ),
    );
  }

  void _insertMarkdown(String prefix, String suffix) {
    final text = _inputController.text;
    final selection = _inputController.selection;
    
    if (selection.isValid && selection.start != selection.end) {
      final selectedText = selection.textInside(text);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      
      _inputController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length + selectedText.length + suffix.length,
        ),
      );
    } else {
      final cursorPos = selection.baseOffset;
      final newText = text.substring(0, cursorPos) + 
                      prefix + 
                      suffix + 
                      text.substring(cursorPos);
      
      _inputController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: cursorPos + prefix.length,
        ),
      );
    }
    
    _focusNode.requestFocus();
  }

  void _insertLinePrefix(String prefix) {
    final text = _inputController.text;
    final selection = _inputController.selection;
    final cursorPos = selection.baseOffset;
    
    int lineStart = text.lastIndexOf('\n', cursorPos - 1) + 1;
    
    final newText = text.substring(0, lineStart) + 
                    prefix + 
                    text.substring(lineStart);
    
    _inputController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: cursorPos + prefix.length,
      ),
    );
    
    _focusNode.requestFocus();
  }

  String? _validateComment(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Komentar tidak boleh kosong";
    }
    if (value.trim().length > 2000) {
      return "Komentar maksimal 2000 karakter";
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
      final comments = await _commentController.getComments(_currentPost.id);
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
      final nickname = user.displayName ?? user.email?.split('@').first ?? 'Anonim';
      
      final comment = CommentModel(
        id: '',
        userId: user.uid,
        userNickname: nickname,
        content: _inputController.text.trim(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await _commentController.addComment(_currentPost.id, comment);
      
      if (mounted) {
        _inputController.clear();
        setState(() {
          _showFormattingTools = false;
          _isExpanded = false;
        });
        await _loadComments();
        
        _showSuccessMessage("Komentar berhasil dikirim");
        
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

  Future<void> _handleEditPost() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditPostView(post: _currentPost),
      ),
    );

    if (result == true && mounted) {
      // Reload post data
      widget.onPostUpdated();
      _showSuccessMessage("Postingan berhasil diperbarui");
      
      // Update local post (you might want to fetch fresh data from Firestore)
      // For now, we'll trigger the parent callback
    }
  }

  Future<void> _handleDeletePost() async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    try {
      final success = await _postController.deletePost(_currentPost.id);
      
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
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}