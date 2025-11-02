import 'package:flutter/material.dart';
import '../../../controllers/bookmark_controller.dart';
import '../models/post_model.dart';
import '../themes/app_collors.dart';
import '../widget/markdown_text.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkChanged;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onBookmarkChanged,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final BookmarkController _bookmarkController = BookmarkController();
  bool _isBookmarked = false;
  bool _isLoading = true;
  bool _isTogglingBookmark = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final isBookmarked = await _bookmarkController.isBookmarked(widget.post.id);
    if (mounted) {
      setState(() {
        _isBookmarked = isBookmarked;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isTogglingBookmark) return;

    setState(() => _isTogglingBookmark = true);

    try {
      final newStatus = await _bookmarkController.toggleBookmark(
        widget.post.id,
      );
      if (mounted) {
        setState(() {
          _isBookmarked = newStatus;
          _isTogglingBookmark = false;
        });

        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newStatus ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  newStatus
                      ? 'Ditambahkan ke tersimpan'
                      : 'Dihapus dari tersimpan',
                ),
              ],
            ),
            backgroundColor: newStatus ? Colors.green[600] : Colors.grey[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );

        // Notify parent widget
        widget.onBookmarkChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTogglingBookmark = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Gagal mengubah status bookmark'),
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
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPostTitle()),
                const SizedBox(width: 12),
                _buildBookmarkButton(),
              ],
            ),
            const SizedBox(height: 12),
            _buildPostDescription(),
            const SizedBox(height: 12),
            _buildPostMeta(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostTitle() {
    return Text(
      widget.post.title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildBookmarkButton() {
    if (_isLoading) {
      return Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(8),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isTogglingBookmark ? null : _toggleBookmark,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color:
                _isBookmarked
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              _isTogglingBookmark
                  ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                  : Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    size: 20,
                    color: _isBookmarked ? AppColors.primary : Colors.grey[600],
                  ),
        ),
      ),
    );
  }

  Widget _buildPostDescription() {
    return MarkdownText(
      text: widget.post.content,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      baseStyle: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
    );
  }

  Widget _buildPostMeta() {
    return Row(
      children: [
        Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          widget.post.authorName.isNotEmpty
              ? widget.post.authorName
              : 'Pengguna',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(width: 12),
        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          widget.post.formattedTime,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
