part of 'call_cubit.dart';

abstract class CallState {}

class CallInitial extends CallState {}

class CallDialingState extends CallState {
  final CallModel call;
  CallDialingState(this.call);
}

class CallIncomingState extends CallState {
  final CallModel call;
  CallIncomingState(this.call);
}

class CallConnectedState extends CallState {
  final CallModel call;
  final String currentUserName;

  CallConnectedState(this.call, this.currentUserName);
}

class CallEndedState extends CallState {}

class CallErrorState extends CallState {
  final String error;
  CallErrorState(this.error);
}
