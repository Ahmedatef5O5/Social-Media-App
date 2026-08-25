import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:open_filex/open_filex.dart';
import '../../../core/attachment/attachment_sheet/attachment_kind.dart';
import '../../../core/attachment/attachment_sheet/attachment_picker_sheet.dart';
import '../../../core/attachment/attachment_sheet/picked_attachment.dart';
import '../../../core/cache/repository/media_cache_repository.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/cloudinary_storage_services.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../../auth/data/models/user_data.dart';
import '../../chat_forwarding/models/forward_target_selection.dart';
import '../../chat_forwarding/models/forwardable_message.dart';
import '../../chat_forwarding/services/forward_service.dart';
import '../../chat_forwarding/views/forward_target_picker_view.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../../single_chats/helper/glass_icon_btn.dart';
import '../cubit/ai_chat_cubit/ai_chat_cubit.dart';
import '../di/ai_chat_dependencies.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_chat_session.dart';
import '../models/ai_model_option.dart';
import '../models/ai_reply_phase.dart';
import '../models/ai_suggestion_item.dart';
import '../widgets/ai_chat_greeting_header.dart';
import '../widgets/ai_chat_input_bar.dart';
import '../widgets/ai_chat_message_list.dart';
import '../widgets/ai_chat_sessions_drawer.dart';
import '../widgets/ai_chat_shimmer.dart';
import '../widgets/ai_model_selector.dart';
import '../widgets/ai_suggestion_grid.dart';
import '../widgets/syncra_backdrop.dart';
import 'ai_photo_preview_screen.dart';

String _downscaleAndEncodeImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return base64Encode(bytes);

  final needsResize = decoded.width > 1024 || decoded.height > 1024;
  final resized =
      needsResize
          ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? 1024 : null,
            height: decoded.height > decoded.width ? 1024 : null,
          )
          : decoded;

  return base64Encode(img.encodeJpg(resized, quality: 85));
}

class AiChatView extends StatefulWidget {
  final String? initialSessionId;
  final String? initialDraftText;
  final String? initialDraftImageRemoteUrl;
  final String? initialDraftImageCaption;
  final String? initialDraftImageLocalPath;
  final String? initialDraftFileLocalPath;
  final String? initialDraftFileName;

  const AiChatView({
    super.key,
    this.initialSessionId,
    this.initialDraftText,
    this.initialDraftImageRemoteUrl,
    this.initialDraftImageCaption,
    this.initialDraftImageLocalPath,
    this.initialDraftFileLocalPath,
    this.initialDraftFileName,
  });

  @override
  State<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<AiChatView> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _greetingFade;
  late final Animation<Offset> _greetingSlide;
  late final Animation<double> _gridFade;
  late final Animation<Offset> _gridSlide;
  late final AnimationController _morphController;
  late bool _showWelcome;
  late final ScrollController _scrollController;
  late final TextEditingController _textController;
  late final FocusNode _textFocusNode;
  AiModelOption _selectedModel = AiModelCatalog.defaultModel;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, dio_pkg.CancelToken> _uploadCancelTokens = {};

  // --- Live backend wiring ------------------------------------------
  AiChatDependencies? _deps;
  AiChatCubit? _chatCubit;
  String? _activeSessionId;
  bool _isUploadingImage = false;
  bool _isSendingVoice = false;
  bool _isSendingFile = false;
  File? _stagedMediaFile;
  AiChatMediaType? _stagedMediaType;
  String? _stagedFileName;
  int? _stagedFileSizeBytes;
  String? _stagedRemoteImageUrl;
  static const int _maxFileSizeBytes =
      20 * 1024 * 1024; // matches Gemini's own inline-PDF cap
  final Set<String> _historicalMessageIds = {};

  // Thinking / Analyzing / Generating cycle — driven by AiChatCubit's
  // real `isSending` flag (see _onChatStateChanged), not a fixed timer.
  AiReplyPhase? _replyPhase;
  Timer? _phaseTimer;
  bool _wasSending = false;
  static const _replyPhases = [
    AiReplyPhase.thinking,
    AiReplyPhase.analyzing,
    AiReplyPhase.generating,
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _textController = TextEditingController();
    _textFocusNode = FocusNode();
    _showWelcome = widget.initialSessionId == null;

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(_headerFade);

    _greetingFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    );
    _greetingSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(_greetingFade);

    _gridFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );
    _gridSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(_gridFade);

    _entranceController.forward();

    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    if (!_showWelcome) {
      // Reopening an existing session — skip the welcome -> chat morph
      // entirely, land directly on the message list.
      _morphController.value = 1;
    }

    if (widget.initialDraftText?.trim().isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _prefillAndFocus(widget.initialDraftText!.trim());
      });
    } else if (widget.initialDraftImageRemoteUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openForwardedPhotoPreview(widget.initialDraftImageRemoteUrl!);
        }
      });
    } else if (widget.initialDraftImageLocalPath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _stageImage(File(widget.initialDraftImageLocalPath!));
        }
      });
    } else if (widget.initialDraftFileLocalPath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final path = widget.initialDraftFileLocalPath!;
          final name = widget.initialDraftFileName ?? path.split('/').last;
          _stageFile(File(path), name);
        }
      });
    }
    _bootstrap();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _morphController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    _phaseTimer?.cancel();
    _chatCubit?.close();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final deps = await AiChatDependencies.instance();
    if (!mounted) return;
    setState(() {
      _deps = deps;
      // Hydrate the composer chip from whatever provider preference was
      // last persisted, instead of always defaulting back to Gemini.
      final savedProvider = deps.modelSelectorCubit.state.preferredProvider;
      if (savedProvider != null) {
        _selectedModel = _catalogOptionFor(savedProvider);
      }
      if (widget.initialSessionId != null) {
        _attachCubit(widget.initialSessionId!, isExisting: true);
      } else if (widget.initialDraftText?.trim().isEmpty ?? true) {
        final resumeId = deps.lastActiveSessionId;
        if (resumeId != null) {
          _showWelcome = false;
          _morphController.value = 1; // skip the welcome->chat morph
          _attachCubit(resumeId, isExisting: true);
        }
      }
    });
  }

  void _attachCubit(
    String sessionId, {
    required bool isExisting,
    AiChatSession? newlyCreatedSession,
  }) {
    final cubit = AiChatCubit(
      repository: _deps!.repository,
      gatewayService: _deps!.gatewayService,
      sessionId: sessionId,
      isExisting: isExisting,
    );
    _chatCubit = cubit;
    _activeSessionId = sessionId;

    // In-memory "resume last session" bookkeeping — see
    // AiChatDependencies.lastActiveSessionId.
    _deps?.lastActiveSessionId = sessionId;
    if (!isExisting && newlyCreatedSession != null) {
      _deps?.sessionsCubit.trackNewSession(newlyCreatedSession);
    }

    if (isExisting) {
      _historicalMessageIds
        ..clear()
        ..addAll(_deps!.repository.localMessages(sessionId).map((m) => m.id));
      cubit.loadMessages().then((_) {
        if (!mounted) return;
        final state = cubit.state;
        if (state is AiChatMessagesLoaded) {
          _historicalMessageIds
            ..clear()
            ..addAll(state.messages.map((m) => m.id));
        }
      });
    }
  }

  // ---------------------------------------------------------------------
  // Model preference <-> backend provider mapping. The composer's chip
  // only ever deals with the 3 real backend buckets (gemini/groq/
  // openrouter) — see ai_model_option.dart for why "Claude" was removed.
  // ---------------------------------------------------------------------

  String _providerStringFor(AiModelOption option) => switch (option.provider) {
    AiModelProvider.gemini => 'gemini',
    AiModelProvider.llama => 'groq',
    AiModelProvider.openrouter => 'openrouter',
  };

  AiModelOption _catalogOptionFor(String provider) => switch (provider) {
    'groq' => AiModelCatalog.all.firstWhere(
      (m) => m.provider == AiModelProvider.llama,
    ),
    'openrouter' => AiModelCatalog.all.firstWhere(
      (m) => m.provider == AiModelProvider.openrouter,
    ),
    _ => AiModelCatalog.all.firstWhere(
      (m) => m.provider == AiModelProvider.gemini,
    ),
  };

  void _onModelChanged(AiModelOption model) {
    setState(() => _selectedModel = model);
    _deps?.modelSelectorCubit.setPreferredProvider(_providerStringFor(model));
  }

  void _startConversationIfNeeded() {
    if (_chatCubit == null && _morphController.isDismissed) {
      _morphController.forward().whenCompleteOrCancel(() {
        if (mounted) setState(() => _showWelcome = false);
      });
    }
  }

  void _startNewChatInPlace() {
    _textController.clear();
    _deps?.lastActiveSessionId = null;

    if (_chatCubit == null) {
      _textFocusNode.requestFocus();
      return;
    }

    final oldCubit = _chatCubit;
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _wasSending = false;
    _replyPhase = null;

    setState(() => _showWelcome = true); // welcome fades back in immediately
    _morphController.reverse().whenCompleteOrCancel(() {
      if (!mounted) return;
      setState(() {
        _chatCubit = null;
        _activeSessionId = null;
        _historicalMessageIds.clear();
      });
      // Close AFTER the widget tree has already dropped its reference,
      // so nothing can rebuild against a closed cubit mid-transition.
      oldCubit?.close();
    });
  }

  // Sessions Drawer — Open / New chat / Delete intents bubbled up from

  void _startNewChatFromDrawer() {
    Navigator.of(context).pop(); // close the drawer
    _startNewChatInPlace();
  }

  void _openSessionFromDrawer(AiChatSession session) {
    Navigator.of(context).pop(); // close the drawer
    if (session.id == _activeSessionId) return; // already open
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacementNamed(AppRoutes.aiChatViewRoute, arguments: session.id);
  }

  Future<void> _deleteSessionFromDrawer(AiChatSession session) async {
    Navigator.of(context).pop(); // close the drawer before the dialog
    final deps = _deps;
    if (deps == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1C1D24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Delete this chat?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Delete "${session.title}"? This permanently removes it '
              "from Syncra and can't be undone.",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await deps.sessionsCubit.delete(session.id);
      if (deps.lastActiveSessionId == session.id) {
        deps.lastActiveSessionId = null;
      }
      if (session.id == _activeSessionId) {
        _startNewChatInPlace();
      }
    } catch (_) {
      if (mounted) {
        AppToast.error('Failed to delete this chat. Please try again.');
      }
    }
  }

  void _handleForward(AiChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.shortcut_rounded),
                  title: const Text('Forward'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _forwardMessage(message);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _forwardMessage(AiChatMessage message) async {
    final result = await Navigator.of(context).push<ForwardTargetSelection>(
      MaterialPageRoute(
        builder: (_) => const ForwardTargetPickerView(messageCount: 1),
      ),
    );
    if (result == null || result.isEmpty || !mounted) return;
    if (result.toAi) return; // forwarding an AI reply back into itself — n/a

    try {
      await ForwardService().forwardMessages(
        messages: [ForwardableMessage.fromAiChatMessage(message)],
        targets: result,
        currentUserId: SupabaseProvider.id,
      );
      if (mounted) AppToast.info('Forwarded to ${result.length} chat(s)');
    } catch (_) {
      if (mounted) AppToast.error('Failed to forward. Please try again.');
    }
  }

  // ---------------------------------------------------------------------
  // Suggestion taps
  // ---------------------------------------------------------------------

  void _prefillAndFocus(String text) {
    _textController.text = text;
    _textController.selection = TextSelection.collapsed(offset: text.length);
    _textFocusNode.requestFocus();
  }

  Future<void> _openFilesSuggestion() async {
    final picked = await AttachmentPickerSheet.show(
      context,
      showVoiceOption: false,
      showFileOption: true,
      showCameraOption: false,
    );
    if (picked == null || !mounted) return;
    _handleAttachmentPicked(picked);
  }

  List<AiSuggestionItem> _buildSuggestions(BuildContext context) {
    return [
      AiSuggestionItem(
        icon: Icons.image_rounded,
        label: 'Image',
        accentColor: Colors.purpleAccent,
        onTap: () => _prefillAndFocus('Create an image of '),
      ),
      AiSuggestionItem(
        icon: Icons.translate_rounded,
        label: 'Translate',
        accentColor: Colors.lightBlueAccent,
        onTap: () => _prefillAndFocus('Translate this to '),
      ),
      AiSuggestionItem(
        icon: Icons.graphic_eq_rounded,
        label: 'Audio Chat',
        accentColor: Colors.orangeAccent,
        onTap: () => _textFocusNode.requestFocus(),
      ),
      AiSuggestionItem(
        icon: Icons.description_rounded,
        label: 'Chat Files',
        accentColor: Colors.tealAccent,
        onTap: _openFilesSuggestion,
      ),
    ];
  }

  // ---------------------------------------------------------------------
  // Composer callbacks
  // ---------------------------------------------------------------------

  Future<void> _onSendText(String text) async {
    if (_stagedMediaFile != null) {
      final file = _stagedMediaFile!;
      final type = _stagedMediaType!;
      final fileName = _stagedFileName;
      final fileSizeBytes = _stagedFileSizeBytes;
      final remoteImageUrl = _stagedRemoteImageUrl;
      _removeStagedMedia();

      if (type == AiChatMediaType.image) {
        await _sendImage(file, caption: text, remoteImageUrl: remoteImageUrl);
      } else {
        await _sendFile(
          file,
          fileName: fileName ?? 'file',
          fileSizeBytes: fileSizeBytes ?? await file.length(),
          caption: text,
        );
      }
      return;
    }
    final deps = _deps;
    if (deps == null) {
      AppToast.info('Still getting Syncra ready — try again in a second.');
      return;
    }
    _scrollToBottom();
    _startConversationIfNeeded();
    try {
      if (_chatCubit == null) {
        final session = await deps.repository.createSession(firstMessage: text);
        if (!mounted) return;
        setState(
          () => _attachCubit(
            session.id,
            isExisting: false,
            newlyCreatedSession: session,
          ),
        );
      }
      await _chatCubit!.sendMessage(text: text);
    } catch (_) {
      if (mounted) {
        AppToast.error('Failed to send your message. Please try again.');
      }
    }
  }

  Future<void> _handleSendVoice(File file, int durationSeconds) async {
    if (_isSendingVoice) return;
    if (!await file.exists()) {
      AppToast.error('Voice message not found. Please try recording again.');
      return;
    }

    _scrollToBottom();
    final deps = _deps;
    if (deps == null) {
      AppToast.info('Still getting Syncra ready — try again in a second.');
      return;
    }

    setState(() => _isSendingVoice = true);

    _startConversationIfNeeded();
    if (_chatCubit == null) {
      try {
        final session = await deps.repository.createSession(
          firstMessage: '🎤 Voice message',
        );
        if (!mounted) return;
        setState(
          () => _attachCubit(
            session.id,
            isExisting: false,
            newlyCreatedSession: session,
          ),
        );
      } catch (_) {
        if (mounted) {
          AppToast.error('Failed to send the voice message. Please try again.');
          setState(() => _isSendingVoice = false);
        }
        return;
      }
    }

    final fileSizeBytes = await file.length();
    final tempId = _chatCubit!.beginOptimisticMediaMessage(
      mediaType: AiChatMediaType.voice,
      localFilePath: file.path,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
    );
    final cancelToken = dio_pkg.CancelToken();
    _uploadCancelTokens[tempId] = cancelToken;

    try {
      final uploadResult = await CloudinaryStorageServices.instance
          .uploadFile(
            file,
            'ai_chat',
            'voice',
            cancelToken: cancelToken,
            onProgress: (progress) {
              _chatCubit?.updateOptimisticProgress(tempId, progress);
            },
          )
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () => throw Exception('Upload timed out'),
          );
      _uploadCancelTokens.remove(tempId);

      if (!mounted) return;
      await _chatCubit!.sendMessage(
        text: '',
        mediaType: 'voice',
        mediaUrl: uploadResult.secureUrl,
        fileSizeBytes: fileSizeBytes,
        durationSeconds: durationSeconds,
        targetMediaType: 'voice_record',
        replacingMessageId: tempId,
      );
    } catch (e) {
      _uploadCancelTokens.remove(tempId);
      _chatCubit?.removeOptimisticMessage(tempId);
      if (e is dio_pkg.DioException &&
          dio_pkg.DioExceptionType.cancel == e.type) {
        return;
      }
      if (e.toString().contains('UploadCanceledException')) {
        return;
      }
      if (mounted) {
        AppToast.error('Failed to send the voice message. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSendingVoice = false);
    }
  }

  static const Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
    'gif',
    'bmp',
  };

  bool _looksLikeImage(String nameOrPath) {
    final dot = nameOrPath.lastIndexOf('.');
    if (dot == -1 || dot == nameOrPath.length - 1) return false;
    return _imageExtensions.contains(
      nameOrPath.substring(dot + 1).toLowerCase(),
    );
  }

  void _handleAttachmentPicked(PickedAttachment attachment) {
    if (attachment.kind == AttachmentKind.image &&
        attachment.localFile != null) {
      _stageImage(attachment.localFile!, fileName: attachment.fileName);
      return;
    }
    if (attachment.kind == AttachmentKind.file &&
        attachment.localFile != null) {
      final looksLikeImage = _looksLikeImage(
        attachment.fileName ?? attachment.localFile!.path,
      );
      if (looksLikeImage) {
        _stageImage(attachment.localFile!, fileName: attachment.fileName);
        return;
      }
      _stageFile(attachment.localFile!, attachment.fileName ?? 'file');
      return;
    }
    AppToast.info('Sharing this with Syncra is coming soon.');
  }

  Future<void> _stageImage(
    File file, {
    String? remoteImageUrl,
    String? fileName,
  }) async {
    if (!await file.exists()) {
      AppToast.error('Image file not found. Please try picking it again.');
      return;
    }
    final sizeBytes = await file.length();
    if (!mounted) return;
    setState(() {
      _stagedMediaFile = file;
      _stagedMediaType = AiChatMediaType.image;
      _stagedFileName = fileName ?? 'Photo';
      _stagedFileSizeBytes = sizeBytes;
      _stagedRemoteImageUrl = remoteImageUrl;
    });
    _textFocusNode.requestFocus();
  }

  Future<void> _stageFile(File file, String fileName) async {
    if (!await file.exists()) {
      AppToast.error('File not found. Please try picking it again.');
      return;
    }
    final sizeBytes = await file.length();
    if (sizeBytes > _maxFileSizeBytes) {
      AppToast.error("Files larger than 20MB aren't supported yet.");
      return;
    }
    if (!mounted) return;
    setState(() {
      _stagedMediaFile = file;
      _stagedMediaType = AiChatMediaType.file;
      _stagedFileName = fileName;
      _stagedFileSizeBytes = sizeBytes;
      _stagedRemoteImageUrl = null;
    });
    _textFocusNode.requestFocus();
  }

  void _removeStagedMedia() {
    setState(() {
      _stagedMediaFile = null;
      _stagedMediaType = null;
      _stagedFileName = null;
      _stagedFileSizeBytes = null;
      _stagedRemoteImageUrl = null;
    });
  }

  Future<void> _openStagedMediaPreview() async {
    final file = _stagedMediaFile;
    if (file == null) return;

    if (_stagedMediaType == AiChatMediaType.image) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => AiPhotoPreviewScreen(
                file: file,
                captionController: _textController,
              ),
        ),
      );
      return;
    }

    try {
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        AppToast.error("Couldn't open that file.");
      }
    } catch (_) {
      if (mounted) AppToast.error("Couldn't open that file.");
    }
  }

  Future<void> _sendFile(
    File file, {
    required String fileName,
    required int fileSizeBytes,
    required String caption,
  }) async {
    if (_isSendingFile) return;
    _scrollToBottom();
    final deps = _deps;
    if (deps == null) {
      AppToast.info('Still getting Syncra ready — try again in a second.');
      return;
    }

    setState(() => _isSendingFile = true);

    _startConversationIfNeeded();
    if (_chatCubit == null) {
      try {
        final session = await deps.repository.createSession(
          firstMessage: caption.isEmpty ? fileName : caption,
        );
        if (!mounted) return;
        setState(
          () => _attachCubit(
            session.id,
            isExisting: false,
            newlyCreatedSession: session,
          ),
        );
      } catch (_) {
        if (mounted) {
          AppToast.error('Failed to send the file. Please try again.');
          setState(() => _isSendingFile = false);
        }
        return;
      }
    }

    final tempId = _chatCubit!.beginOptimisticMediaMessage(
      mediaType: AiChatMediaType.file,
      caption: caption,
      localFilePath: file.path,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
    );

    try {
      final extension =
          fileName.contains('.')
              ? fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
              : '';

      String? textContent;
      String? documentBase64;
      String? targetMediaType;
      final cancelToken = dio_pkg.CancelToken();
      _uploadCancelTokens[tempId] = cancelToken;

      const textExtensions = {
        'txt',
        'md',
        'json',
        'csv',
        'tsv',
        'html',
        'htm',
        'xml',
        'yaml',
        'yml',
        'dart',
        'js',
        'ts',
        'py',
        'java',
        'c',
        'cpp',
        'cs',
        'sql',
        'sh',
        'log',
        'ini',
        'env',
        'rtf',
      };

      if (textExtensions.contains(extension)) {
        try {
          final bytes = await file.readAsBytes();
          // استخدام compute لقراءة النصوص لعدم تجميد الواجهة مع الملفات الكبيرة
          final raw = await compute(_extractPlainText, bytes);
          if (raw != null && raw.isNotEmpty) {
            textContent =
                raw.length > 25000
                    ? '${raw.substring(0, 25000)}\n\n[...تم اختصار باقي النص لكبر حجمه...]'
                    : raw;
          } else {
            targetMediaType = 'document';
          }
        } catch (_) {
          targetMediaType = 'document';
        }
      } else if (extension == 'docx' || extension == 'doc') {
        try {
          final bytes = await file.readAsBytes();
          final extracted = await compute(_extractDocxText, bytes);
          if (extracted != null && extracted.isNotEmpty) {
            textContent =
                extracted.length > 25000
                    ? '${extracted.substring(0, 25000)}\n\n[...تم اختصار باقي النص...]'
                    : extracted;
          } else {
            targetMediaType = 'document';
          }
        } catch (_) {
          targetMediaType = 'document';
        }
      } else if (extension == 'xlsx' || extension == 'xls') {
        try {
          final bytes = await file.readAsBytes();
          final extracted = await compute(_extractXlsxText, bytes);
          if (extracted != null && extracted.isNotEmpty) {
            textContent =
                extracted.length > 25000
                    ? '${extracted.substring(0, 25000)}\n\n[...تم اختصار باقي البيانات...]'
                    : extracted;
          } else {
            targetMediaType = 'document';
          }
        } catch (_) {
          targetMediaType = 'document';
        }
      } else if (extension == 'pdf') {
        final bytes = await file.readAsBytes();
        documentBase64 = await compute(base64Encode, bytes);
      } else {
        targetMediaType = 'document';
      }
      final uploadResult = await CloudinaryStorageServices.instance
          .uploadFile(
            file,
            'ai_chat',
            'files',
            cancelToken: cancelToken,
            onProgress: (progress) {
              _chatCubit?.updateOptimisticProgress(tempId, progress);
            },
          )
          .timeout(
            const Duration(seconds: 180),
            onTimeout: () => throw Exception('Upload timed out'),
          );
      _uploadCancelTokens.remove(tempId);

      if (!mounted) return;
      await context.read<MediaCacheRepository>().adoptUploadedFile(
        uploadResult.secureUrl,
        file,
      );

      if (!mounted) return;
      await _chatCubit!.sendMessage(
        text: caption,
        mediaType: 'file',
        mediaUrl: uploadResult.secureUrl,
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
        textContent: textContent,
        documentBase64: documentBase64,
        targetMediaType: targetMediaType,
        replacingMessageId: tempId,
      );
    } catch (e) {
      _uploadCancelTokens.remove(tempId);
      _chatCubit?.removeOptimisticMessage(tempId);
      if (e is dio_pkg.DioException &&
          dio_pkg.DioExceptionType.cancel == e.type) {
        return;
      }
      if (e.toString().contains('UploadCanceledException')) {
        return;
      }
      if (mounted) AppToast.error('Failed to upload. Please try again.');
    } finally {
      if (mounted) setState(() => _isSendingFile = false);
    }
  }

  Future<void> _openForwardedPhotoPreview(String remoteUrl) async {
    final localPath = await context
        .read<MediaCacheRepository>()
        .resolveLocalPath(remoteUrl);
    if (!mounted) return;
    if (localPath == null) {
      AppToast.error("Couldn't load that photo. Please try again.");
      return;
    }
    if (widget.initialDraftImageCaption != null) {
      _textController.text = widget.initialDraftImageCaption!;
    }
    await _stageImage(File(localPath), remoteImageUrl: remoteUrl);
  }

  Future<void> _sendImage(
    File file, {
    String? caption,
    String? remoteImageUrl,
  }) async {
    if (_isUploadingImage) return;
    _scrollToBottom();
    final deps = _deps;
    if (deps == null) {
      AppToast.info('Still getting Syncra ready — try again in a second.');
      return;
    }
    if (!await file.exists()) {
      AppToast.error('Image file not found. Please try picking it again.');
      return;
    }

    setState(() => _isUploadingImage = true);

    final resolvedCaption = caption ?? '';

    _startConversationIfNeeded();
    if (_chatCubit == null) {
      try {
        final session = await deps.repository.createSession(
          firstMessage: resolvedCaption.isEmpty ? '📷 Photo' : resolvedCaption,
        );
        if (!mounted) return;
        setState(
          () => _attachCubit(
            session.id,
            isExisting: false,
            newlyCreatedSession: session,
          ),
        );
      } catch (_) {
        if (mounted) {
          AppToast.error('Failed to send the photo. Please try again.');
          setState(() => _isUploadingImage = false);
        }
        return;
      }
    }

    final fileSizeBytes = await file.length();
    final tempId = _chatCubit!.beginOptimisticMediaMessage(
      mediaType: AiChatMediaType.image,
      caption: resolvedCaption,
      localFilePath: file.path,
      fileSizeBytes: fileSizeBytes,
    );

    try {
      final bytes = await file.readAsBytes();
      final imageBase64 = await compute(_downscaleAndEncodeImage, bytes);
      final String finalUrl;
      if (remoteImageUrl != null) {
        finalUrl = remoteImageUrl;
      } else {
        final uploadResult = await CloudinaryStorageServices.instance
            .uploadFile(
              file,
              'ai_chat',
              'images',
              onProgress: (progress) {
                _chatCubit?.updateOptimisticProgress(tempId, progress);
              },
            )
            .timeout(
              const Duration(seconds: 90),
              onTimeout: () => throw Exception('Upload timed out'),
            );
        finalUrl = uploadResult.secureUrl;

        if (!mounted) return;
        await context.read<MediaCacheRepository>().adoptUploadedFile(
          finalUrl,
          file,
        );
      }

      if (!mounted) return;
      await _chatCubit!.sendMessage(
        text: resolvedCaption,
        mediaType: 'image',
        mediaUrl: finalUrl,
        fileSizeBytes: bytes.length,
        imageBase64: imageBase64,
        replacingMessageId: tempId,
      );
    } catch (e) {
      _uploadCancelTokens.remove(tempId);
      _chatCubit?.removeOptimisticMessage(tempId);
      if (e is dio_pkg.DioException &&
          dio_pkg.DioExceptionType.cancel == e.type) {
        return;
      }
      if (e.toString().contains('UploadCanceledException')) {
        return;
      }
      if (mounted) {
        AppToast.error('Failed to send the photo. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _handleCancelUpload(AiChatMessage message) {
    _uploadCancelTokens[message.id]?.cancel('user_cancelled');
    _uploadCancelTokens.remove(message.id);

    _chatCubit?.removeOptimisticMessage(message.id);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleRetry(AiChatMessage message) {
    _chatCubit?.sendMessage(text: message.text);
  }

  void _onChatStateChanged(BuildContext context, AiChatMessagesState state) {
    if (state is! AiChatMessagesLoaded) return;

    if (state.isSending && !_wasSending) {
      _startPhaseCycle();
    } else if (!state.isSending && _wasSending) {
      _stopPhaseCycle();
    }
    _wasSending = state.isSending;

    if (state.error != null) {
      AppToast.error(_friendlyErrorMessage(state.error!));
    }
  }

  void _startPhaseCycle() {
    _phaseTimer?.cancel();
    var index = 0;
    setState(() => _replyPhase = _replyPhases[index]);
    _phaseTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      index = (index + 1) % _replyPhases.length;
      setState(() => _replyPhase = _replyPhases[index]);
    });
  }

  void _stopPhaseCycle() {
    _phaseTimer?.cancel();
    _phaseTimer = null;
    if (mounted) setState(() => _replyPhase = null);
  }

  String _friendlyErrorMessage(String reason) {
    switch (reason) {
      case 'user_quota_exceeded':
        return "You've reached today's Syncra limit — try again tomorrow.";
      case 'global_quota_exceeded':
        return 'Syncra is a bit busy right now — please try again shortly.';
      case 'all_providers_unavailable':
        return "Syncra couldn't reach any AI provider — please try again.";
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  Widget _buildLoadError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          "Couldn't load this conversation.\n$message",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = SyncraBackdrop.gradientColors(theme.primaryColor);
    final currentUser = context.read<HomeCubit>().currentUserData;
    final firstName =
        (currentUser?.name ?? '').trim().isEmpty
            ? 'there'
            : currentUser!.name.trim().split(' ').first;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: gradient.last,
        onDrawerChanged: ((isOpened) {
          if (isOpened) {
            _deps?.sessionsCubit.refresh();
          }
        }),
        drawer: AiChatSessionsDrawer(
          deps: _deps,
          activeSessionId: _activeSessionId,
          onStartNewChat: _startNewChatFromDrawer,
          onOpenSession: _openSessionFromDrawer,
          onDeleteSession: _deleteSessionFromDrawer,
        ),
        body: Stack(
          children: [
            Positioned.fill(child: SyncraBackdrop(primary: theme.primaryColor)),
            SafeArea(
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: _buildHeader(context),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        if (_showWelcome)
                          AnimatedBuilder(
                            animation: _morphController,
                            child: _buildWelcomeContent(
                              context,
                              firstName,
                              currentUser,
                            ),
                            builder: (context, child) {
                              final morph = _morphController.value;
                              return IgnorePointer(
                                ignoring: morph > 0.02,
                                child: Opacity(
                                  opacity: (1 - morph).clamp(0.0, 1.0),
                                  child: Transform.scale(
                                    scale: 1 - (morph * 0.06),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                          ),
                        if (_chatCubit != null)
                          AnimatedBuilder(
                            animation: _morphController,
                            child: BlocProvider.value(
                              value: _chatCubit!,
                              child: BlocConsumer<
                                AiChatCubit,
                                AiChatMessagesState
                              >(
                                listener: _onChatStateChanged,
                                builder: (context, state) {
                                  if (state is AiChatMessagesLoading) {
                                    return const AiChatMessagesShimmerList();
                                  }
                                  if (state is AiChatMessagesError) {
                                    return _buildLoadError(state.message);
                                  }
                                  final loaded = state as AiChatMessagesLoaded;
                                  return AiChatMessageList(
                                    scrollController: _scrollController,
                                    messages: loaded.messages,
                                    activePhase: _replyPhase,
                                    activeModel: _selectedModel,
                                    shouldAnimateText:
                                        (m) =>
                                            m.role == AiChatRole.assistant &&
                                            !_historicalMessageIds.contains(
                                              m.id,
                                            ),

                                    onRetry: _handleRetry,
                                    onForward: _handleForward,
                                    onCancelUpload: _handleCancelUpload,
                                  );
                                },
                              ),
                            ),
                            builder: (context, child) {
                              final morph = _morphController.value;
                              return IgnorePointer(
                                ignoring: morph < 0.98,
                                child: Opacity(
                                  opacity: morph.clamp(0.0, 1.0),
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - morph) * 16),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  SafeArea(
                    top: false,
                    child: AiChatInputBar(
                      controller: _textController,
                      focusNode: _textFocusNode,
                      selectedModel: _selectedModel,
                      onModelChanged: _onModelChanged,
                      onSendText: _onSendText,
                      onSendVoice: _handleSendVoice,
                      onAttachmentPicked: _handleAttachmentPicked,
                      stagedFileName: _stagedFileName,
                      stagedFileSizeBytes: _stagedFileSizeBytes,
                      stagedImageFile:
                          _stagedMediaType == AiChatMediaType.image
                              ? _stagedMediaFile
                              : null,
                      onRemoveStagedFile: _removeStagedMedia,
                      onTapStagedFile: _openStagedMediaPreview,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeContent(
    BuildContext context,
    String firstName,
    UserData? currentUser,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          FadeTransition(
            opacity: _greetingFade,
            child: SlideTransition(
              position: _greetingSlide,
              child: AiChatGreetingHeader(
                userName: firstName,
                avatarUrl: currentUser?.imageUrl,
              ),
            ),
          ),
          const SizedBox(height: 40),
          FadeTransition(
            opacity: _gridFade,
            child: SlideTransition(
              position: _gridSlide,
              child: AiSuggestionGrid(items: _buildSuggestions(context)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.menu_rounded,
            iconSize: 20,
            size: 42,
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),

          const Expanded(
            child: Center(
              child: Text(
                'Syncra',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),

          GlassIconButton(
            icon: _selectedModel.icon,
            iconColor: _selectedModel.accentColor,
            iconSize: 20,
            size: 42,
            onTap:
                () => AiModelSelector.openPicker(
                  context,
                  selected: _selectedModel,
                  onChanged: _onModelChanged,
                ),
          ),
          const SizedBox(width: 8),
          GlassIconButton(
            icon: Icons.close_rounded,
            iconSize: 20,
            size: 42,
            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Top-Level Data Extraction Functions (Run in Isolates via compute)
// ============================================================================

String? _extractPlainText(Uint8List bytes) {
  try {
    return utf8.decode(bytes, allowMalformed: true);
  } catch (e) {
    return null;
  }
}

String? _extractDocxText(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    final documentFile = archive.findFile('word/document.xml');
    if (documentFile == null) return null;

    final xmlContent = utf8.decode(
      documentFile.content as List<int>,
      allowMalformed: true,
    );
    final regex = RegExp(r'<w:t(?:\s+[^>]*)?>([^<]*)</w:t>');
    final matches = regex.allMatches(xmlContent);
    final text = matches.map((m) => m.group(1) ?? '').join(' ');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  } catch (e) {
    debugPrint('Docx extraction error: $e');
    return null;
  }
}

String? _extractXlsxText(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    final buffer = StringBuffer();

    final sharedStringsFile = archive.findFile('xl/sharedStrings.xml');
    if (sharedStringsFile != null) {
      final xmlContent = utf8.decode(
        sharedStringsFile.content as List<int>,
        allowMalformed: true,
      );
      final regex = RegExp(r'<t(?:\s+[^>]*)?>([^<]*)</t>');
      for (final match in regex.allMatches(xmlContent)) {
        buffer.write('${match.group(1)} | ');
      }
    }

    final sheetFile = archive.findFile('xl/worksheets/sheet1.xml');
    if (sheetFile != null) {
      final xmlContent = utf8.decode(
        sheetFile.content as List<int>,
        allowMalformed: true,
      );
      final regex = RegExp(r'<v>([^<]*)</v>');
      for (final match in regex.allMatches(xmlContent)) {
        final val = match.group(1) ?? '';
        if (double.tryParse(val) != null) buffer.write('$val | ');
      }
    }

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  } catch (e) {
    debugPrint('Xlsx extraction error: $e');
    return null;
  }
}
