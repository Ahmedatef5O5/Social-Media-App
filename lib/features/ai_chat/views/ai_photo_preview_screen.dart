import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/directional_text_field.dart';
import '../../ai_assistant/entities/ai_action_type.dart';
import '../../ai_assistant/entities/ai_request_context.dart';
import '../../ai_assistant/widgets/ai_action_icon.dart';

class AiPhotoPreviewScreen extends StatefulWidget {
  final File file;
  final String? initialCaption;
  final void Function(String? caption) onSend;

  const AiPhotoPreviewScreen({
    super.key,
    required this.file,
    this.initialCaption,
    required this.onSend,
  });

  @override
  State<AiPhotoPreviewScreen> createState() => _AiPhotoPreviewScreenState();
}

class _AiPhotoPreviewScreenState extends State<AiPhotoPreviewScreen> {
  late final TextEditingController _captionController;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(
      text: widget.initialCaption ?? '',
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final caption = _captionController.text.trim();
    Navigator.of(context).pop();
    widget.onSend(caption.isEmpty ? null : caption);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.black,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Hero(
                    tag: widget.file.path,
                    child: Image.file(widget.file, fit: BoxFit.contain),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                color: Colors.black54,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: DirectionalTextField(
                        controller: _captionController,
                        style: const TextStyle(color: AppColors.white),
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSend(),
                        decoration: InputDecoration(
                          hintText: 'Add a caption...',
                          hintStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: Colors.white24,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: AiActionIcon(
                            controller: _captionController,
                            surface: AiSurfaceType.chatMessage,
                            actionContext: AiActionContext.mediaCaption,
                            generationAction: AiActionType.autocompleteCaption,
                            hasMediaAttached: true,
                            targetMediaType: AiTargetMediaType.image,
                            imageBytesProvider: () => widget.file.readAsBytes(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: AppColors.white),
                          onPressed: _handleSend,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
