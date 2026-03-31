import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:calculator/core/di/injection.dart';
import 'package:calculator/features/auth/data/repositories/auth_repository.dart';
import 'package:calculator/features/calculator/data/models/calculation_model.dart';
import 'package:calculator/features/calculator/data/repositories/calculator_repository.dart';
import 'package:calculator/features/calculator/presentation/bloc/calculator_bloc.dart';

class CalculationsListScreen extends StatelessWidget {
  const CalculationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CalculatorBloc(getIt<CalculatorRepository>())
        ..add(CalculatorLoadRequested()),
      child: const _CalculationsListView(),
    );
  }
}

class _CalculationsListView extends StatelessWidget {
  const _CalculationsListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Мои расчёты'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выход',
            onPressed: () async {
              await getIt<AuthRepository>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<CalculatorBloc, CalculatorState>(
        builder: (context, state) => FloatingActionButton(
          onPressed: () async {
            if (state is CalculatorLoaded) {
              await context.push('/new-calculation', extra: {
                'materials': state.materials,
              });
              if (context.mounted) {
                context.read<CalculatorBloc>().add(CalculatorLoadRequested());
              }
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
      body: BlocBuilder<CalculatorBloc, CalculatorState>(
        builder: (context, state) {
          if (state is CalculatorLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CalculatorError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<CalculatorBloc>()
                        .add(CalculatorLoadRequested()),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }
          if (state is CalculatorLoaded) {
            if (state.calculations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calculate_outlined,
                        size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Нет расчётов',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('Нажмите + чтобы создать новый',
                        style: TextStyle(color: Colors.grey.shade400)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context
                  .read<CalculatorBloc>()
                  .add(CalculatorLoadRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.calculations.length,
                itemBuilder: (context, index) => _CalculationCard(
                  calculation: state.calculations[index],
                  materials: state.materials,
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _CalculationCard extends StatelessWidget {
  final CalculationModel calculation;
  final List materials;

  const _CalculationCard({required this.calculation, required this.materials});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final bloc = context.read<CalculatorBloc>();
          await context.push('/calculation-detail', extra: {
            'calculation': calculation,
            'materials': materials,
          });
          if (context.mounted) bloc.add(CalculatorLoadRequested());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      calculation.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  // Кнопка редактирования
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Редактировать',
                    onPressed: () async {
                      final bloc = context.read<CalculatorBloc>();
                      await context.push('/edit-calculation', extra: {
                        'materials': materials,
                        'calculation': calculation,
                      });
                      if (context.mounted) bloc.add(CalculatorLoadRequested());
                    },
                  ),
                  const SizedBox(width: 12),
                  // Кнопка удаления
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Удалить',
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(calculation.clientName,
                  style: TextStyle(color: Colors.grey.shade600)),
              if (calculation.clientPhone != null) ...[
                const SizedBox(height: 2),
                Text(calculation.clientPhone!,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
              const SizedBox(height: 8),

              // Разбивка
              if (calculation.products.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.layers_outlined, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '${calculation.products.length} изд. — ${calculation.productsTotal.toStringAsFixed(2)} ₽',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                    if (calculation.servicesTotal > 0) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.miscellaneous_services_outlined,
                          size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Услуги — ${calculation.servicesTotal.toStringAsFixed(2)} ₽',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(calculation.createdAt),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                  Text(
                    '${calculation.totalPrice.toStringAsFixed(2)} ₽',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Статусная плашка
              _StatusBadge(status: calculation.status, isDraft: calculation.isDraft),

              // Комментарий от администратора
              if (calculation.reviewRequest?.adminComment != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: calculation.status == 'APPROVED'
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 13,
                        color: calculation.status == 'APPROVED'
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          calculation.reviewRequest!.adminComment!,
                          style: TextStyle(
                            fontSize: 12,
                            color: calculation.status == 'APPROVED'
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
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

  void _confirmDelete(BuildContext context) {
    final bloc = context.read<CalculatorBloc>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить расчёт?'),
        content: Text('Расчёт "${calculation.title}" будет удалён.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              bloc.add(CalculatorDeleteRequested(calculation.id));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isDraft;
  const _StatusBadge({required this.status, required this.isDraft});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'DRAFT':
        if (this.isDraft) {
    color = Colors.grey.shade400; 
    text = 'Черновик'; 
    icon = Icons.edit_note_outlined;
  } else {
    color = Colors.green; 
    text = 'Подтверждён'; 
    icon = Icons.check_circle_outline;
  }
        break;
      case 'PENDING':
        color = Colors.grey; text = 'Не подтверждён'; icon = Icons.radio_button_unchecked;
        break;
      case 'IN_REVIEW':
        color = Colors.orange; text = 'На модерации'; icon = Icons.pending_outlined;
        break;
      case 'APPROVED':
        color = Colors.green; text = 'Одобрен'; icon = Icons.verified_outlined;
        break;
      case 'REJECTED':
        color = Colors.red; text = 'Отклонён'; icon = Icons.cancel_outlined;
        break;
      default:
        color = Colors.grey; text = status; icon = Icons.circle_outlined;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
