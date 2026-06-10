import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:calculator/core/di/injection.dart';
import 'package:calculator/core/services/pdf_service.dart';
import 'package:calculator/core/theme/app_styles.dart';
import 'package:calculator/features/calculator/data/models/calculation_model.dart';
import 'package:calculator/features/calculator/data/models/product_template_model.dart';
import 'package:calculator/features/calculator/presentation/bloc/calculator_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CalculationDetailScreen extends StatelessWidget {
  final CalculationModel calculation;
  final List<ProductTemplateModel> productTemplates;
  final bool highlightChanges;
  final bool showEditButton;

  const CalculationDetailScreen({
    super.key,
    required this.calculation,
    required this.productTemplates,
    this.highlightChanges = false,
    this.showEditButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      backgroundColor: AppStyles.background,
      appBar: AppBar(
        title: Text(calculation.title),
        backgroundColor: AppStyles.appBarBg,
        foregroundColor: AppStyles.appBarFg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Скачать PDF',
            onPressed: () => PdfService.generateAndPrint(calculation),
          ),
        ],
      ),
      bottomNavigationBar: showEditButton ? Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: ElevatedButton.icon(
          onPressed: () async {
            await context.push('/edit-calculation', extra: {
              'productTemplates': productTemplates,
              'calculation': calculation,
            });
            if (context.mounted) {
              context.read<CalculatorBloc>().add(CalculatorLoadRequested());
              context.pop();
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: AppStyles.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusL),
          ),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Редактировать', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ) : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text('Информация о заказе',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow('Заказчик', calculation.clientName),
                  if (calculation.clientPhone != null)
                    _InfoRow('Телефон', calculation.clientPhone!),
                  if (calculation.clientAddress != null)
                    _InfoRow('Адрес', calculation.clientAddress!),
                  if (calculation.comment != null)
                    _InfoRow('Комментарий', calculation.comment!),
                  _InfoRow('Создан', dateFormat.format(calculation.createdAt)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Изделия',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text('${calculation.products.length} шт',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...calculation.products.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProductCard(index: e.key, product: e.value, highlightChanges: highlightChanges),
                )),
            const SizedBox(height: 4),

            if (calculation.servicesTotal > 0) ...[
              _InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.miscellaneous_services_outlined, size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text('Дополнительные услуги',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (calculation.delivery > 0) _InfoRow('Доставка', '${calculation.delivery.toStringAsFixed(2)} ₽'),
                    if (calculation.lifting > 0) _InfoRow('Подъём', '${calculation.lifting.toStringAsFixed(2)} ₽'),
                    if (calculation.consumables > 0) _InfoRow('Расходники', '${calculation.consumables.toStringAsFixed(2)} ₽'),
                    if (calculation.measurement > 0) _InfoRow('Замер', '${calculation.measurement.toStringAsFixed(2)} ₽'),
                    if (calculation.installation > 0) _InfoRow('Монтаж', '${calculation.installation.toStringAsFixed(2)} ₽'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Итоговая смета',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _TotalRow('Сумма по изделиям', calculation.productsTotal),
                  const SizedBox(height: 6),
                  _TotalRow('Доп. услуги', calculation.servicesTotal),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Colors.white24),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ИТОГО', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      Text(
                        '${calculation.totalPrice.toStringAsFixed(2)} ₽',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _TotalRow(String label, double value, {bool isDiscount = false, bool isPositive = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(
          '${isDiscount ? '-' : isPositive ? '+' : ''}${value.toStringAsFixed(2)} ₽',
          style: TextStyle(
            color: isDiscount ? Colors.redAccent : isPositive ? Colors.greenAccent : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final int index;
  final CalcProductModel product;
  final bool highlightChanges;

  const _ProductCard({required this.index, required this.product, this.highlightChanges = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: product.isTempered
            ? Border.all(color: Colors.blueGrey.shade400, width: 2)
            : null,
        boxShadow: product.isTempered
            ? [BoxShadow(color: Colors.blueGrey.withOpacity(0.2), blurRadius: 12, spreadRadius: 2)]
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: product.isTempered ? Colors.blueGrey.shade50 : Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border(bottom: BorderSide(
                    color: product.isTempered ? Colors.blueGrey.shade200 : Colors.grey.shade200)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  if (product.isTempered)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(Icons.shield, size: 16, color: Colors.blueGrey.shade600),
                    ),
                  Text('Изделие #${index + 1}: ${product.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  if (product.quantity > 1)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text('× ${product.quantity}',
                          style: TextStyle(color: Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${(product.totalPrice * product.quantity).toStringAsFixed(2)} ₽',
                      style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat('Размер', '${product.width.toStringAsFixed(0)} × ${product.height.toStringAsFixed(0)} мм'),
                        _Stat('Площадь', '${product.area.toStringAsFixed(3)} м²'),
                        _Stat('Периметр', '${product.perimeter.toStringAsFixed(2)} м'),
                        if (highlightChanges && product.hasPriceChange)
                          _StatChanged(
                            '₽/м²',
                            product.originalPricePerSqm?.toStringAsFixed(0) ?? '—',
                            product.pricePerSqm.toStringAsFixed(0),
                          )
                        else
                          _Stat('₽/м²', product.pricePerSqm.toStringAsFixed(0)),
                      ],
                    ),
                  ),

                  if (product.materialName != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.layers_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text('Материал: ${product.materialName}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ],

                  if (product.isTempered) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 14, color: Colors.blueGrey.shade500),
                        const SizedBox(width: 6),
                        Text('Закалка +100 ₽',
                            style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13)),
                      ],
                    ),
                  ],

                  if (product.processings.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('Обработка:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13)),
                    const SizedBox(height: 4),
                    ...product.processings.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('• ${p.name}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              if (highlightChanges && p.hasPriceChange)
                                Row(children: [
                                  Text('${p.originalPricePerMeter?.toStringAsFixed(0)} ₽/м',
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12, decoration: TextDecoration.lineThrough)),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: Text('${p.pricePerMeter.toStringAsFixed(0)} ₽/м',
                                        style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ])
                              else
                                Text('${p.totalPrice.toStringAsFixed(2)} ₽',
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            ],
                          ),
                        )),
                  ],

                  if (product.pieceWorks.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('Штучные работы:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13)),
                    const SizedBox(height: 4),
                    ...product.pieceWorks.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('• ${p.name} × ${p.quantity}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              if (highlightChanges && p.hasPriceChange)
                                Row(children: [
                                  Text('${p.originalUnitPrice?.toStringAsFixed(0)} ₽/шт',
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12, decoration: TextDecoration.lineThrough)),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: Text('${p.unitPrice.toStringAsFixed(0)} ₽/шт',
                                        style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ])
                              else
                                Text('${p.totalPrice.toStringAsFixed(2)} ₽',
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            ],
                          ),
                        )),
                  ],

                  if (product.complexityType != 'none' && product.complexityValue > 0) ...[
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(
                        'Коэф. сложности${product.complexityType == 'percent' ? ' (${product.complexityValue.toStringAsFixed(0)}%)' : ' (${product.complexityValue.toStringAsFixed(0)} ₽)'}',
                        style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                      ),
                      Text('включён в цену', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                    ]),
                  ],
                  if (product.discountType != 'none' && product.discountValue > 0) ...[
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(
                        'Скидка${product.discountType == 'percent' ? ' (${product.discountValue.toStringAsFixed(0)}%)' : ' (${product.discountValue.toStringAsFixed(0)} ₽)'}',
                        style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                      ),
                      Text('включена в цену', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }
}

class _StatChanged extends StatelessWidget {
  final String label;
  final String oldValue;
  final String newValue;
  const _StatChanged(this.label, this.oldValue, this.newValue);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.orange.shade600)),
        const SizedBox(height: 2),
        Text(oldValue,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
          child: Text(newValue,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange.shade800)),
        ),
      ],
    );
  }
}