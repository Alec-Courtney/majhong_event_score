import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/game_log.dart';
import '../models/player.dart';
import 'package:uuid/uuid.dart'; /// Import Uuid for gameId generation

class GameLogManagementDialog extends StatefulWidget {
  final Event currentEvent;
  final Function(String message, {bool isError}) showSnackBar;
  final Function(List<GameResult> gameResults, {String? existingGameId}) showAdjustmentWindow;
  final Function() onRecalculateStats;
  final Function() onSaveAllEvents;

  const GameLogManagementDialog({
    super.key,
    required this.currentEvent,
    required this.showSnackBar,
    required this.showAdjustmentWindow,
    required this.onRecalculateStats,
    required this.onSaveAllEvents,
  });

  @override
  State<GameLogManagementDialog> createState() => _GameLogManagementDialogState();
}

class _GameLogManagementDialogState extends State<GameLogManagementDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("管理比赛记录"),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Expanded(
              child: widget.currentEvent.gameLog.isEmpty
                  ? const Center(child: Text('暂无数据'))
                  : ListView.builder(
                      itemCount: widget.currentEvent.gameLog.length,
                      itemBuilder: (context, index) {
                        final game = widget.currentEvent.gameLog[index];
                        final players = game.results.map((r) {
                          /// 尝试找到选手的名字，如果找不到，就用ID
                          final playerName = widget.currentEvent.playerBaseData
                              .firstWhere((p) => p.mahjongId == r.id, orElse: () => Player(name: r.id, mahjongId: r.id, team: ''))
                              .name;
                          return playerName;
                        }).join(', ');
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('游戏ID: ${game.gameId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text('日期: ${game.timestamp}'),
                                      Text('选手: $players'),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.of(context).pop(); /// 关闭当前对话框
                                    widget.showAdjustmentWindow(game.results, existingGameId: game.gameId);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    final bool? confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("确认删除"),
                                          content: Text("确定要永久删除比赛记录 ${game.gameId} 吗？\n此操作无法撤销。"),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text("取消"),
                                              onPressed: () {
                                                Navigator.of(context).pop(false);
                                              },
                                            ),
                                            TextButton(
                                              child: const Text("删除"),
                                              onPressed: () {
                                                Navigator.of(context).pop(true);
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (confirm == true) {
                                      setState(() {
                                        widget.currentEvent.gameLog.removeWhere((g) => g.gameId == game.gameId);
                                      });
                                      await widget.onSaveAllEvents();
                                      widget.showSnackBar("比赛记录已删除。");
                                      widget.onRecalculateStats();
                                      /// 列表将自动更新
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text("关闭"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
