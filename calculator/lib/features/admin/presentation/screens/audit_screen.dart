import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calculator/core/api/api_client.dart';
import 'package:calculator/core/di/injection.dart';

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
      case 'CALCULATION_CREATED': return Icons.add_circle_outline;
      case 'CALCULATION_APPROVED': return Icons.check_circle_outline;
      case 'CALCULATION_REJECTED': return Icons.cancel_outlined;
      case 'REVIEW_SUBMITTED': return Icons.send_outlined;
      default: return Icons.info_outline;
    }
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'CALCULATION_CREATED': return Colors.blue;
      case 'CALCULATION_APPROVED': return Colors.green;
      case 'CALCULATION_REJECTED': return Colors.red;
      case 'REVIEW_SUBMITTED': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _actionText(String action) {
    switch (action) {
      case 'CALCULATION_CREATED': return 'Создан расчёт';
      case 'CALCULATION_APPROVED': return 'Расчёт одобрен';
      case 'CALCULATION_REJECTED': return 'Расчёт отклонён';
      case 'REVIEW_SUBMITTED': return 'Отправлен на модерацию';
      default: return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Журнал аудита'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Text('Нет записей',
                      style: TextStyle(color: Colors.grey.shade500)),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final action = log['action'] ?? '';
                      final color = _actionColor(action);
                      final createdAt = DateTime.tryParse(log['createdAt'] ?? '');

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_actionIcon(action),
                                    color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_actionText(action),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: color,
                                            fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text(log['entityTitle'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Text(log['userFullName'] ?? '',
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12)),
                                    if (log['details'] != null &&
                                        log['details'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(log['details'],
                                          style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic)),
                                    ],
                                  ],
                                ),
                              ),
                              if (createdAt != null)
                                Text(
                                  dateFormat.format(createdAt),
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 11),
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