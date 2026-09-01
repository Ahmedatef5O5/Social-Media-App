import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../helpers/formatted_date.dart';
import '../cubits/presence_cubit/presence_cubit.dart';
import '../models/presence_info.dart';

class PresenceStatusText extends StatelessWidget {
  final String userId;
  final bool fallbackIsOnline;
  final DateTime? fallbackLastSeen;
  final TextStyle? onlineStyle;
  final TextStyle? offlineStyle;

  const PresenceStatusText({
    super.key,
    required this.userId,
    this.fallbackIsOnline = false,
    this.fallbackLastSeen,
    this.onlineStyle,
    this.offlineStyle,
  });

  @override
  Widget build(BuildContext context) {
    final presenceInfo = context.select<PresenceCubit, PresenceInfo?>(
      (cubit) => cubit.of(userId),
    );

    final isOnline = presenceInfo?.isEffectivelyOnline ?? fallbackIsOnline;
    final lastSeen = presenceInfo?.lastSeen ?? fallbackLastSeen;

    final defaultOnlineStyle = const TextStyle(
      color: Colors.green,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
    final defaultOfflineStyle = const TextStyle(
      color: Colors.grey,
      fontSize: 12,
    );

    if (isOnline) {
      return Text('Online', style: onlineStyle ?? defaultOnlineStyle);
    }

    if (lastSeen != null) {
      final lastSeenStr = FormattedDate.getLastSeen(lastSeen);
      if (lastSeenStr == 'Online' || lastSeenStr == 'just now') {
        return Text('Online', style: onlineStyle ?? defaultOnlineStyle);
      }
      return Text(
        'Last seen $lastSeenStr',
        style: offlineStyle ?? defaultOfflineStyle,
      );
    }

    return const SizedBox.shrink();
  }
}
