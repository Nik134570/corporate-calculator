import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:calculator/core/api/api_client.dart';
import 'package:calculator/core/di/injection.dart';
import 'package:calculator/core/storage/secure_storage.dart';
import 'package:calculator/features/auth/data/repositories/auth_repository.dart';
import 'package:calculator/features/calculator/data/models/calculation_model.dart';
import 'package:calculator/features/calculator/data/repositories/calculator_repository.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Администратор'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.notifications_outlined), text: 'Запросы'),
            Tab(icon: Icon(Icons.calculate_outlined), text: 'Расчёты'),
            Tab(icon: Icon(Icons.people_outlined), text: 'Пользователи'),
            Tab(icon: Icon(Icons.category_outlined), text: 'Справочники'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await getIt<AuthRepository>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ReviewsTab(),
          _CalculationsTab(),
          _UsersTab(),
          _CatalogTab(),
        ],
      ),
    );
  }
}

// --- Вкладка пользователей ---

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        getIt<ApiClient>().dio.get('/users'),
        getIt<SecureStorage>().getUserId(),
      ]);
      setState(() {
        _users = List<Map<String, dynamic>>.from((results[0] as dynamic).data['data']);
        _currentUserId = results[1] as String?;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.person_add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final isActive = user['isActive'] ?? true;
                  final allowedRoles = ['WORKER', 'ADMIN'];
                  final role = allowedRoles.contains(user['role'])
                  ? user['role']
                  : 'WORKER';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            role == 'ADMIN' ? Colors.blue.shade100 : Colors.grey.shade200,
                        child: Icon(
                          role == 'ADMIN'
                              ? Icons.admin_panel_settings
                              : Icons.engineering,
                          color: role == 'ADMIN'
                              ? Colors.blue.shade700
                              : Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                      title: Text(user['fullName'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(user['email'] ?? '',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Переключатель роли
                          DropdownButton<String>(
                            value: role,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'WORKER', child: Text('Работник')),
                              DropdownMenuItem(value: 'ADMIN', child: Text('Админ')),
                            ],
                            onChanged: user['id'] == _currentUserId
                                ? null
                                : (newRole) => _updateUser(user['id'], {'role': newRole}),
                          ),
                          const SizedBox(width: 8),
                          // Переключатель активности (скрыт для своего аккаунта)
                          if (user['id'] != _currentUserId)
                            Switch(
                              value: isActive,
                              onChanged: (v) => _updateUser(user['id'], {'isActive': v}),
                              activeColor: Colors.green,
                            )
                          else
                            const SizedBox(width: 56),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _updateUser(String id, Map<String, dynamic> data) async {
    try {
      await getIt<ApiClient>().dio.patch('/users/$id', data: data);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCreateDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String role = 'WORKER';
    String? generatedPassword;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Новый пользователь'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (generatedPassword != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Пользователь создан!',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.green)),
                        const SizedBox(height: 8),
                        const Text('Пароль:'),
                        Row(
                          children: [
                            Expanded(
                              child: Text(generatedPassword!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      fontFamily: 'monospace')),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              onPressed: () {
                                // Копировать в буфер
                              },
                            ),
                          ],
                        ),
                        const Text('Сохраните пароль — он больше не будет показан.',
                            style: TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Имя', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Email', border: OutlineInputBorder(), isDense: true),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(
                        labelText: 'Роль', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'WORKER', child: Text('Работник')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Администратор')),
                    ],
                    onChanged: (v) => setState(() => role = v!),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _load();
              },
              child: Text(generatedPassword != null ? 'Закрыть' : 'Отмена'),
            ),
            if (generatedPassword == null)
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
                  try {
                    final response = await getIt<ApiClient>().dio.post('/users', data: {
                      'fullName': nameCtrl.text,
                      'email': emailCtrl.text,
                      'role': role,
                    });
                    setState(() {
                      generatedPassword = response.data['data']['password'];
                    });
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('Создать'),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Вкладка запросов ---

class _ReviewsTab extends StatefulWidget {
  const _ReviewsTab();

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await getIt<CalculatorRepository>().getPendingReviews();
      setState(() { _reviews = data; _loading = false; });
    } catch (e) {
      print('Reviews error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Нет запросов на модерацию',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        itemBuilder: (context, index) => _ReviewCard(
          review: _reviews[index],
          onAction: _load,
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final VoidCallback onAction;

  const _ReviewCard({required this.review, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final calc = CalculationModel.fromJson(review['calculation']);
    final workerName = review['requestedBy']?['fullName'] ?? '';
    final comment = review['comment'];

    final changes = <String>[];
    for (final p in calc.products) {
      if (p.hasPriceChange) {
        changes.add('${p.name}: ${p.originalPricePerSqm?.toStringAsFixed(0)} → ${p.pricePerSqm.toStringAsFixed(0)} ₽/м²');
      }
      for (final proc in p.processings) {
        if (proc.hasPriceChange) {
          changes.add('${proc.name}: ${proc.originalPricePerMeter?.toStringAsFixed(0)} → ${proc.pricePerMeter.toStringAsFixed(0)} ₽/м');
        }
      }
      for (final pw in p.pieceWorks) {
        if (pw.hasPriceChange) {
          changes.add('${pw.name}: ${pw.originalUnitPrice?.toStringAsFixed(0)} → ${pw.unitPrice.toStringAsFixed(0)} ₽/шт');
        }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/calculation-detail', extra: {
          'calculation': calc,
          'productTemplates': <dynamic>[],
          'highlightChanges': true,
          'showEditButton': false,
        }),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(calc.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text('Работник: $workerName',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            Text('Клиент: ${calc.clientName}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),

            if (comment != null && comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.comment_outlined, size: 14, color: Colors.blue.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(comment,
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            if (changes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Text('Изменения цен:',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...changes.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text('• $c',
                              style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
                        )),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showActionDialog(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Отклонить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showActionDialog(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Одобрить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showActionDialog(BuildContext context, bool isApprove) {
    final calc = CalculationModel.fromJson(review['calculation']);
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApprove ? 'Одобрить расчёт?' : 'Отклонить расчёт?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(calc.title),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              decoration: const InputDecoration(
                labelText: 'Комментарий (необязательно)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (isApprove) {
                  await getIt<CalculatorRepository>().approveReview(
                      calc.id, comment: commentCtrl.text.isEmpty ? null : commentCtrl.text);
                } else {
                  await getIt<CalculatorRepository>().rejectReview(
                      calc.id, comment: commentCtrl.text.isEmpty ? null : commentCtrl.text);
                }
                onAction();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isApprove ? 'Одобрить' : 'Отклонить'),
          ),
        ],
      ),
    );
  }
}

// --- Вкладка расчётов ---

class _CalculationsTab extends StatefulWidget {
  const _CalculationsTab();

  @override
  State<_CalculationsTab> createState() => _CalculationsTabState();
}

class _CalculationsTabState extends State<_CalculationsTab> {
  List<CalculationModel> _calculations = [];
  List _productTemplates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        getIt<CalculatorRepository>().getAll(),
        getIt<CalculatorRepository>().getProductTemplates(),
      ]);
      setState(() {
        _calculations = results[0] as List<CalculationModel>;
        _productTemplates = results[1] as List;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _confirmDelete(BuildContext context, CalculationModel calc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить расчёт?'),
        content: Text('«${calc.title}» будет удалён. Работник получит уведомление.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await getIt<CalculatorRepository>().delete(calc.id);
                _load();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'DRAFT': return Colors.green;
      case 'PENDING': return Colors.grey;
      case 'IN_REVIEW': return Colors.orange;
      case 'APPROVED': return Colors.green;
      case 'REJECTED': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'DRAFT': return 'Подтверждён';
      case 'PENDING': return 'Не подтверждён';
      case 'IN_REVIEW': return 'На модерации';
      case 'APPROVED': return 'Одобрен';
      case 'REJECTED': return 'Отклонён';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/new-calculation', extra: {
            'productTemplates': _productTemplates,
          });
          if (mounted) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _calculations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calculate_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Нет расчётов',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 18)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _calculations.length,
                itemBuilder: (context, index) => _AdminCalculationCard(
                  calculation: _calculations[index],
                  statusColor: _statusColor,
                  statusText: _statusText,
                  onTap: () async {
                    await context.push('/calculation-detail', extra: {
                      'calculation': _calculations[index],
                      'productTemplates': _productTemplates,
                    });
                    if (mounted) _load();
                  },
                  onDelete: () => _confirmDelete(context, _calculations[index]),
                ),
              ),
            ),
    );
  }
}

class _AdminCalculationCard extends StatelessWidget {
  final CalculationModel calculation;
  final Color Function(String) statusColor;
  final String Function(String) statusText;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _AdminCalculationCard({
    required this.calculation,
    required this.statusColor,
    required this.statusText,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final c = calculation;
    final statusC = statusColor(c.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок + сумма + удаление
            Row(
              children: [
                Expanded(
                  child: Text(c.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Text('${c.totalPrice.toStringAsFixed(2)} ₽',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 15)),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(c.clientName,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),

            const SizedBox(height: 8),

            // Статус
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusC.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusC.withOpacity(0.4)),
              ),
              child: Text(statusText(c.status),
                  style: TextStyle(fontSize: 12, color: statusC, fontWeight: FontWeight.w500)),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Создан
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Работник',
              value: c.createdByEmail ?? c.createdByName ?? '—',
            ),
            const SizedBox(height: 4),
            _InfoRow(
              icon: Icons.access_time,
              label: 'Создан',
              value: dateFormat.format(c.createdAt.toLocal()),
            ),

            // Запрос на модерацию (кто отправил и когда)
            if (c.reviewRequest != null) ...[
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.send_outlined,
                label: 'Отправил запрос',
                value: c.reviewRequest!.requestedByEmail ??
                    c.reviewRequest!.requestedByName ??
                    '—',
              ),
            ],

            // Кто одобрил/отклонил и когда
            if ((c.status == 'APPROVED' || c.status == 'REJECTED') &&
                c.reviewRequest != null) ...[
              const SizedBox(height: 4),
              _InfoRow(
                icon: c.status == 'APPROVED'
                    ? Icons.verified_outlined
                    : Icons.cancel_outlined,
                label: c.status == 'APPROVED' ? 'Одобрил' : 'Отклонил',
                value: c.reviewRequest!.reviewedByEmail ??
                    c.reviewRequest!.reviewedByName ??
                    '—',
                color: statusC,
              ),
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.check_circle_outline,
                label: c.status == 'APPROVED' ? 'Одобрен' : 'Отклонён',
                value: dateFormat.format(c.reviewRequest!.updatedAt.toLocal()),
                color: statusC,
              ),
            ],

            // Комментарий администратора
            if (c.reviewRequest?.adminComment != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusC.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.comment_outlined, size: 13, color: statusC),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        c.reviewRequest!.adminComment!,
                        style: TextStyle(fontSize: 12, color: statusC),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey.shade600;
    return Row(
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 5),
        Text('$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        Expanded(
          child: Text(value,
              style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// --- Вкладка справочников ---

class _CatalogTab extends StatelessWidget {
  const _CatalogTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _CatalogSection(title: 'Материалы', icon: Icons.layers_outlined,
            onTap: () => context.push('/admin/catalog/materials')),
        _CatalogSection(title: 'Наименования изделий', icon: Icons.view_list_outlined,
            onTap: () => context.push('/admin/catalog/product-templates')),
        _CatalogSection(title: 'Виды обработки', icon: Icons.carpenter_outlined,
            onTap: () => context.push('/admin/catalog/processings')),
        _CatalogSection(title: 'Штучные работы', icon: Icons.build_outlined,
            onTap: () => context.push('/admin/catalog/piece-works')),
        _CatalogSection(title: 'Скидки', icon: Icons.discount_outlined,
            onTap: () => context.push('/admin/catalog/discounts')),
        _CatalogSection(title: 'Доп. услуги', icon: Icons.miscellaneous_services_outlined,
            onTap: () => context.push('/admin/catalog/services')),
        _CatalogSection(title: 'Настройки (цена закалки)', icon: Icons.settings_outlined,
            onTap: () => context.push('/admin/settings')),
        _CatalogSection(title: 'Журнал аудита', icon: Icons.history_outlined,
            onTap: () => context.push('/admin/audit')),
      ],
    );
  }
}

class _CatalogSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _CatalogSection({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}