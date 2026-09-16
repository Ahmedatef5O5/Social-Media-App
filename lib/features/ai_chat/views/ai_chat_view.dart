import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/attachment/attachment_sheet/attachment_picker_sheet.dart';
import '../../../core/cache/repository/media_cache_repository.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../../auth/data/models/user_data.dart';
import '../../chat_forwarding/models/forward_target_selection.dart';
import '../../chat_forwarding/models/forwardable_message.dart';
import '../../chat_forwarding/services/forward_service.dart';
import '../../chat_forwarding/views/forward_target_picker_view.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../../single_chats/helpers/glass_icon_btn.dart';
import '../controllers/ai_chat_attachment_controller.dart';
import '../controllers/ai_chat_reply_controller.dart';
import '../controllers/ai_chat_scroll_anchor.dart';
import '../controllers/ai_chat_selection_controller.dart';
import '../cubits/ai_chat_cubit/ai_chat_cubit.dart';
import '../di/ai_chat_dependencies.dart';
import '../helpers/ai_model_iconography.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_chat_session.dart';
import '../models/ai_model_option.dart';
import '../models/ai_reply_phase.dart';
import '../models/ai_suggestion_item.dart';
import '../widgets/ai_chat_delete_session_dialog.dart';
import '../widgets/ai_chat_greeting_header.dart';
import '../widgets/ai_chat_input_bar.dart';
import '../widgets/ai_chat_message_list.dart';
import '../widgets/ai_chat_selection_header_bar.dart';
import '../widgets/ai_chat_sessions_drawer.dart';
import '../widgets/ai_chat_shimmer.dart';
import '../widgets/ai_model_selector.dart';
import '../widgets/ai_suggestion_grid.dart';
import '../widgets/syncra_backdrop.dart';
import 'ai_photo_preview_screen.dart';

class AiChatView extends StatefulWidget {
  final String? initialSessionId;
  final String? initialDraftText;
  final String? initialDraftImageRemoteUrl;
  final String? initialDraftImageCaption;
  final String? initialDraftImageLocalPath;
  final String? initialDraftFileRemoteUrl;
  final String? initialDraftFileLocalPath;
  final String? initialDraftFileName;
  final String? initialDraftFileCaption;

  const AiChatView({
    super.key,
    this.initialSessionId,
    this.initialDraftText,
    this.initialDraftImageRemoteUrl,
    this.initialDraftImageCaption,
    this.initialDraftImageLocalPath,
    this.initialDraftFileRemoteUrl,
    this.initialDraftFileLocalPath,
    this.initialDraftFileName,
    this.initialDraftFileCaption,
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
  late final AiChatReplyController _reply;
  late final TextEditingController _textController;
  late final FocusNode _textFocusNode;
  AiModelOption _selectedModel = AiModelCatalog.defaultModel;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AiChatAttachmentController _attachments;
  late final AiChatSelectionController _selection;

  // Hidden by default — the whole point now is "out of the way unless you
  // ask for it", not "visible unless you scroll it away".
  bool _isHeaderVisible = false;
  Timer? _headerAutoHideTimer;
  static const _headerAutoHideDelay = Duration(seconds: 5); // 4-6s window
  // --- Live backend wiring ------------------------------------------
  AiChatDependencies? _deps;
  AiChatCubit? _chatCubit;
  String? _activeSessionId;
  final Set<String> _historicalMessageIds = {};
  final AiChatScrollAnchor _scrollAnchor = AiChatScrollAnchor();
  final Set<String> _animatedMessageIds = {};

  final ValueNotifier<AiReplyPhase?> _replyPhase = ValueNotifier<AiReplyPhase?>(
    null,
  );
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
    _reply = AiChatReplyController();
    _textController = TextEditingController();
    _textFocusNode = FocusNode();
    _showWelcome = widget.initialSessionId == null;

    _attachments = AiChatAttachmentController(
      mediaCache: context.read<MediaCacheRepository>(),
      activeCubit: () => _chatCubit,
      ensureDepsReady: () {
        if (_deps == null) {
          AppToast.info('Still getting Syncra ready — try again in a second.');
          return false;
        }
        _scheduleScrollToBottom();
        _startConversationIfNeeded();
        return true;
      },
      createSession: _createSessionAndAttach,
      onBeforeSend: _scheduleScrollToBottom,
      isMounted: () => mounted,
      onStaged: () => _textFocusNode.requestFocus(),
    );

    _selection = AiChatSelectionController(currentUserId: SupabaseProvider.id);

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
    } else if (widget.initialDraftFileRemoteUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openForwardedFilePreview(
            widget.initialDraftFileRemoteUrl!,
            widget.initialDraftFileName ?? 'Forwarded File',
          );
        }
      });
    } else if (widget.initialDraftImageLocalPath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _attachments.stageImage(File(widget.initialDraftImageLocalPath!));
        }
      });
    } else if (widget.initialDraftFileLocalPath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final path = widget.initialDraftFileLocalPath!;
          final name = widget.initialDraftFileName ?? path.split('/').last;
          _attachments.stageFile(File(path), name);
        }
      });
    }
    _bootstrap();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _morphController.dispose();
    _reply.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    _phaseTimer?.cancel();
    _replyPhase.dispose();
    _chatCubit?.close();
    _attachments.dispose();
    _selection.dispose();
    _headerAutoHideTimer?.cancel();
    _scrollAnchor.dispose();
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
    _selection.clearSelection();
    _reply.cancelReply();
    _headerAutoHideTimer?.cancel();
    _isHeaderVisible = false;
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

  Future<AiChatCubit> _createSessionAndAttach(String firstMessage) async {
    final session = await _deps!.repository.createSession(
      firstMessage: firstMessage,
    );
    if (!mounted) throw StateError('view disposed mid-send');
    setState(
      () => _attachCubit(
        session.id,
        isExisting: false,
        newlyCreatedSession: session,
      ),
    );
    return _chatCubit!;
  }

  void _handleSwipeReply(AiChatMessage message) {
    _reply.setReply(message);
    _textFocusNode.requestFocus();
  }

  void _handleCancelReply() {
    _reply.cancelReply();
  }

  void _handleTapReplyPreview() {
    final target = _reply.replyingTo.value;
    final state = _chatCubit?.state;
    if (target == null || state is! AiChatMessagesLoaded) return;
    _reply.revealMessage(
      messageId: target.id,
      messages: state.messages,
      anchor: _scrollAnchor,
    );
  }

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
    _attachments.removeStagedMedia();
    _selection.clearSelection();
    _reply.cancelReply();
    _headerAutoHideTimer?.cancel();
    _isHeaderVisible = false;
    _deps?.lastActiveSessionId = null;
    if (_chatCubit == null) {
      _textFocusNode.requestFocus();
      return;
    }

    final oldCubit = _chatCubit;
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _wasSending = false;
    _replyPhase.value = null;

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

  // AiChatSessionsDrawer.

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

    final confirmed = await AiChatDeleteSessionDialog.show(context, session);
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

  // ---------------------------------------------------------------------
  // Multi-select: entry points + AppBar actions
  // ---------------------------------------------------------------------

  void _handleLongPressMessage(AiChatMessage message) {
    if (_selection.isInSelectionMode) {
      _selection.toggleMessageSelection(message.id);
    } else {
      HapticFeedback.mediumImpact();
      FocusManager.instance.primaryFocus?.unfocus();
      _selection.startSelection(message.id);
    }
  }

  void _handleTapSelectMessage(AiChatMessage message) {
    _selection.toggleMessageSelection(message.id);
  }

  // ---------------------------------------------------------------------
  // Floating header — [UPDATED] scroll may only ever hide it now;
  // revealing it is exclusively the menu icon's job (_buildMenuToggle).
  // ---------------------------------------------------------------------

  void _showHeaderTemporarily() {
    setState(() => _isHeaderVisible = true);
    _restartHeaderAutoHideTimer();
  }

  void _restartHeaderAutoHideTimer() {
    _headerAutoHideTimer?.cancel();
    _headerAutoHideTimer = Timer(_headerAutoHideDelay, () {
      if (!mounted) return;
      if (_scaffoldKey.currentState?.isDrawerOpen ?? false) return;
      setState(() => _isHeaderVisible = false);
    });
  }

  void _hideHeaderNow() {
    _headerAutoHideTimer?.cancel();
    _headerAutoHideTimer = null;
    if (_isHeaderVisible) setState(() => _isHeaderVisible = false);
  }

  bool _handleUserScrollNotification(UserScrollNotification notification) {
    if (notification.direction != ScrollDirection.idle) {
      _hideHeaderNow();
    }
    return false; // keep bubbling — other ancestors may care too.
  }

  List<AiChatMessage> _currentSelectedMessages() {
    final state = _chatCubit?.state;
    if (state is! AiChatMessagesLoaded) return const [];
    final ids = _selection.selectedMessageIds.value;
    return state.messages.where((m) => ids.contains(m.id)).toList();
  }

  Future<void> _forwardSelectedMessages() async {
    final selected = _currentSelectedMessages();
    if (selected.isEmpty) return;

    final result = await Navigator.of(context).push<ForwardTargetSelection>(
      MaterialPageRoute(
        builder: (_) => ForwardTargetPickerView(messageCount: selected.length),
      ),
    );
    if (result == null || result.isEmpty || !mounted) return;
    if (result.toAi) return; // forwarding an AI reply back into itself — n/a

    _selection.clearSelection();

    try {
      await ForwardService().forwardMessages(
        messages: selected.map(ForwardableMessage.fromAiChatMessage).toList(),
        targets: result,
        currentUserId: SupabaseProvider.id,
      );
      if (mounted) AppToast.info('Forwarded to ${result.length} chat(s)');
    } catch (_) {
      if (mounted) AppToast.error('Failed to forward. Please try again.');
    }
  }

  Future<void> _shareSelectedMessages() async {
    final selected = _currentSelectedMessages();
    if (selected.isEmpty) return;

    final combinedText = selected
        .map((m) => m.text.trim())
        .where((t) => t.isNotEmpty)
        .join('\n\n');

    if (combinedText.isEmpty) {
      AppToast.info("There's no text to share in this selection.");
      return;
    }

    _selection.clearSelection();
    await SharePlus.instance.share(ShareParams(text: combinedText));
  }

  Future<void> _copySelectedMessages() async {
    final ids = _selection.selectedMessageIds.value;
    final state = _chatCubit?.state;
    if (ids.isEmpty || state is! AiChatMessagesLoaded) return;

    final selected = state.messages.where((m) => ids.contains(m.id)).toList();
    if (selected.isEmpty) return;

    final combinedText = selected
        .map((m) => m.text.trim())
        .where((t) => t.isNotEmpty)
        .join('\n\n');
    await Clipboard.setData(ClipboardData(text: combinedText));

    if (mounted) {
      AppToast.success('Copied to clipboard');
      _selection.clearSelection();
    }
  }

  Future<void> _toggleStarForSelectedMessages() async {
    await _selection.toggleStarForSelection();
    if (mounted) _selection.clearSelection();
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
    _attachments.handleAttachmentPicked(picked);
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

  AiChatMessage? _consumeReplyTarget() {
    final target = _reply.replyingTo.value;
    if (target == null) return null;
    _reply.cancelReply();
    return target;
  }

  Future<void> _onSendText(String text) async {
    final replyTarget = _consumeReplyTarget();

    if (_attachments.stagedMediaFile != null) {
      await _attachments.sendStagedMedia(
        caption: text,
        replyToMessageId: replyTarget?.id,
        replyToMessageText: replyTarget?.text,
        replyToSenderRole:
            replyTarget == null
                ? null
                : (replyTarget.isMe ? 'user' : 'assistant'),
        replyToMediaType:
            replyTarget != null && replyTarget.mediaType != AiChatMediaType.none
                ? replyTarget.mediaType.name
                : null,
        replyToMediaUrl: replyTarget?.mediaUrl,
      );
      return;
    }
    final deps = _deps;
    if (deps == null) {
      AppToast.info('Still getting Syncra ready — try again in a second.');
      return;
    }
    _startConversationIfNeeded();
    try {
      if (_chatCubit == null) {
        await _createSessionAndAttach(text);
      }
      await _chatCubit!.sendMessage(
        text: text,
        replyToMessageId: replyTarget?.id,
        replyToMessageText: replyTarget?.text,
        replyToSenderRole: replyTarget?.isMe == true ? 'user' : 'assistant',
        replyToMediaType:
            replyTarget != null && replyTarget.mediaType != AiChatMediaType.none
                ? replyTarget.mediaType.name
                : null,
        replyToMediaUrl: replyTarget?.mediaUrl,
      );
      _scheduleScrollToBottom();
    } catch (_) {
      if (mounted) {
        AppToast.error('Failed to send your message. Please try again.');
      }
    }
  }

  Future<void> _handleSendVoice(File file, int durationSeconds) async {
    final replyTarget = _consumeReplyTarget();
    await _attachments.sendVoice(
      file,
      durationSeconds,
      replyToMessageId: replyTarget?.id,
      replyToMessageText: replyTarget?.text,
      replyToSenderRole:
          replyTarget == null
              ? null
              : (replyTarget.isMe ? 'user' : 'assistant'),
      replyToMediaType:
          replyTarget != null && replyTarget.mediaType != AiChatMediaType.none
              ? replyTarget.mediaType.name
              : null,
      replyToMediaUrl: replyTarget?.mediaUrl,
    );
  }

  void _handleTapReplyInBubble(String originalMessageId) {
    final state = _chatCubit?.state;
    if (state is! AiChatMessagesLoaded) return;
    _reply.revealMessage(
      messageId: originalMessageId,
      messages: state.messages,
      anchor: _scrollAnchor,
    );
  }

  void _handleCancelUpload(AiChatMessage message) {
    _attachments.cancelUpload(message.id);
  }

  // ignore: unused_field
  bool _scrollToBottomScheduled = false;

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollAnchor.pinToBottom();
    });
  }

  void _scrollToBottom() => _scrollAnchor.pinToBottom();

  void _handleRetry(AiChatMessage message) {
    _chatCubit?.sendMessage(
      text: message.text,
      replyToMessageId: message.replyToMessageId,
      replyToMessageText: message.replyToText,
      replyToSenderRole: message.replyToSenderRole,
      replyToMediaType: message.replyToMediaType,
      replyToMediaUrl: message.replyToMediaUrl,
    );
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
    _replyPhase.value = _replyPhases[index];
    _phaseTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      index = (index + 1) % _replyPhases.length;
      _replyPhase.value = _replyPhases[index];
    });
  }

  void _stopPhaseCycle() {
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _replyPhase.value = null;
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
    await _attachments.stageImage(File(localPath), remoteImageUrl: remoteUrl);
  }

  Future<void> _openForwardedFilePreview(
    String remoteUrl,
    String fileName,
  ) async {
    final localPath = await context
        .read<MediaCacheRepository>()
        .resolveLocalPath(remoteUrl);

    if (!mounted) return;

    if (localPath == null) {
      AppToast.error("Couldn't load that file. Please try again.");
      return;
    }

    if (widget.initialDraftFileCaption != null) {
      _textController.text = widget.initialDraftFileCaption!;
    }

    await _attachments.stageFile(File(localPath), fileName);
  }

  Future<void> _openStagedMediaPreview() async {
    final file = _attachments.stagedMediaFile;
    if (file == null) return;

    if (_attachments.stagedMediaType == AiChatMediaType.image) {
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
            _headerAutoHideTimer?.cancel();
            _headerAutoHideTimer = null;
            if (!_isHeaderVisible) {
              setState(() => _isHeaderVisible = true);
            }
          } else {
            _restartHeaderAutoHideTimer();
          }
        }),
        drawer: AiChatSessionsDrawer(
          deps: _deps,
          activeSessionId: _activeSessionId,
          selectedModel: _selectedModel,
          onStartNewChat: _startNewChatFromDrawer,
          onOpenSession: _openSessionFromDrawer,
          onDeleteSession: _deleteSessionFromDrawer,
        ),
        body: Stack(
          children: [
            Positioned.fill(child: SyncraBackdrop(primary: theme.primaryColor)),
            SafeArea(
              child: NotificationListener<UserScrollNotification>(
                onNotification: _handleUserScrollNotification,
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _headerFade,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeInOutCubic,
                          alignment: Alignment.topCenter,
                          child: _buildHeaderArea(context, currentUser),
                        ),
                      ),
                    ),

                    Expanded(
                      child: Stack(
                        children: [
                          AnimatedBuilder(
                            key: const ValueKey('ai-welcome-layer'),
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
                              key: const ValueKey('ai-chat-layer'),
                              animation: _morphController,
                              child: BlocProvider.value(
                                value: _chatCubit!,
                                child: BlocConsumer<
                                  AiChatCubit,
                                  AiChatMessagesState
                                >(
                                  listener: _onChatStateChanged,
                                  buildWhen: (previous, current) {
                                    if (previous.runtimeType !=
                                        current.runtimeType) {
                                      return true;
                                    }
                                    if (previous is AiChatMessagesLoaded &&
                                        current is AiChatMessagesLoaded) {
                                      return !identical(
                                            previous.messages,
                                            current.messages,
                                          ) ||
                                          previous.error != current.error;
                                    }
                                    return true;
                                  },
                                  builder: (context, state) {
                                    if (state is AiChatMessagesLoading) {
                                      return const AiChatMessagesShimmerList();
                                    }
                                    if (state is AiChatMessagesError) {
                                      return _buildLoadError(state.message);
                                    }
                                    final loaded =
                                        state as AiChatMessagesLoaded;
                                    return AiChatMessageList(
                                      scrollAnchor: _scrollAnchor,
                                      messages: loaded.messages,
                                      replyPhase: _replyPhase,
                                      activeModel: _selectedModel,
                                      shouldAnimateText:
                                          (m) =>
                                              m.role == AiChatRole.assistant &&
                                              !_historicalMessageIds.contains(
                                                m.id,
                                              ) &&
                                              !_animatedMessageIds.contains(
                                                m.id,
                                              ),
                                      onTypewriterDone: (messageId) {
                                        _animatedMessageIds.add(messageId);
                                      },
                                      onRetry: _handleRetry,
                                      onCancelUpload: _handleCancelUpload,
                                      selectedMessageIds:
                                          _selection.selectedMessageIds,
                                      onLongPressMessage:
                                          _handleLongPressMessage,
                                      onTapSelectMessage:
                                          _handleTapSelectMessage,
                                      starredMessageIds:
                                          _selection.starredMessageIds,
                                      onSwipeReply: _handleSwipeReply,
                                      highlightedMessageId:
                                          _reply.highlightedMessageId,
                                      onTapReply:
                                          _handleTapReplyInBubble, // [FIX] ربط الـ Scroll بالـ Bubble
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

                          ValueListenableBuilder<Set<String>>(
                            valueListenable: _selection.selectedMessageIds,
                            builder: (context, selectedIds, _) {
                              final isSelectionMode = selectedIds.isNotEmpty;
                              if (_isHeaderVisible || isSelectionMode) {
                                return const SizedBox.shrink();
                              }
                              return PositionedDirectional(
                                top: 8,
                                start: 14,
                                child: AnimatedOpacity(
                                  opacity: _isHeaderVisible ? 0.0 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: GlassIconButton(
                                    icon: Icons.expand_more_rounded,
                                    iconSize: 18,
                                    size: 34,
                                    onTap: _showHeaderTemporarily,
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
                      child: ValueListenableBuilder<AiChatMessage?>(
                        valueListenable: _reply.replyingTo,
                        builder: (context, replyingTo, _) {
                          return ListenableBuilder(
                            listenable: _attachments,
                            builder: (context, __) {
                              return AiChatInputBar(
                                controller: _textController,
                                focusNode: _textFocusNode,
                                selectedModel: _selectedModel,
                                onModelChanged: _onModelChanged,
                                onSendText: _onSendText,
                                onSendVoice: _handleSendVoice,
                                onAttachmentPicked:
                                    _attachments.handleAttachmentPicked,
                                stagedFileName: _attachments.stagedFileName,
                                stagedFileSizeBytes:
                                    _attachments.stagedFileSizeBytes,
                                stagedImageFile:
                                    _attachments.stagedMediaType ==
                                            AiChatMediaType.image
                                        ? _attachments.stagedMediaFile
                                        : null,
                                onRemoveStagedFile:
                                    _attachments.removeStagedMedia,
                                onTapStagedFile: _openStagedMediaPreview,
                                replyingTo: replyingTo,
                                onCancelReply: _handleCancelReply,
                                onTapReplyPreview: _handleTapReplyPreview,
                              );
                            },
                          );
                        },
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

  Widget _buildWelcomeContent(
    BuildContext context,
    String firstName,
    UserData? currentUser,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.fromLTRB(20, _isHeaderVisible ? 14 : 48, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 36),
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
      ),
    );
  }

  Widget _buildSelectionHeader(BuildContext context, Set<String> selectedIds) {
    return ValueListenableBuilder<AiSelectionStarState>(
      valueListenable: _selection.starState,
      builder: (context, starState, _) {
        return AiChatSelectionHeaderBar(
          selectedCount: selectedIds.length,
          onCancel: _selection.clearSelection,
          showStar:
              starState == AiSelectionStarState.allStarred ||
              starState == AiSelectionStarState.allUnstarred,
          isStarred: starState == AiSelectionStarState.allStarred,
          onStarToggle: _toggleStarForSelectedMessages,
          onShareTap: _shareSelectedMessages,
          onForwardTap: _forwardSelectedMessages,
          onCopyTap: _copySelectedMessages,
          onInfoTap: () => AppToast.info('Info is coming soon'),
        );
      },
    );
  }

  Widget _buildHeaderArea(BuildContext context, UserData? currentUser) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: _selection.selectedMessageIds,
      builder: (context, selectedIds, _) {
        final isSelectionMode = selectedIds.isNotEmpty;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child:
              isSelectionMode
                  ? KeyedSubtree(
                    key: const ValueKey('ai-chat-header-selection'),
                    child: _buildSelectionHeader(context, selectedIds),
                  )
                  : KeyedSubtree(
                    key: const ValueKey('ai-chat-header-normal'),
                    child: _buildNormalHeaderRow(context, currentUser),
                  ),
        );
      },
    );
  }

  Widget _buildNormalHeaderRow(BuildContext context, UserData? currentUser) {
    if (!_isHeaderVisible) {
      return const SizedBox.shrink();
    }

    return KeyedSubtree(
      key: const ValueKey('ai-header-expanded'),
      child: _buildExpandedHeaderRow(context, currentUser),
    );
  }

  Widget _buildExpandedHeaderRow(BuildContext context, UserData? currentUser) {
    return KeyedSubtree(
      key: const ValueKey('ai-header-expanded'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.32),
              Colors.black.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Row(
          children: [
            GlassIconButton(
              icon: Icons.menu_rounded,
              iconSize: 18,
              size: 38,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 8),
            Expanded(child: _buildHeaderRestContent(context, currentUser)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRestContent(BuildContext context, UserData? currentUser) {
    return Row(
      children: [
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
          iconSize: 18,
          size: 38,
          onTap:
              () => AiModelSelector.openPicker(
                context,
                selected: _selectedModel,
                onChanged: _onModelChanged,
              ),
          child: AiModelIconography.buildBrandIcon(
            AiModelIconography.brandFromWire(_selectedModel.provider.name),
            size: 18,
            useOriginalColors: true,
          ),
        ),
        const SizedBox(width: 8),
        GlassIconButton(
          icon: Icons.close_rounded,
          iconSize: 18,
          size: 38,
          onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ],
    );
  }
}
