import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/conversation_ref.dart';

class ConversationSelectionState {
  final Set<ConversationRef> selectedRefs;
  const ConversationSelectionState(this.selectedRefs);

  bool get isSelecting => selectedRefs.isNotEmpty;
  bool isSelected(ConversationRef ref) => selectedRefs.contains(ref);
}

class ConversationSelectionCubit extends Cubit<ConversationSelectionState> {
  ConversationSelectionCubit() : super(const ConversationSelectionState({}));

  void toggle(ConversationRef ref) {
    final updated = Set<ConversationRef>.from(state.selectedRefs);
    if (!updated.remove(ref)) updated.add(ref);
    emit(ConversationSelectionState(updated));
  }

  void clear() => emit(const ConversationSelectionState({}));
}
