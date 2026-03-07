import 'package:flutter_application_1/models/event.dart';
import 'package:flutter_application_1/models/game_log.dart';
import 'package:flutter_application_1/models/player.dart';
import 'package:flutter_application_1/services/event_stats_calculator.dart';
import 'package:flutter_application_1/services/game_result_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EventStatsCalculator：能从日志重新计算选手与队伍数据', () {
    final event = Event.defaultFourPlayerEvent(eventId: 'e1', eventName: 'test');
    event.playerBaseData.addAll([
      Player(name: 'A', mahjongId: 'A', team: 'T1'),
      Player(name: 'B', mahjongId: 'B', team: 'T2'),
      Player(name: 'C', mahjongId: 'C', team: 'T3'),
      Player(name: 'D', mahjongId: 'D', team: 'T4'),
    ]);

    final game1Results = GameResultCalculator.calculateResults(
      event: event,
      entries: const [
        GameEntry(playerId: 'A', rawScore: 45000),
        GameEntry(playerId: 'B', rawScore: 25000),
        GameEntry(playerId: 'C', rawScore: 20000),
        GameEntry(playerId: 'D', rawScore: 10000),
      ],
    );
    final game2Results = GameResultCalculator.calculateResults(
      event: event,
      entries: const [
        GameEntry(playerId: 'A', rawScore: 14000),
        GameEntry(playerId: 'B', rawScore: 52000),
        GameEntry(playerId: 'C', rawScore: 19000),
        GameEntry(playerId: 'D', rawScore: 15000),
      ],
    );

    event.gameLog.addAll([
      GameLogEntry(gameId: 'g1', timestamp: '2026-03-05', results: game1Results),
      GameLogEntry(gameId: 'g2', timestamp: '2026-03-05', results: game2Results),
    ]);

    final allTeams = event.playerBaseData.map((p) => p.team).toSet().toList()..sort();
    final playerToTeam = {
      for (final p in event.playerBaseData)
        if (p.mahjongId != null) p.mahjongId!: p.team,
    };

    final result = EventStatsCalculator.recalculate(
      event: event,
      allTeams: allTeams,
      playerToTeam: playerToTeam,
    );

    expect(result.playerStats.first.mahjongId, 'B');
    expect(result.playerStats.first.gamesPlayed, 2);
    expect(result.playerStats.first.rank1, 1);

    final playerA = result.playerStats.firstWhere((p) => p.mahjongId == 'A');
    expect(playerA.highestScore, 45000);
    expect(playerA.gamesPlayed, 2);
    expect(playerA.rank1, 1);
    expect(playerA.rank4, 1);
    expect(playerA.averageGameScore, 29500);
  });
}

