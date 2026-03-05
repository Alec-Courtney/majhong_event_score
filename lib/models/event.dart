import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_application_1/models/player.dart';
import 'package:flutter_application_1/models/game_log.dart';
import 'package:flutter_application_1/models/column_config.dart';

part 'event.g.dart';

@JsonSerializable(explicitToJson: true)
class Event {
  final String eventId;
  String eventName;
  /// "四人麻将" 或 "三人麻将"
  String mahjongType;
  /// 是否为团队赛事
  bool isTeamEvent;
  /// 总分检查值，例如 100000
  int scoreCheckTotal;
  @JsonKey(defaultValue: 30000)
  /// 精算原点
  int calculationBasePoint;
  /// 顺位基础点数，键为顺位（"1", "2", "3", "4"）
  Map<String, double> basePoints;
  /// 玩家列配置
  List<ColumnConfig> playerColumns;
  /// 团队列配置
  List<ColumnConfig> teamColumns;
  /// 赛事专属的选手基础数据
  List<Player> playerBaseData;
  /// 赛事专属的比赛记录
  List<GameLogEntry> gameLog;

  Event({
    required this.eventId,
    required this.eventName,
    required this.mahjongType,
    required this.isTeamEvent, /// 是否为团队赛事
    required this.scoreCheckTotal,
    this.calculationBasePoint = 30000, /// 默认值
    required this.basePoints,
    required this.playerColumns,
    required this.teamColumns,
    required this.playerBaseData,
    required this.gameLog,
  });

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
  Map<String, dynamic> toJson() => _$EventToJson(this);

  /// 默认的四人麻将配置
  static Event defaultFourPlayerEvent({required String eventId, required String eventName}) {
    return Event(
      eventId: eventId,
      eventName: eventName,
      mahjongType: "四人麻将",
      isTeamEvent: true, /// 四人麻将默认为团队赛事
      scoreCheckTotal: 100000,
      calculationBasePoint: 30000,
      basePoints: {"1": 50.0, "2": 10.0, "3": -10.0, "4": -30.0},
      playerColumns: [
        ColumnConfig(columnName: '队员', dataKey: 'name', calculationType: 'none', displayFormat: 'string', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '雀魂ID', dataKey: 'mahjongId', calculationType: 'none', displayFormat: 'string', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '分数', dataKey: 'score', calculationType: 'none', displayFormat: 'fixed1', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '半庄数', dataKey: 'gamesPlayed', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '1位', dataKey: 'rank1', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '2位', dataKey: 'rank2', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '3位', dataKey: 'rank3', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '4位', dataKey: 'rank4', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '最高得点', dataKey: 'highestScore', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '避四率', dataKey: 'avoidFourthRate', calculationType: 'avoidFourthRate', displayFormat: 'percent1', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '连对率', dataKey: 'consecutiveWinRate', calculationType: 'consecutiveWinRate', displayFormat: 'percent1', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '平均顺位', dataKey: 'averageRank', calculationType: 'averageRank', displayFormat: 'fixed1', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '平均场分', dataKey: 'averageGameScore', calculationType: 'averageGameScore', displayFormat: 'fixed1', isPlayerColumn: true, isTeamColumn: false),
      ],
      teamColumns: [
        ColumnConfig(columnName: '队伍', dataKey: 'name', calculationType: 'none', displayFormat: 'string', isPlayerColumn: false, isTeamColumn: true),
        ColumnConfig(columnName: '分数', dataKey: 'score', calculationType: 'none', displayFormat: 'fixed1', isPlayerColumn: false, isTeamColumn: true),
        ColumnConfig(columnName: '分差', dataKey: 'scoreDifference', calculationType: 'none', displayFormat: 'fixed1', isPlayerColumn: false, isTeamColumn: true),
        ColumnConfig(columnName: '半庄数', dataKey: 'gamesPlayed', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: false, isTeamColumn: true),
        ColumnConfig(columnName: '1位', dataKey: 'rank1', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: false, isTeamColumn: true),
        ColumnConfig(columnName: '2位', dataKey: 'rank2', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: false, isTeamColumn: true),
        ColumnConfig(columnName: '3位', dataKey: 'rank3', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: false, isTeamColumn: true),
        ColumnConfig(columnName: '4位', dataKey: 'rank4', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: false, isTeamColumn: true),
      ],
      playerBaseData: [],
      gameLog: [],
    );
  }

  /// 默认的三人麻将配置 (示例，需要根据实际规则调整)
  static Event defaultThreePlayerEvent({required String eventId, required String eventName}) {
    return Event(
      eventId: eventId,
      eventName: eventName,
      mahjongType: "三人麻将",
      isTeamEvent: false, /// 三人麻将默认为个人赛事
      scoreCheckTotal: 75000, /// 示例值
      calculationBasePoint: 30000, /// 适用于三人麻将的精算原点
      basePoints: {"1": 45.0, "2": 0.0, "3": -45.0}, /// 示例值
      playerColumns: [
        ColumnConfig(columnName: '队员', dataKey: 'name', calculationType: 'none', displayFormat: 'string', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '雀魂ID', dataKey: 'mahjongId', calculationType: 'none', displayFormat: 'string', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '分数', dataKey: 'score', calculationType: 'none', displayFormat: 'fixed1', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '半庄数', dataKey: 'gamesPlayed', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '1位', dataKey: 'rank1', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '2位', dataKey: 'rank2', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '3位', dataKey: 'rank3', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '最高得点', dataKey: 'highestScore', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '平均顺位', dataKey: 'averageRank', calculationType: 'averageRank', displayFormat: 'fixed1', isPlayerColumn: true, isTeamColumn: false),
        ColumnConfig(columnName: '平均场分', dataKey: 'averageGameScore', calculationType: 'averageGameScore', displayFormat: 'fixed1', isPlayerColumn: true, isTeamColumn: false),
      ],
      teamColumns: [
        ColumnConfig(columnName: '队伍', dataKey: 'name', calculationType: 'none', displayFormat: 'string', isPlayerColumn: false, isTeamColumn: true),
        ColumnConfig(columnName: '分数', dataKey: 'score', calculationType: 'none', displayFormat: 'fixed1', isPlayerColumn: false, isTeamColumn: true),
        ColumnConfig(columnName: '分差', dataKey: 'scoreDifference', calculationType: 'none', displayFormat: 'fixed1', isPlayerColumn: false, isTeamColumn: true),
        ColumnConfig(columnName: '半庄数', dataKey: 'gamesPlayed', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: false, isTeamColumn: true),
        ColumnConfig(columnName: '1位', dataKey: 'rank1', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: false, isTeamColumn: true),
        ColumnConfig(columnName: '2位', dataKey: 'rank2', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: false, isTeamColumn: true),
        ColumnConfig(columnName: '3位', dataKey: 'rank3', calculationType: 'none', displayFormat: 'integer', isPlayerColumn: false, isTeamColumn: true),
      ],
      playerBaseData: [],
      gameLog: [],
    );
  }
}
