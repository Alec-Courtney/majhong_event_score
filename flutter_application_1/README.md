# 立直麻将赛事计分系统

这是一个基于 Flutter 开发的立直麻将赛事计分系统，旨在为麻将比赛提供便捷的选手管理、比赛记录、积分计算和数据分析功能。系统支持四人麻将和三人麻将两种模式，并可自定义赛事规则和计分方式。

## 主要功能

- **赛事管理**：创建、加载、保存和删除不同的麻将赛事，每个赛事拥有独立的选手数据、比赛记录和规则配置。
- **选手管理**：添加、编辑和删除选手信息，包括选手姓名、雀魂ID和所属队伍。
- **比赛记录**：记录每局比赛的选手得分、顺位和最终得分，并支持对历史记录进行修改和删除。
- **积分计算**：根据预设的规则（如精算原点、顺位点数）自动计算选手的最终得分，并实时更新选手和队伍的积分榜。
- **数据分析**：提供选手和队伍的各项统计数据，包括总分、半庄数、各顺位次数、最高得点、避四率、连对率、平均顺位和平均场分等。
- **图文报告导出**：支持将选手数据榜和队伍积分榜导出为图片报告。
- **数据持久化**：所有赛事数据通过 `shared_preferences` 持久化到本地存储，确保数据不会丢失。

## 数据成员设计

### `Event` (赛事)
- `eventId` (String): 唯一赛事ID。
- `eventName` (String): 赛事名称。
- `mahjongType` (String): 麻将类型 ("四人麻将" 或 "三人麻将")。
- `isTeamEvent` (bool): 是否为团队赛事。
- `scoreCheckTotal` (int): 比赛总分检查值 (例如四人麻将为 100000)。
- `calculationBasePoint` (int): 精算原点 (例如 30000)。
- `basePoints` (Map<String, double>): 顺位基础点数，键为顺位 ("1", "2", "3", "4")。
- `playerColumns` (List<ColumnConfig>): 选手表格的列配置。
- `teamColumns` (List<ColumnConfig>): 队伍表格的列配置。
- `playerBaseData` (List<Player>): 赛事专属的选手基础数据。
- `gameLog` (List<GameLogEntry>): 赛事专属的比赛记录。

### `Player` (选手)
- `name` (String): 选手姓名。
- `mahjongId` (String?): 雀魂ID (可为空)。
- `team` (String): 所属队伍。
- `score` (double): 总得分。
- `gamesPlayed` (int): 参加半庄数。
- `rank1`, `rank2`, `rank3`, `rank4` (int): 各顺位次数。
- `highestScore` (int): 最高得点。
- `avoidFourthRate` (double): 避四率。
- `consecutiveWinRate` (double): 连对率。
- `averageRank` (double): 平均顺位。
- `averageGameScore` (double): 平均场分。

### `Team` (队伍)
- `name` (String): 队伍名称。
- `score` (double): 总得分。
- `scoreDifference` (double): 与上一名队伍的分差。
- `gamesPlayed` (int): 参加半庄数。
- `rank1`, `rank2`, `rank3`, `rank4` (int): 各顺位次数。

### `GameLogEntry` (比赛记录条目)
- `gameId` (String): 唯一比赛ID。
- `timestamp` (String): 比赛时间戳。
- `results` (List<GameResult>): 比赛结果列表。

### `GameResult` (比赛结果)
- `id` (String): 雀魂ID。
- `score` (int): 场内分数。
- `rank` (int): 顺位。
- `finalScore` (double): 最终得分 (pt)。

### `ColumnConfig` (列配置)
- `columnName` (String): 显示名称。
- `dataKey` (String): 对应数据模型中的字段名。
- `calculationType` (String): 预设计算类型 (例如 "none", "avoidFourthRate")。
- `customFormula` (String?): 自定义计算公式 (保留接口)。
- `displayFormat` (String): 显示格式 (例如 "fixed1", "percent1", "integer")。
- `isPlayerColumn` (bool): 是否是选手表格列。
- `isTeamColumn` (bool): 是否是队伍表格列。

## 数据持久性设计

系统使用 `shared_preferences` 进行数据持久化。所有赛事数据 (`allEvents`) 在应用启动时从本地存储加载，并在每次数据更新（如添加比赛记录、修改选手信息、创建新赛事等）后保存到本地。`allEvents` 是一个包含所有 `Event` 对象的列表，每个 `Event` 对象内部包含了该赛事的所有 `Player` 基础数据和 `GameLogEntry` 比赛记录。通过 `json_annotation` 库，模型对象可以方便地序列化为 JSON 字符串并存储，反之亦然。

## 如何运行

1. 确保您已安装 Flutter SDK。
2. 克隆本项目到本地。
3. 在项目根目录运行 `flutter pub get` 安装依赖。
4. 运行 `flutter run` 启动应用。
.
