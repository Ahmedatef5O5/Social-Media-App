import 'dart:math';

class InjectionPlanEntry {
  final int afterPostIndex;
  final int reelsCount;
  const InjectionPlanEntry({
    required this.afterPostIndex,
    required this.reelsCount,
  });
}

List<InjectionPlanEntry> buildInjectionPlan(int postsCount) {
  final plan = <InjectionPlanEntry>[];
  final random = Random();
  var cursor = 0;
  while (cursor < postsCount) {
    cursor += 3 + random.nextInt(2);
    if (cursor >= postsCount) break;
    final size = 4 + random.nextInt(2) * 2;
    plan.add(InjectionPlanEntry(afterPostIndex: cursor, reelsCount: size));
  }
  return plan;
}
