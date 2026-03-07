import '../models/column_config.dart';
import '../models/event.dart';
import '../models/game_log.dart';
import '../models/player.dart';
import '../models/team.dart';

class EventStatsResult {
  final List<Player> playerStats;
  final List<Team> teamStats;

  const EventStatsResult({
    required this.playerStats,
    required this.teamStats,
  });
}

class EventStatsCalculator {
  static EventStatsResult recalculate({
    required Event event,
    required List<String> allTeams,
    required Map<String, String> playerToTeam,
  }) {
    final List<Player> playerStats = event.playerBaseData.map((p) {
      final newPlayer = Player(name: p.name, mahjongId: p.mahjongId, team: p.team);
      newPlayer.resetStats();
      return newPlayer;
    }).toList();

    final Map<String, Player> playerMap = {
      for (final player in playerStats)
        if (player.mahjongId != null) player.mahjongId!: player,
    };
    final Map<String, List<int>> playerRawScores = {
      for (final player in playerStats)
        if (player.mahjongId != null) player.mahjongId!: <int>[],
    };

    final List<Team> teamStats = allTeams.map((teamName) => Team(name: teamName)).toList();
    final Map<String, Team> teamMap = {for (final team in teamStats) team.name: team};

    for (final GameLogEntry game in event.gameLog) {
      for (final GameResult result in game.results) {
        final Player? player = playerMap[result.id];
        if (player == null) continue;

        final String? teamName = playerToTeam[player.mahjongId];
        if (teamName == null) continue;
        final Team? team = teamMap[teamName];
        if (team == null) continue;

        player.score += result.finalScore;
        player.gamesPlayed += 1;
        switch (result.rank) {
          case 1:
            player.rank1 += 1;
            break;
          case 2:
            player.rank2 += 1;
            break;
          case 3:
            player.rank3 += 1;
            break;
          case 4:
            player.rank4 += 1;
            break;
        }
        if (result.score > player.highestScore) {
          player.highestScore = result.score;
        }
        playerRawScores[player.mahjongId]?.add(result.score);

        team.score += result.finalScore;
        team.gamesPlayed += 1;
        switch (result.rank) {
          case 1:
            team.rank1 += 1;
            break;
          case 2:
            team.rank2 += 1;
            break;
          case 3:
            team.rank3 += 1;
            break;
          case 4:
            team.rank4 += 1;
            break;
        }
      }
    }

    for (final Player player in playerStats) {
      if (player.gamesPlayed <= 0) continue;

      for (final ColumnConfig col in event.playerColumns) {
        if (!col.isPlayerColumn) continue;

        switch (col.calculationType) {
          case 'avoidFourthRate':
            player.avoidFourthRate =
                ((player.rank1 + player.rank2 + player.rank3) / player.gamesPlayed) * 100;
            break;
          case 'consecutiveWinRate':
            player.consecutiveWinRate = ((player.rank1 + player.rank2) / player.gamesPlayed) * 100;
            break;
          case 'averageRank':
            player.averageRank =
                (player.rank1 * 1 + player.rank2 * 2 + player.rank3 * 3 + player.rank4 * 4) /
                    player.gamesPlayed;
            break;
          case 'averageGameScore':
            final rawScores = playerRawScores[player.mahjongId];
            if (rawScores == null || rawScores.isEmpty) {
              player.averageGameScore = 0.0;
              break;
            }
            final int sum = rawScores.fold(0, (acc, score) => acc + score);
            player.averageGameScore = sum / player.gamesPlayed;
            break;
        }
      }
    }

    playerStats.sort((a, b) => b.score.compareTo(a.score));
    teamStats.sort((a, b) => b.score.compareTo(a.score));

    for (int i = 0; i < teamStats.length; i++) {
      if (i == 0) {
        teamStats[i].scoreDifference = 0.0;
        continue;
      }
      teamStats[i].scoreDifference = (teamStats[i - 1].score - teamStats[i].score).abs();
    }

    return EventStatsResult(playerStats: playerStats, teamStats: teamStats);
  }
}

