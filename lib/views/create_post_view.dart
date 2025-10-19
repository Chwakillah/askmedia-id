import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../controllers/post_controller.dart';
import '../../../models/post_model.dart';
import '../themes/app_collors.dart';
import '../widget/custom_input_field.dart';
import '../widget/primmary_button.dart';

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
            _buildTitleField(),
            const SizedBox(height: 20),
            _buildContentField(),
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
                  "Bagikan ide dan pemikiran Anda",
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
    return CustomInputField(
      label: "Deskripsi",
      controller: _contentController,
      validator: _validateContent,
      maxLines: 6,
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