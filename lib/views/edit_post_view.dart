import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../controllers/post_controller.dart';
import '../../../models/post_model.dart';
import '../themes/app_collors.dart';
import '../widget/custom_input_field.dart';
import '../widget/rich_text_editor.dart';
import '../widget/primmary_button.dart';
import '../widget/markdown_text.dart';

class EditPostView extends StatefulWidget {
  final PostModel post;

  const EditPostView({super.key, required this.post});

  @override
  State<EditPostView> createState() => _EditPostViewState();
}

class _EditPostViewState extends State<EditPostView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final PostController _postController = PostController();
  bool _isLoading = false;
  bool _showPreview = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.post.title;
    _contentController.text = widget.post.content;
    
    // Listen for changes
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Buang Perubahan?",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          "Anda memiliki perubahan yang belum disimpan. Yakin ingin keluar?",
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
              "Buang",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        "Edit Postingan",
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
          Icons.close,
          color: Colors.grey[600],
        ),
        onPressed: () async {
          if (await _onWillPop()) {
            Navigator.pop(context);
          }
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
            _showPreview ? Icons.edit : Icons.visibility,
            color: AppColors.primary,
          ),
          tooltip: _showPreview ? 'Edit' : 'Preview',
          onPressed: () {
            setState(() {
              _showPreview = !_showPreview;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormHeader(),
            const SizedBox(height: 24),
            if (_showPreview) ...[
              _buildPreview(),
            ] else ...[
              _buildTitleField(),
              const SizedBox(height: 20),
              _buildContentField(),
            ],
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Edit Postingan",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "Perbarui konten postingan Anda",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return CustomInputField(
      label: "Judul Postingan",
      controller: _titleController,
      validator: _validateTitle,
      maxLines: 2,
    );
  }

  Widget _buildContentField() {
    return RichTextEditor(
      label: "Deskripsi",
      controller: _contentController,
      validator: _validateContent,
      maxLines: 10,
      hintText: "Tulis deskripsi postingan Anda...",
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.inputBackground.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                "Preview Postingan",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Text(
            _titleController.text.isEmpty 
                ? "Judul postingan akan muncul di sini" 
                : _titleController.text,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _titleController.text.isEmpty 
                  ? Colors.grey[400] 
                  : Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          _contentController.text.isEmpty
              ? Text(
                  "Deskripsi postingan akan muncul di sini",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                    height: 1.6,
                  ),
                )
              : MarkdownText(
                  text: _contentController.text,
                  baseStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: PrimaryButton(
        text: "Simpan Perubahan",
        onPressed: (_isLoading || !_hasChanges) ? null : _submitPost,
        isLoading: _isLoading,
      ),
    );
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Judul tidak boleh kosong";
    }
    if (value.trim().length < 5) {
      return "Judul minimal 5 karakter";
    }
    if (value.trim().length > 200) {
      return "Judul maksimal 200 karakter";
    }
    return null;
  }

  String? _validateContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Deskripsi tidak boleh kosong";
    }
    if (value.trim().length < 10) {
      return "Deskripsi minimal 10 karakter";
    }
    return null;
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorMessage("Mohon lengkapi semua field dengan benar");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorMessage("Anda harus login terlebih dahulu");
      return;
    }

    if (user.uid != widget.post.userId) {
      _showErrorMessage("Anda tidak memiliki izin untuk mengedit postingan ini");
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Updating post...');
      
      final success = await _postController.updatePost(
        widget.post.id,
        _titleController.text.trim(),
        _contentController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        _showSuccessMessage("Postingan berhasil diperbarui");
      } else {
        _showErrorMessage("Gagal memperbarui postingan");
      }
    } catch (error) {
      print('Error updating post: $error');
      _showErrorMessage("Terjadi kesalahan: ${error.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        duration: const Duration(seconds: 3),
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
        duration: const Duration(seconds: 4),
      ),
    );
  }
}