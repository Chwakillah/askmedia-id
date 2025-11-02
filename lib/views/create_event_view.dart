import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/event_controller.dart';
import '../themes/app_collors.dart';

class CreateEventView extends StatefulWidget {
  const CreateEventView({super.key});

  @override
  State<CreateEventView> createState() => _CreateEventViewState();
}

class _CreateEventViewState extends State<CreateEventView> {
  final EventController _eventController = EventController();
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _organizerController = TextEditingController();
  final _linkController = TextEditingController();
  
  String _selectedCategory = 'webinar';
  DateTime _eventDate = DateTime.now().add(const Duration(days: 7));
  DateTime _registrationDeadline = DateTime.now().add(const Duration(days: 3));
  bool _isSubmitting = false;

  final Map<String, String> _categoryLabels = {
    'webinar': 'Webinar',
    'lomba': 'Lomba',
    'beasiswa': 'Beasiswa',
    'kuisioner': 'Kuisioner',
    'magang': 'Magang',
  };

  final Map<String, IconData> _categoryIcons = {
    'webinar': Icons.video_camera_front_rounded,
    'lomba': Icons.emoji_events_rounded,
    'beasiswa': Icons.school_rounded,
    'kuisioner': Icons.groups_rounded,
    'magang': Icons.work_rounded,
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _organizerController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surfaceLight,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buat Event Baru',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Category selection
            const Text(
              'Kategori Event',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildCategorySelector(),
            
            const SizedBox(height: 24),
            
            // Title
            _buildTextField(
              controller: _titleController,
              label: 'Judul Event',
              hint: 'Masukkan judul event',
              icon: Icons.title_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Judul tidak boleh kosong';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Organizer
            _buildTextField(
              controller: _organizerController,
              label: 'Penyelenggara',
              hint: 'Nama organisasi/institusi',
              icon: Icons.apartment_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Penyelenggara tidak boleh kosong';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Deskripsi',
              hint: 'Jelaskan detail event',
              icon: Icons.description_rounded,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Deskripsi tidak boleh kosong';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Event date
            _buildDatePicker(
              label: 'Tanggal Event',
              date: _eventDate,
              icon: Icons.event_rounded,
              onTap: () => _selectDate(true),
            ),
            
            const SizedBox(height: 20),
            
            // Registration deadline
            _buildDatePicker(
              label: 'Batas Pendaftaran',
              date: _registrationDeadline,
              icon: Icons.schedule_rounded,
              onTap: () => _selectDate(false),
            ),
            
            const SizedBox(height: 20),
            
            // Registration link
            _buildTextField(
              controller: _linkController,
              label: 'Link Pendaftaran',
              hint: 'https://example.com/register',
              icon: Icons.link_rounded,
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Link pendaftaran tidak boleh kosong';
                }
                if (!value.startsWith('http')) {
                  return 'Link harus diawali dengan http:// atau https://';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
            
            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Buat Event',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.inputBackground.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _categoryLabels.entries.map((entry) {
          final isSelected = entry.key == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = entry.key),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.inputBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.inputBorder,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _categoryIcons[entry.key],
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.value,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.inputBackground.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.inputBorder,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.inputBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inputBackground.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.inputBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd MMMM yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.grey[400],
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isEventDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEventDate ? _eventDate : _registrationDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isEventDate) {
          _eventDate = picked;
          if (_registrationDeadline.isAfter(_eventDate)) {
            _registrationDeadline = _eventDate.subtract(const Duration(days: 1));
          }
        } else {
          _registrationDeadline = picked;
        }
      });
    }
  }

  Future<void> _submitEvent() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      _showMessage('Mohon lengkapi semua field dengan benar');
      return;
    }

    // Validate dates
    if (_registrationDeadline.isAfter(_eventDate)) {
      _showMessage('Batas pendaftaran harus sebelum tanggal event');
      return;
    }

    if (_registrationDeadline.isBefore(DateTime.now())) {
      _showMessage('Batas pendaftaran tidak boleh di masa lalu');
      return;
    }

    setState(() => _isSubmitting = true);

    try {

      final eventId = await _eventController.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        registrationLink: _linkController.text.trim(),
        organizerName: _organizerController.text.trim(),
        eventDate: _eventDate,
        registrationDeadline: _registrationDeadline,
      );


      if (mounted) {
        setState(() => _isSubmitting = false);
        
        if (eventId != null && eventId.isNotEmpty) {
          Navigator.pop(context);
          _showMessage('Event berhasil dibuat');
        } else {
          _showMessage('Gagal membuat event. Silakan coba lagi.');
        }
      }
    } catch (e, stackTrace) {
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showMessage('Terjadi kesalahan: ${e.toString()}');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}