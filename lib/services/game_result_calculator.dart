import '../models/event.dart';
import '../models/game_log.dart';
import '../models/player.dart';

class GameEntry {
  final String playerId;
  final int rawScore;

  const GameEntry({
    required this.playerId,
    required this.rawScore,
  });
}

class GameResultCalculator {
  static int expectedPlayerCount(Event event) {
    return event.mahjongType == '三人麻将' ? 3 : 4;
  }

  static String? validateEntries({
    required Event event,
    required List<GameEntry> entries,
  }) {
    final int playerCount = expectedPlayerCount(event);

    if (entries.length != playerCount) {
      return "必须输入 ${playerCount} 名选手的数据。";
    }

    final List<String> playerIds = entries.map((e) => e.playerId).toList();
    if (playerIds.toSet().length != playerCount) {
      return "错误：一局内的 ${playerCount} 名选手不能重复。";
    }

    final Map<String, Player> basePlayersById = {
      for (final player in event.playerBaseData)
        if ((player.mahjongId ?? '').trim().isNotEmpty) player.mahjongId!.trim(): player,
    };

    for (final entry in entries) {
      final Player? basePlayer = basePlayersById[entry.playerId];
      if (basePlayer == null) {
        return "未找到选手ID: ${entry.playerId}";
      }
      if (event.isTeamEvent && basePlayer.team.trim().isEmpty) {
        return "错误：团队赛事下，选手 ${entry.playerId} 没有填写队伍信息。";
      }
    }

    if (event.isTeamEvent && event.mahjongType == '四人麻将') {
      final Set<String> teamsInGame = entries
          .map((e) => basePlayersById[e.playerId]!.team.trim())
          .where((team) => team.isNotEmpty)
          .toSet();
      if (teamsInGame.length != 4) {
        return "错误：四人麻将团队赛事中，四名选手必须来自不同的队伍。";
      }
    }

    final int totalRawScore = entries.fold<int>(0, (sum, e) => sum + e.rawScore);
    if (totalRawScore != event.scoreCheckTotal) {
      return "错误：${playerCount} 名选手的场内总分必须为 ${event.scoreCheckTotal}，当前为 $totalRawScore。";
    }

    return null;
  }

  static List<GameResult> calculateResults({
    required Event event,
    required List<GameEntry> entries,
  }) {
    final List<GameEntry> sortedEntries = [...entries]
      ..sort((a, b) => b.rawScore.compareTo(a.rawScore));

    final List<GameResult> results = [];
    for (int i = 0; i < sortedEntries.length; i++) {
      final int rank = i + 1;
      final double basePoint = event.basePoints[rank.toString()] ?? 0.0;
      final double finalScore =
          (sortedEntries[i].rawScore - event.calculationBasePoint) / 1000 + basePoint;
      results.add(
        GameResult(
          id: sortedEntries[i].playerId,
          score: sortedEntries[i].rawScore,
          rank: rank,
          finalScore: finalScore,
        ),
      );
    }
    return results;
  }
}

