import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/presence_cubit/presence_cubit.dart';

/// Declares that the subtree displays presence for [userIds].
///
/// While mounted, [PresenceCubit] keeps a live (filtered) Realtime
/// subscription for those users. It renders [child] unchanged and adds no
/// render objects, so it is safe to use around slivers.
class PresenceInterest extends StatefulWidget {
  final Set<String> userIds;
  final Widget child;

  const PresenceInterest({
    super.key,
    required this.userIds,
    required this.child,
  });

  PresenceInterest.single({
    super.key,
    required String userId,
    required this.child,
  }) : userIds = {userId};

  @override
  State<PresenceInterest> createState() => _PresenceInterestState();
}

class _PresenceInterestState extends State<PresenceInterest> {
  PresenceCubit? _cubit;
  Set<String> _registered = const <String>{};

  @override
  void initState() {
    super.initState();
    _cubit = context.read<PresenceCubit>();
    _registered = Set<String>.of(widget.userIds);
    _cubit!.watchAll(_registered);
  }

  @override
  void didUpdateWidget(covariant PresenceInterest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (setEquals(widget.userIds, _registered)) return;

    final next = Set<String>.of(widget.userIds);
    _cubit?.watchAll(next.difference(_registered));
    _cubit?.unwatchAll(_registered.difference(next));
    _registered = next;
  }

  @override
  void dispose() {
    _cubit?.unwatchAll(_registered);
    _cubit = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
