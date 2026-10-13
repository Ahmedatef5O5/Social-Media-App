import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/session/session_cubits.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/features/group_chats/cubits/group_list_cubit/group_list_cubit.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import 'package:social_media_app/features/posts/cubits/posts_cubit/posts_cubit.dart';
import 'package:social_media_app/features/reels/cubits/reels_feed_cubit/reels_feed_cubit.dart';
import 'package:social_media_app/features/single_calls/cubits/single_call_cubit/call_cubit.dart';
import 'package:social_media_app/features/single_chats/cubits/chats_cubit/chats_cubit.dart';
import 'package:social_media_app/features/stories/cubits/stories_cubit/stories_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionScope extends StatefulWidget {
  final Widget child;
  const SessionScope({super.key, required this.child});

  /// Ends the current session: closes every account-scoped Cubit and installs
  /// a fresh, idle (signed-out) bundle. Call only on a CONFIRMED sign-out
  /// (the bootstrap listener already ignores offline phantom sign-outs).
  static void endSession(BuildContext context) {
    context.findAncestorStateOfType<SessionScopeState>()?._rotateTo(null);
  }

  @override
  State<SessionScope> createState() => SessionScopeState();
}

class SessionScopeState extends State<SessionScope> {
  late SessionCubits _cubits;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _cubits = SessionCubits.create(context, userId: SupabaseProvider.idOrNull);
    try {
      _authSub = SupabaseProvider.authChanges.listen(_onAuthChange);
    } catch (e) {
      debugPrint('⚠️ SessionScope: Supabase auth listener deferred: $e');
    }
  }

  void _onAuthChange(AuthState data) {
    final session = data.session;
    final isSignIn =
        data.event == AuthChangeEvent.signedIn ||
        data.event == AuthChangeEvent.initialSession;
    // Same id (token refresh, app resume re-emitting signedIn) is a no-op
    // inside _rotateTo. Sign-out is handled explicitly via endSession().
    if (isSignIn && session != null) _rotateTo(session.user.id);
  }

  void _rotateTo(String? userId) {
    if (!mounted || userId == _cubits.userId) return;

    final old = _cubits;
    // Close first: some Cubits use fixed channel names (e.g.
    // `public_stories_changes`), so the old owner must release them before
    // the new one subscribes.
    unawaited(old.close());

    setState(() {
      _cubits = SessionCubits.create(context, userId: userId);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    unawaited(_cubits.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PostsCubit>.value(value: _cubits.posts),
        BlocProvider<HomeCubit>.value(value: _cubits.home),
        BlocProvider<StoriesCubit>.value(value: _cubits.stories),
        BlocProvider<ReelsFeedCubit>.value(value: _cubits.reels),
        BlocProvider<GroupListCubit>.value(value: _cubits.groups),
        BlocProvider<CallCubit>.value(value: _cubits.call),
        BlocProvider<ChatsCubit>.value(value: _cubits.chats),
      ],
      child: widget.child,
    );
  }
}
