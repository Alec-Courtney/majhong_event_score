// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameResult _$GameResultFromJson(Map<String, dynamic> json) => GameResult(
  id: json['id'] as String,
  score: (json['score'] as num).toInt(),
  rank: (json['rank'] as num).toInt(),
  finalScore: (json['final_score'] as num).toDouble(),
);

Map<String, dynamic> _$GameResultToJson(GameResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'score': instance.score,
      'rank': instance.rank,
      'final_score': instance.finalScore,
    };

GameLogEntry _$GameLogEntryFromJson(Map<String, dynamic> json) => GameLogEntry(
  gameId: json['game_id'] as String,
  timestamp: json['timestamp'] as String,
  results: (json['results'] as List<dynamic>)
      .map((e) => GameResult.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GameLogEntryToJson(GameLogEntry instance) =>
    <String, dynamic>{
      'game_id': instance.gameId,
      'timestamp': instance.timestamp,
      'results': instance.results,
    };
