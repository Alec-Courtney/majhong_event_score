import 'package:flutter_application_1/models/event.dart';
import 'package:flutter_application_1/models/player.dart';
import 'package:flutter_application_1/services/game_result_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameResultCalculator', () {
    test('团队赛事四人麻将：队伍重复会报错', () {
      final event = Event.defaultFourPlayerEvent(eventId: 'e1', eventName: 'test');
      event.playerBaseData.addAll([
        Player(name: 'A', mahjongId: 'A', team: 'T1'),
        Player(name: 'B', mahjongId: 'B', team: 'T1'),
        Player(name: 'C', mahjongId: 'C', team: 'T2'),
        Player(name: 'D', mahjongId: 'D', team: 'T3'),
      ]);

      final error = GameResultCalculator.validateEntries(
        event: event,
        entries: const [
          GameEntry(playerId: 'A', rawScore: 35000),
          GameEntry(playerId: 'B', rawScore: 25000),
          GameEntry(playerId: 'C', rawScore: 20000),
          GameEntry(playerId: 'D', rawScore: 20000),
        ],
      );

      expect(error, "错误：四人麻将团队赛事中，四名选手必须来自不同的队伍。");
    });

    test('个人赛事四人麻将：不强制四队不同', () {
      final event = Event.defaultFourPlayerEvent(eventId: 'e1', eventName: 'test');
      event.isTeamEvent = false;
      event.playerBaseData.addAll([
        Player(name: 'A', mahjongId: 'A', team: 'T1'),
        Player(name: 'B', mahjongId: 'B', team: 'T1'),
        Player(name: 'C', mahjongId: 'C', team: 'T1'),
        Player(name: 'D', mahjongId: 'D', team: 'T1'),
      ]);

      final error = GameResultCalculator.validateEntries(
        event: event,
        entries: const [
          GameEntry(playerId: 'A', rawScore: 35000),
          GameEntry(playerId: 'B', rawScore: 25000),
          GameEntry(playerId: 'C', rawScore: 20000),
          GameEntry(playerId: 'D', rawScore: 20000),
        ],
      );

      expect(error, isNull);
    });

    test('计算最终得分：按顺位点与精算原点计算', () {
      final event = Event.defaultFourPlayerEvent(eventId: 'e1', eventName: 'test');
      event.playerBaseData.addAll([
        Player(name: 'A', mahjongId: 'A', team: 'T1'),
        Player(name: 'B', mahjongId: 'B', team: 'T2'),
        Player(name: 'C', mahjongId: 'C', team: 'T3'),
        Player(name: 'D', mahjongId: 'D', team: 'T4'),
      ]);

      final results = GameResultCalculator.calculateResults(
        event: event,
        entries: const [
          GameEntry(playerId: 'A', rawScore: 45000),
          GameEntry(playerId: 'B', rawScore: 25000),
          GameEntry(playerId: 'C', rawScore: 20000),
          GameEntry(playerId: 'D', rawScore: 10000),
        ],
      );

      expect(results.first.id, 'A');
      expect(results.first.rank, 1);
      expect(results.first.finalScore, 65.0);
    });
  });
}

