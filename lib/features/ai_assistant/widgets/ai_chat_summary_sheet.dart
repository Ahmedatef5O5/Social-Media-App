import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import '../data/repositories/ai_repository_impl.dart';
import '../entities/ai_action_type.dart';
import '../entities/ai_result.dart';
import '../repository/ai_repository.dart';

class AiChatSummarySheet extends StatefulWidget {
  final AiActionType mode;
  final String transcript;
  final AiRepository? repository;

  const AiChatSummarySheet({
    super.key,
    required this.mode,
    required this.transcript,
    this.repository,
  });

  @override
  State<AiChatSummarySheet> createState() => _AiChatSummarySheetState();
}

class _AiChatSummarySheetState extends State<AiChatSummarySheet> {
  late final AiRepository _repository = widget.repository ?? AiRepositoryImpl();

  bool _loading = true;
  String? _text;
  String? _failureReason;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    if (widget.transcript.trim().isEmpty) {
      setState(() {
        _loading = false;
        _failureReason = 'empty_chat';
      });
      return;
    }

    final AiResult result = await _repository.summarizeChat(
      transcript: widget.transcript,
      mode: widget.mode,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _text = result.text;
      } else {
        _failureReason = result.failureReason;
      }
    });
  }

  String get _title {
    switch (widget.mode) {
      case AiActionType.chatSummaryShort:
        return 'ملخص المحادثة';
      case AiActionType.chatSummaryDetailed:
        return 'ملخص تفصيلي';
      case AiActionType.chatSummaryTopic:
        return 'عن إيه الكلام؟';
      default:
        return 'ملخص';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 420),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 18),
                const SizedBox(width: 8),
                Text(_title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(child: SingleChildScrollView(child: _buildBody(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_failureReason != null) {
      final isQuota =
          _failureReason == AiFailureReason.userQuotaExceeded ||
          _failureReason == AiFailureReason.globalQuotaExceeded;

      final message =
          _failureReason == 'empty_chat'
              ? 'مفيش رسائل كفاية في المحادثة عشان نلخصها.'
              : isQuota
              ? 'خلصت حصتك اليومية من الذكاء الاصطناعي، جرب تاني بكرة.'
              : 'حصل خطأ، جرب تاني كمان شوية.';

      return Text(message, style: Theme.of(context).textTheme.bodyMedium);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_text ?? '', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _text ?? ''));
              AppToast.success('اتنسخ');
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('نسخ'),
          ),
        ),
      ],
    );
  }
}
