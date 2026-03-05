// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
  eventId: json['eventId'] as String,
  eventName: json['eventName'] as String,
  mahjongType: json['mahjongType'] as String,
  isTeamEvent: json['isTeamEvent'] as bool,
  scoreCheckTotal: (json['scoreCheckTotal'] as num).toInt(),
  calculationBasePoint:
      (json['calculationBasePoint'] as num?)?.toInt() ?? 30000,
  basePoints: (json['basePoints'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
  playerColumns: (json['playerColumns'] as List<dynamic>)
      .map((e) => ColumnConfig.fromJson(e as Map<String, dynamic>))
      .toList(),
  teamColumns: (json['teamColumns'] as List<dynamic>)
      .map((e) => ColumnConfig.fromJson(e as Map<String, dynamic>))
      .toList(),
  playerBaseData: (json['playerBaseData'] as List<dynamic>)
      .map((e) => Player.fromJson(e as Map<String, dynamic>))
      .toList(),
  gameLog: (json['gameLog'] as List<dynamic>)
      .map((e) => GameLogEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
  'eventId': instance.eventId,
  'eventName': instance.eventName,
  'mahjongType': instance.mahjongType,
  'isTeamEvent': instance.isTeamEvent,
  'scoreCheckTotal': instance.scoreCheckTotal,
  'calculationBasePoint': instance.calculationBasePoint,
  'basePoints': instance.basePoints,
  'playerColumns': instance.playerColumns.map((e) => e.toJson()).toList(),
  'teamColumns': instance.teamColumns.map((e) => e.toJson()).toList(),
  'playerBaseData': instance.playerBaseData.map((e) => e.toJson()).toList(),
  'gameLog': instance.gameLog.map((e) => e.toJson()).toList(),
};
