import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calculator/core/api/api_client.dart';
import 'package:calculator/core/di/injection.dart';
import 'package:calculator/core/theme/app_styles.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await getIt<ApiClient>().dio.get('/audit');
      setState(() {
        _logs = List<Map<String, dynamic>>.from(response.data['data']);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'CALCULATION_CREATED':   return Icons.add_circle_outline;
      case 'CALCULATION_APPROVED':  return Icons.check_circle_outline;
      case 'CALCULATION_REJECTED':  return Icons.cancel_outlined;
      case 'REVIEW_SUBMITTED':      return Icons.send_outlined;
      case 'CALCULATION_DELETED':   return Icons.delete_outline_rounded;
      case 'CALCULATION_RESTORED':  return Icons.restore_rounded;
      default:                      return Icons.info_outline;
    }
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'CALCULATION_CREATED':   return AppStyles.primary;
      case 'CALCULATION_APPROVED':  return AppStyles.success;
      case 'CALCULATION_REJECTED':  return AppStyles.danger;
      case 'REVIEW_SUBMITTED':      return AppStyles.warning;
      case 'CALCULATION_DELETED':   return AppStyles.danger;
      case 'CALCULATION_RESTORED':  return AppStyles.success;
      default:                      return AppStyles.textMuted;
    }
  }

  String _actionText(String action) {
    switch (action) {
      case 'CALCULATION_CREATED':   return 'Создан расчёт';
      case 'CALCULATION_APPROVED':  return 'Расчёт одобрен';
      case 'CALCULATION_REJECTED':  return 'Расчёт отклонён';
      case 'REVIEW_SUBMITTED':      return 'Отправлен на модерацию';
      case 'CALCULATION_DELETED':   return 'Расчёт удалён';
      case 'CALCULATION_RESTORED':  return 'Расчёт восстановлен';
      default:                      return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      backgroundColor: AppStyles.background,
      appBar: AppBar(title: const Text('Журнал аудита')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Text('Нет записей', style: AppStyles.subtitleStyle),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: AppStyles.listPadding,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log      = _logs[index];
                      final action   = log['action'] ?? '';
                      final color    = _actionColor(action);
                      final createdAt = DateTime.tryParse(log['createdAt'] ?? '');

                      return Card(
                        margin: AppStyles.cardMarginSmall,
                        shape: AppStyles.cardShape(10),
                        child: Padding(
                          padding: const EdgeInsets.all(AppStyles.spaceM),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppStyles.spaceS),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_actionIcon(action), color: color, size: 20),
                              ),
                              const SizedBox(width: AppStyles.spaceM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _actionText(action),
                                      style: AppStyles.labelBold.copyWith(color: color),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(log['entityTitle'] ?? '', style: AppStyles.titleMedium),
                                    const SizedBox(height: 2),
                                    Text(log['userFullName'] ?? '', style: AppStyles.captionStyle),
                                    if (log['details'] != null &&
                                        log['details'].toString().isNotEmpty) ...[
                                      const SizedBox(height: AppStyles.spaceXS),
                                      Text(
                                        log['details'],
                                        style: AppStyles.captionStyle.copyWith(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (createdAt != null)
                                Text(
                                  dateFormat.format(createdAt),
                                  style: AppStyles.captionStyle.copyWith(fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
