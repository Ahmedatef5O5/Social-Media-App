import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
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
import '../cubits/ai_chat_cubit/ai_chat_cubit.dart';
import '../di/ai_chat_dependencies.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_chat_session.dart';
import '../models/ai_model_option.dart';
import '../models/ai_reply_phase.dart';
import '../models/ai_suggestion_item.dart';
import '../widgets/ai_chat_delete_session_dialog.dart';
import '../widgets/ai_chat_forward_sheet.dart';
import '../widgets/ai_chat_greeting_header.dart';
import '../widgets/ai_chat_input_bar.dart';
import '../widgets/ai_chat_message_list.dart';
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
  late final ScrollController _scrollController;
  late final TextEditingController _textController;
  late final FocusNode _textFocusNode;
  AiModelOption _selectedModel = AiModelCatalog.defaultModel;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AiChatAttachmentController _attachments;

  // --- Live backend wiring ------------------------------------------
  AiChatDependencies? _deps;
  AiChatCubit? _chatCubit;
  String? _activeSessionId;
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

    _attachments = AiChatAttachmentController(
      mediaCache: context.read<MediaCacheRepository>(),
      activeCubit: () => _chatCubit,
      ensureDepsReady: () {
        if (_deps == null) {
          AppToast.info('Still getting Syncra ready — try again in a second.');
          return false;
        }
        _scrollToBottom();
        _startConversationIfNeeded();
        return true;
      },
      createSession: _createSessionAndAttach,
      onBeforeSend: _scrollToBottom,
      isMounted: () => mounted,
      onStaged: () => _textFocusNode.requestFocus(),
    );

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
    _scrollController.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    _phaseTimer?.cancel();
    _chatCubit?.close();
    _attachments.dispose();
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
    _attachments.removeStagedMedia();
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

  void _handleForward(AiChatMessage message) {
    AiChatForwardSheet.show(context, onForward: () => _forwardMessage(message));
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

  Future<void> _onSendText(String text) async {
    if (_attachments.stagedMediaFile != null) {
      await _attachments.sendStagedMedia(caption: text);
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
        await _createSessionAndAttach(text);
      }
      await _chatCubit!.sendMessage(text: text);
    } catch (_) {
      if (mounted) {
        AppToast.error('Failed to send your message. Please try again.');
      }
    }
  }

  void _handleCancelUpload(AiChatMessage message) {
    _attachments.cancelUpload(message.id);
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
                    child: ListenableBuilder(
                      listenable: _attachments,
                      builder: (context, _) {
                        return AiChatInputBar(
                          controller: _textController,
                          focusNode: _textFocusNode,
                          selectedModel: _selectedModel,
                          onModelChanged: _onModelChanged,
                          onSendText: _onSendText,
                          onSendVoice: _attachments.sendVoice,
                          onAttachmentPicked:
                              _attachments.handleAttachmentPicked,
                          stagedFileName: _attachments.stagedFileName,
                          stagedFileSizeBytes: _attachments.stagedFileSizeBytes,
                          stagedImageFile:
                              _attachments.stagedMediaType ==
                                      AiChatMediaType.image
                                  ? _attachments.stagedMediaFile
                                  : null,
                          onRemoveStagedFile: _attachments.removeStagedMedia,
                          onTapStagedFile: _openStagedMediaPreview,
                        );
                      },
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
