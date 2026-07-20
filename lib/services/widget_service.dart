import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:isar/isar.dart';
import 'database/isar_service.dart';
import 'database/collections/task_collection.dart';
import 'database/collections/transaction_collection.dart';
import 'database/collections/client_collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/formatters.dart';

class WidgetService {
  static const String _tasksWidgetName = 'CriticalTasksWidgetProvider';
  static const String _overviewWidgetName = 'AgencyOverviewWidgetProvider';
  static const String _targetWidgetName = 'TargetProgressWidgetProvider';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId('group.right_craft_media_os');
  }

  static Future<void> syncWidgets() async {
    try {
      if (!IsarService.instance.isOpen) return;

      await syncTasksWidget();
      await syncOverviewWidget();
      await syncTargetProgressWidget();
    } catch (e) {
      debugPrint('Error syncing widgets: $e');
    }
  }

  static Future<void> syncTasksWidget() async {
    final isar = IsarService.instance;

    final tasks = await isar.taskItems
        .filter()
        .isCompletedEqualTo(false)
        .and()
        .group((q) => q.priorityEqualTo('Critical').or().priorityEqualTo('High'))
        .sortByCreatedAtDesc()
        .limit(3)
        .findAll();

    final taskTitles = tasks.map((t) => t.title).toList();
    final taskPriorities = tasks.map((t) => t.priority).toList();

    // Fill empty slots if less than 3
    while (taskTitles.length < 3) {
      taskTitles.add('');
      taskPriorities.add('');
    }

    await HomeWidget.saveWidgetData<String>('task_1_title', taskTitles[0]);
    await HomeWidget.saveWidgetData<String>('task_1_priority', taskPriorities[0]);
    await HomeWidget.saveWidgetData<String>('task_2_title', taskTitles[1]);
    await HomeWidget.saveWidgetData<String>('task_2_priority', taskPriorities[1]);
    await HomeWidget.saveWidgetData<String>('task_3_title', taskTitles[2]);
    await HomeWidget.saveWidgetData<String>('task_3_priority', taskPriorities[2]);

    await HomeWidget.updateWidget(name: _tasksWidgetName);
  }

  static Future<void> syncOverviewWidget() async {
    final isar = IsarService.instance;

    final clients = await isar.clientItems.filter().statusEqualTo('Active').count();
    
    final transactions = await isar.transactionItems.where().findAll();
    double revenue = 0;
    double expenses = 0;
    for (var tx in transactions) {
      if (tx.type == 'Income') {
        revenue += tx.amount;
      } else if (tx.type == 'Expense') {
        expenses += tx.amount;
      }
    }

    await HomeWidget.saveWidgetData<String>('active_clients', clients.toString());
    await HomeWidget.saveWidgetData<String>('total_revenue', AppFormatters.compactCurrency(revenue));
    await HomeWidget.saveWidgetData<String>('total_expenses', AppFormatters.compactCurrency(expenses));

    await HomeWidget.updateWidget(name: _overviewWidgetName);
  }

  static Future<void> syncTargetProgressWidget() async {
    final isar = IsarService.instance;
    final clients = await isar.clientItems
        .filter()
        .isRetainerEqualTo(true)
        .and()
        .statusEqualTo('Active')
        .not().syncStatusEqualTo('pendingDelete')
        .findAll();

    double currentMrr = 0;
    for (var c in clients) {
      currentMrr += c.retainerAmount;
    }

    final prefs = await SharedPreferences.getInstance();
    final wsId = prefs.getString('current_workspace_id');
    int mrrTarget = 10000;
    if (wsId != null) {
      mrrTarget = prefs.getInt('ws_${wsId}_mrr_target') ?? 10000;
    }

    int progress = 0;
    if (mrrTarget > 0) {
      progress = ((currentMrr / mrrTarget) * 100).toInt().clamp(0, 100);
    }

    await HomeWidget.saveWidgetData<String>('mrr_current', AppFormatters.compactCurrency(currentMrr));
    await HomeWidget.saveWidgetData<String>('mrr_target', AppFormatters.compactCurrency(mrrTarget.toDouble()));
    await HomeWidget.saveWidgetData<int>('mrr_progress_percent', progress);

    await HomeWidget.updateWidget(name: _targetWidgetName);
  }
}
