import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_model.dart';
import '../controllers/event_controller.dart';
import '../controllers/event_bookmark_controller.dart';
import '../themes/app_collors.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventDetailView extends StatefulWidget {
  final EventModel event;
  final VoidCallback? onEventUpdated;
  final VoidCallback? onEventDeleted;

  const EventDetailView({
    super.key,
    required this.event,
    this.onEventUpdated,
    this.onEventDeleted,
  });

  @override
  State<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<EventDetailView> {
  final EventController _eventController = EventController();
  final EventBookmarkController _bookmarkController = EventBookmarkController();
  
  bool _isBookmarked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final status = await _bookmarkController.isBookmarked(widget.event.id);
    if (mounted) {
      setState(() => _isBookmarked = status);
    }
  }

  Future<void> _toggleBookmark() async {
    setState(() => _isLoading = true);
    final newStatus = await _bookmarkController.toggleBookmark(widget.event.id);
    if (mounted) {
      setState(() {
        _isBookmarked = newStatus;
        _isLoading = false;
      });
      _showMessage(newStatus ? 'Event disimpan' : 'Event dihapus dari simpanan');
    }
  }

  Color _getCategoryColor() {
    switch (widget.event.category) {
      case 'webinar':
        return Colors.blue;
      case 'lomba':
        return Colors.orange;
      case 'beasiswa':
        return Colors.green;
      case 'kuisioner':
        return Colors.purple;
      case 'magang':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.event.category) {
      case 'webinar':
        return Icons.video_camera_front_rounded;
      case 'lomba':
        return Icons.emoji_events_rounded;
      case 'beasiswa':
        return Icons.school_rounded;
      case 'seminar':
        return Icons.groups_rounded;
      case 'magang':
        return Icons.work_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor();
    final isExpired = !widget.event.isRegistrationOpen;
    final isOwner = FirebaseAuth.instance.currentUser?.uid == widget.event.userId;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isOwner),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: categoryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(),
                          size: 18,
                          color: categoryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.event.categoryLabel,
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Event info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.inputBackground.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.event_rounded,
                          'Tanggal Event',
                          DateFormat('EEEE, dd MMMM yyyy')
                              .format(widget.event.eventDate),
                          Colors.blue,
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          Icons.schedule_rounded,
                          'Batas Pendaftaran',
                          DateFormat('EEEE, dd MMMM yyyy')
                              .format(widget.event.registrationDeadline),
                          isExpired ? Colors.red : Colors.green,
                        ),
                        if (widget.event.organizerName.isNotEmpty) ...[
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.apartment_rounded,
                            'Penyelenggara',
                            widget.event.organizerName,
                            Colors.purple,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Status
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isExpired
                            ? Colors.red.withOpacity(0.3)
                            : Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isExpired ? Icons.close_rounded : Icons.check_circle_rounded,
                          color: isExpired ? Colors.red[700] : Colors.green[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isExpired ? 'Pendaftaran Ditutup' : 'Pendaftaran Dibuka',
                          style: TextStyle(
                            color: isExpired ? Colors.red[700] : Colors.green[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      widget.event.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isExpired),
    );
  }

  Widget _buildAppBar(bool isOwner) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.surfaceLight,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.grey[600], size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
            color: _isBookmarked ? AppColors.primary : Colors.grey[600],
          ),
          onPressed: _isLoading ? null : _toggleBookmark,
        ),
        if (isOwner)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[600]),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    const SizedBox(width: 12),
                    const Text(
                      'Hapus Event',
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

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isExpired) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: isExpired ? null : _openRegistrationLink,
          style: ElevatedButton.styleFrom(
            backgroundColor: isExpired ? Colors.grey : AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isExpired ? Icons.close_rounded : Icons.open_in_new_rounded,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isExpired ? 'Pendaftaran Ditutup' : 'Daftar Sekarang',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openRegistrationLink() async {
    try {
      final uri = Uri.parse(widget.event.registrationLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showMessage('Tidak dapat membuka link pendaftaran');
      }
    } catch (e) {
      _showMessage('Link tidak valid');
    }
  }

  void _handleMenuSelection(String value) {
    if (value == 'delete') {
      _confirmDelete();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Hapus Event',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus event ini?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _eventController.deleteEvent(widget.event.id);
      if (mounted) {
        if (success) {
          widget.onEventDeleted?.call();
          Navigator.pop(context);
          _showMessage('Event berhasil dihapus');
        } else {
          _showMessage('Gagal menghapus event');
        }
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}