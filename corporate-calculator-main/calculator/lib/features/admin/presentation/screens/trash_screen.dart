import 'package:flutter/material.dart';
import 'package:calculator/core/di/injection.dart';
import 'package:calculator/core/theme/app_styles.dart';
import 'package:calculator/features/calculator/data/models/calculation_model.dart';
import 'package:calculator/features/calculator/data/repositories/calculator_repository.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<CalculationModel> _items = [];
  bool _loading = true;
  final Set<String> _restoring = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await getIt<CalculatorRepository>().getTrash();
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restore(CalculationModel calc) async {
    setState(() => _restoring.add(calc.id));
    try {
      await getIt<CalculatorRepository>().restore(calc.id);
      if (mounted) {
        setState(() { _items.removeWhere((c) => c.id == calc.id); });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('«${calc.title}» восстановлен'),
            backgroundColor: AppStyles.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppStyles.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _restoring.remove(calc.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      appBar: AppBar(
        title: const Text('Корзина'),
        backgroundColor: AppStyles.appBarBg,
        foregroundColor: AppStyles.appBarFg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Обновить',
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: AppStyles.listPadding,
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _TrashCard(
                      calc: _items[i],
                      restoring: _restoring.contains(_items[i].id),
                      onRestore: () => _restore(_items[i]),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, size: 64, color: AppStyles.textMuted),
            const SizedBox(height: AppStyles.spaceM),
            Text('Корзина пуста', style: AppStyles.subtitleStyle),
          ],
        ),
      );
}

class _TrashCard extends StatelessWidget {
  final CalculationModel calc;
  final bool restoring;
  final VoidCallback onRestore;

  const _TrashCard({
    required this.calc,
    required this.restoring,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final deletedDate = calc.deletedAt != null
        ? '${calc.deletedAt!.day.toString().padLeft(2, '0')}.${calc.deletedAt!.month.toString().padLeft(2, '0')}.${calc.deletedAt!.year}'
        : '—';

    return Card(
      margin: AppStyles.cardMargin,
      shape: AppStyles.cardShape(),
      elevation: 2,
      child: Padding(
        padding: AppStyles.cardPadding,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppStyles.danger.withOpacity(0.08),
                borderRadius: AppStyles.radiusS,
              ),
              child: Icon(Icons.delete_rounded, color: AppStyles.danger.withOpacity(0.7), size: 22),
            ),
            const SizedBox(width: AppStyles.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(calc.title, style: AppStyles.titleBold),
                  const SizedBox(height: 2),
                  Text(calc.clientName, style: AppStyles.subtitleStyle),
                  const SizedBox(height: 2),
                  Text(
                    'Удалён: $deletedDate',
                    style: AppStyles.captionStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppStyles.spaceS),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${calc.totalPrice.toStringAsFixed(0)} ₽',
                  style: AppStyles.amountMedium,
                ),
                const SizedBox(height: AppStyles.spaceS),
                restoring
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton.icon(
                        onPressed: onRestore,
                        icon: const Icon(Icons.restore_rounded, size: 16),
                        label: const Text('Восстановить'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppStyles.success,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
