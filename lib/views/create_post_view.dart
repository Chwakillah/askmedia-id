import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../controllers/post_controller.dart';
import '../../../models/post_model.dart';
import '../themes/app_collors.dart';
import '../widget/custom_input_field.dart';
import '../widget/rich_text_editor.dart';
import '../widget/primmary_button.dart';
import '../widget/markdown_text.dart';

class CreatePostView extends StatefulWidget {
  const CreatePostView({super.key});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final PostController _postController = PostController();
  bool _isLoading = false;
  bool _showPreview = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        "Buat Postingan",
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
        onPressed: () => Navigator.pop(context),
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
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.create,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Buat Postingan Baru",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "Bagikan ide dan pemikiran Anda dengan formatting",
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
        text: "Publikasikan",
        onPressed: _isLoading ? null : _submitPost,
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorMessage("Anda harus login terlebih dahulu");
        return;
      }

      final newPost = PostModel(
        id: '',
        userId: user.uid,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        authorEmail: user.email ?? '',
        authorName: user.displayName ?? '',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await _postController.createPost(newPost);

      if (mounted) {
        Navigator.pop(context);
        _showSuccessMessage("Postingan berhasil dipublikasikan");
      }
    } catch (error) {
      _showErrorMessage("Gagal membuat postingan. Silakan coba lagi.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}