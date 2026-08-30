import 'dart:math';
import '../models/reel_model.dart';

class ReelsInterleaver {
  const ReelsInterleaver._();

  static List<ReelModel> shuffle(List<ReelModel> reels, {Random? random}) {
    if (reels.length <= 1) return List.of(reels);
    final rnd = random ?? Random();

    final byChannel = <String, List<ReelModel>>{};
    for (final reel in reels) {
      byChannel.putIfAbsent(reel.channel.id, () => []).add(reel);
    }
    final channelQueues = byChannel.values.toList();
    for (final queue in channelQueues) {
      queue.shuffle(rnd);
    }

    final result = <ReelModel>[];
    String? lastChannelId;

    while (channelQueues.any((queue) => queue.isNotEmpty)) {
      final roundOrder =
          channelQueues.where((queue) => queue.isNotEmpty).toList()
            ..shuffle(rnd);

      if (lastChannelId != null &&
          roundOrder.length > 1 &&
          roundOrder.first.first.channel.id == lastChannelId) {
        final swapIndex = 1 + rnd.nextInt(roundOrder.length - 1);
        final tmp = roundOrder[0];
        roundOrder[0] = roundOrder[swapIndex];
        roundOrder[swapIndex] = tmp;
      }

      for (final queue in roundOrder) {
        final reel = queue.removeAt(0);
        result.add(reel);
        lastChannelId = reel.channel.id;
      }
    }

    return result;
  }
}
