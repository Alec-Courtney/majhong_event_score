import 'package:json_annotation/json_annotation.dart';

part 'game_log.g.dart';

@JsonSerializable()
class GameResult {
  final String id; // 雀魂ID
  final int score; // 场内分数
  int rank; // 顺位
  @JsonKey(name: 'final_score')
  double finalScore; // 最终得分 (pt)

  GameResult({
    required this.id,
    required this.score,
    required this.rank,
    required this.finalScore,
  });

  factory GameResult.fromJson(Map<String, dynamic> json) => _$GameResultFromJson(json);
  Map<String, dynamic> toJson() => _$GameResultToJson(this);
}

@JsonSerializable()
class GameLogEntry {
  @JsonKey(name: 'game_id')
  final String gameId;
  final String timestamp;
  final List<GameResult> results;

  GameLogEntry({
    required this.gameId,
    required this.timestamp,
    required this.results,
  });

  factory GameLogEntry.fromJson(Map<String, dynamic> json) => _$GameLogEntryFromJson(json);
  Map<String, dynamic> toJson() => _$GameLogEntryToJson(this);
}
