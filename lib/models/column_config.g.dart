// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'column_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ColumnConfig _$ColumnConfigFromJson(Map<String, dynamic> json) => ColumnConfig(
  columnName: json['columnName'] as String,
  dataKey: json['dataKey'] as String,
  calculationType: json['calculationType'] as String,
  customFormula: json['customFormula'] as String?,
  displayFormat: json['displayFormat'] as String,
  isPlayerColumn: json['isPlayerColumn'] as bool,
  isTeamColumn: json['isTeamColumn'] as bool,
);

Map<String, dynamic> _$ColumnConfigToJson(ColumnConfig instance) =>
    <String, dynamic>{
      'columnName': instance.columnName,
      'dataKey': instance.dataKey,
      'calculationType': instance.calculationType,
      'customFormula': instance.customFormula,
      'displayFormat': instance.displayFormat,
      'isPlayerColumn': instance.isPlayerColumn,
      'isTeamColumn': instance.isTeamColumn,
    };
