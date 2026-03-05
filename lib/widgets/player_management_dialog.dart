import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';
import '../models/event.dart';

class PlayerManagementDialog extends StatefulWidget {
  final Event currentEvent;
  final Function(String message, {bool isError}) showSnackBar;
  final Function() onRecalculateStats;
  final Function() onPrepareCurrentEventData;
  final Function() onSaveAllEvents;

  const PlayerManagementDialog({
    super.key,
    required this.currentEvent,
    required this.showSnackBar,
    required this.onRecalculateStats,
    required this.onPrepareCurrentEventData,
    required this.onSaveAllEvents,
  });

  @override
  State<PlayerManagementDialog> createState() => _PlayerManagementDialogState();
}

class _PlayerManagementDialogState extends State<PlayerManagementDialog> {
  String? selectedPlayerIdentifier;
  final TextEditingController newNameController = TextEditingController();
  final TextEditingController newIdController = TextEditingController();
  final TextEditingController newTeamController = TextEditingController();
  final Uuid uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("修改选手信息"),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedPlayerIdentifier,
                hint: const Text("选择要修改的选手"),
                items: widget.currentEvent.playerBaseData.map((player) {
                  /// 如果mahjongId为null，则使用一个默认值，例如空字符串
                  final String displayId = player.mahjongId ?? '无ID/昵称选手';
                  return DropdownMenuItem(
                    value: player.mahjongId, /// value仍然可以是null
                    child: Text('${player.name} (${displayId})'),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedPlayerIdentifier = newValue;
                    if (newValue != null) {
                      final playerInfo = widget.currentEvent.playerBaseData.firstWhere(
                          (p) => p.mahjongId == newValue);
                      newNameController.text = playerInfo.name;
                      newIdController.text = playerInfo.mahjongId ?? ''; /// 如果为null，显示空字符串
                      newTeamController.text = playerInfo.team;
                    } else {
                      /// 如果选择了null，清空输入框
                      newNameController.text = '';
                      newIdController.text = '';
                      newTeamController.text = '';
                    }
                  });
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newNameController,
                decoration: const InputDecoration(labelText: "新队员名"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newIdController,
                decoration: const InputDecoration(labelText: "新选手ID/昵称 (可选)"),
              ),
              const SizedBox(height: 10),
              if (widget.currentEvent.isTeamEvent) /// 仅在团队赛事中显示队伍字段
                TextField(
                  controller: newTeamController,
                  decoration: const InputDecoration(labelText: "新队伍名"),
                ),
              if (widget.currentEvent.isTeamEvent)
                const SizedBox(height: 10),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (newNameController.text.trim().isEmpty) {
                    widget.showSnackBar("队员名不能为空。", isError: true);
                    return;
                  }
                  if (widget.currentEvent.isTeamEvent && newTeamController.text.trim().isEmpty) {
                    widget.showSnackBar("队伍名不能为空。", isError: true);
                    return;
                  }

                  /// 选手ID/昵称现在是可选的，如果为空则存储为null
                  final String? mahjongId = newIdController.text.trim().isEmpty
                      ? null
                      : newIdController.text.trim();

                  /// 唯一性校验
                  if (mahjongId != null && widget.currentEvent.playerBaseData.any((p) => p.mahjongId == mahjongId)) {
                    widget.showSnackBar("错误：选手ID已存在。", isError: true);
                    return;
                  }
                  
                  final newPlayer = Player(
                    name: newNameController.text.trim(),
                    mahjongId: mahjongId,
                    team: widget.currentEvent.isTeamEvent ? newTeamController.text.trim() : '个人', /// 为个人赛事设置默认队伍
                  );
                  setState(() {
                    widget.currentEvent.playerBaseData.add(newPlayer);
                  });
                  widget.onPrepareCurrentEventData();
                  await widget.onSaveAllEvents();
                  widget.showSnackBar("新选手已添加。");
                  widget.onRecalculateStats();
                  Navigator.of(context).pop();
                },
                child: const Text("添加新选手"),
              ),
            ],
          );
        },
      ),
      actions: <Widget>[
        TextButton(
          child: const Text("保存更改"),
          onPressed: () async {
            if (selectedPlayerIdentifier == null ||
                newNameController.text.trim().isEmpty) {
              widget.showSnackBar("请选择选手，并确保队员名不为空。", isError: true);
              return;
            }
            if (widget.currentEvent.isTeamEvent && newTeamController.text.trim().isEmpty) {
              widget.showSnackBar("队伍名不能为空。", isError: true);
              return;
            }

            /// 更新时，如果选手ID/昵称为空，则存储为null
            final String? updatedMahjongId = newIdController.text.trim().isEmpty
                ? null
                : newIdController.text.trim();

            /// 唯一性校验
            if (updatedMahjongId != null && updatedMahjongId != selectedPlayerIdentifier && widget.currentEvent.playerBaseData.any((p) => p.mahjongId == updatedMahjongId)) {
              widget.showSnackBar("错误：选手ID已存在。", isError: true);
              return;
            }

            final originalPlayerIndex = widget.currentEvent.playerBaseData.indexWhere(
                (p) => p.mahjongId == selectedPlayerIdentifier);

            if (originalPlayerIndex != -1) {
              widget.currentEvent.playerBaseData[originalPlayerIndex] = Player(
                name: newNameController.text.trim(),
                mahjongId: updatedMahjongId,
                team: widget.currentEvent.isTeamEvent ? newTeamController.text.trim() : '个人', /// 为个人赛事设置默认队伍
              );

              widget.onPrepareCurrentEventData();
              await widget.onSaveAllEvents();
              widget.showSnackBar("选手信息已更新。");
              widget.onRecalculateStats();
              Navigator.of(context).pop();
            } else {
              widget.showSnackBar("找不到原始选手数据。", isError: true);
            }
          },
        ),
        TextButton(
          child: const Text("删除选手"),
          onPressed: () async {
            if (selectedPlayerIdentifier == null) {
              widget.showSnackBar("请选择要删除的选手。", isError: true);
              return;
            }
            final bool? confirm = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("确认删除"),
                  content: Text("确定要永久删除选手 ${selectedPlayerIdentifier ?? '无ID/昵称选手'} 吗？\n此操作无法撤销。"),
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
              /// 检查选手是否有关联的比赛记录
              bool hasGameLogs = widget.currentEvent.gameLog.any(
                (log) => log.results.any((result) => result.id == selectedPlayerIdentifier)
              );

              if (hasGameLogs) {
                widget.showSnackBar("无法删除已参赛的选手。", isError: true);
                return;
              }
              
              setState(() {
                widget.currentEvent.playerBaseData.removeWhere((p) => p.mahjongId == selectedPlayerIdentifier);
              });
              widget.onPrepareCurrentEventData();
              await widget.onSaveAllEvents();
              widget.showSnackBar("选手已删除。");
              widget.onRecalculateStats();
              Navigator.of(context).pop();
            }
          },
        ),
        TextButton(
          child: const Text("取消"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
