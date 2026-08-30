sealed class ConnectivityState {
  const ConnectivityState();
}

final class ConnectivityInitial extends ConnectivityState {}

final class ConnectivityOnline extends ConnectivityState {}

final class ConnectivityOffline extends ConnectivityState {}

final class ConnectivityRestored extends ConnectivityState {}
