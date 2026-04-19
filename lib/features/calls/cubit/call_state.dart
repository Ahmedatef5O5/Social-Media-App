import '../model/call_model.dart';

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
  CallConnectedState(this.call);
}

class CallEndedState extends CallState {}

class CallErrorState extends CallState {
  final String error;
  CallErrorState(this.error);
}
