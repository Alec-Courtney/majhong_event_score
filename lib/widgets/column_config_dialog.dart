import 'package:flutter/material.dart';
import '../models/column_config.dart';
import '../models/event.dart';

class ColumnConfigDialog extends StatefulWidget {
  final Event currentEvent;
  final Function(String message, {bool isError}) showSnackBar;
  final VoidCallback onRecalculateStats;
  final VoidCallback onSaveAllEvents;
  final VoidCallback openEventManagementWindow;

  const ColumnConfigDialog({
    super.key,
    required this.currentEvent,
    required this.showSnackBar,
    required this.onRecalculateStats,
    required this.onSaveAllEvents,
    required this.openEventManagementWindow,
  });

  @override
  State<ColumnConfigDialog> createState() => _ColumnConfigDialogState();
}

class _ColumnConfigDialogState extends State<ColumnConfigDialog> {
  late List<ColumnConfig> _playerColumns;
  late List<ColumnConfig> _teamColumns;

  @override
  void initState() {
    super.initState();
    _playerColumns = List.from(widget.currentEvent.playerColumns);
    _teamColumns = List.from(widget.currentEvent.teamColumns);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("配置表格列"),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return DefaultTabController(
            length: 2, // Player Columns and Team Columns
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: "选手列"),
                    Tab(text: "队伍列"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Player Columns Tab
                      _buildColumnList(
                        context,
                        _playerColumns,
                        (newColumns) {
                          setState(() {
                            _playerColumns = newColumns;
                          });
                        },
                        isPlayerColumn: true,
                      ),
                      // Team Columns Tab
                      _buildColumnList(
                        context,
                        _teamColumns,
                        (newColumns) {
                          setState(() {
                            _teamColumns = newColumns;
                          });
                        },
                        isPlayerColumn: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: <Widget>[
        TextButton(
          child: const Text("保存"),
          onPressed: () async {
            // Update the event object with new column configurations
            setState(() {
              widget.currentEvent.playerColumns = _playerColumns;
              widget.currentEvent.teamColumns = _teamColumns;
            });
            widget.onSaveAllEvents(); // Removed await
            widget.showSnackBar("表格列配置已更新。");
            widget.onRecalculateStats();
            Navigator.of(context).pop(); // Close column config dialog
            // Reopen event management dialog
            widget.openEventManagementWindow();
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

  Widget _buildColumnList(
    BuildContext context,
    List<ColumnConfig> columns,
    Function(List<ColumnConfig>) onReorder, {
    required bool isPlayerColumn,
  }) {
    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            itemCount: columns.length,
            itemBuilder: (context, index) {
              final column = columns[index];
              return Card(
                key: ValueKey(column.columnName), // Unique key for reordering
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: column.columnName,
                        decoration: const InputDecoration(labelText: '显示名称'),
                        onChanged: (value) {
                          setState(() {
                            column.columnName = value;
                            onReorder(columns); // Notify parent to update state
                          });
                        },
                      ),
                      TextFormField(
                        initialValue: column.dataKey,
                        decoration: const InputDecoration(labelText: '数据键'),
                        onChanged: (value) {
                          setState(() {
                            column.dataKey = value;
                            onReorder(columns); // Notify parent to update state
                          });
                        },
                      ),
                      TextFormField(
                        initialValue: column.calculationType,
                        decoration: const InputDecoration(labelText: '计算类型 (可选)'),
                        onChanged: (value) {
                          setState(() {
                            column.calculationType = value;
                            onReorder(columns); // Notify parent to update state
                          });
                        },
                      ),
                      TextFormField(
                        initialValue: column.displayFormat,
                        decoration: const InputDecoration(labelText: '显示格式 (可选)'),
                        onChanged: (value) {
                          setState(() {
                            column.displayFormat = value;
                            onReorder(columns); // Notify parent to update state
                          });
                        },
                      ),
                      TextFormField(
                        initialValue: column.customFormula,
                        decoration: const InputDecoration(labelText: '自定义公式 (待实现)'),
                        onChanged: (value) {
                          setState(() {
                            column.customFormula = value;
                            onReorder(columns); // Notify parent to update state
                          });
                        },
                        enabled: false, // Disable for now
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                columns.removeAt(index);
                                onReorder(columns); // Notify parent to update state
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final ColumnConfig item = columns.removeAt(oldIndex);
                columns.insert(newIndex, item);
                onReorder(columns); // Notify parent to update state
              });
            },
          ),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              columns.add(ColumnConfig(
                columnName: '新列',
                dataKey: 'newKey',
                calculationType: '', // Provide default empty string
                displayFormat: '', // Provide default empty string
                isPlayerColumn: isPlayerColumn,
                isTeamColumn: !isPlayerColumn,
              ));
              onReorder(columns); // Notify parent to update state
            });
          },
          child: const Text("添加新列"),
        ),
      ],
    );
  }
}
