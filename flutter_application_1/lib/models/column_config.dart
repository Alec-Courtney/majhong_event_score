import 'package:json_annotation/json_annotation.dart';

part 'column_config.g.dart';

@JsonSerializable()
class ColumnConfig {
  /// 显示名称（例如“队员”、“分数”）
  String columnName;
  /// 对应数据模型（Player/Team）中的字段名
  String dataKey;
  /// 预设计算类型（例如 "none", "avoidFourthRate", "consecutiveWinRate", "averageRank", "averageGameScore"）
  String calculationType;
  /// 自定义计算公式（保留接口，暂时不实现解析）
  String? customFormula;
  /// 显示格式（例如 "fixed1", "percent1", "integer"）
  String displayFormat;
  /// 是否是选手表格列
  bool isPlayerColumn;
  /// 是否是队伍表格列
  bool isTeamColumn;

  ColumnConfig({
    required this.columnName,
    required this.dataKey,
    required this.calculationType,
    this.customFormula,
    required this.displayFormat,
    required this.isPlayerColumn,
    required this.isTeamColumn,
  });

  factory ColumnConfig.fromJson(Map<String, dynamic> json) => _$ColumnConfigFromJson(json);
  Map<String, dynamic> toJson() => _$ColumnConfigToJson(this);
}
