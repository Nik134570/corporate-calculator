import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:calculator/core/di/injection.dart';
import 'package:calculator/core/services/pdf_service.dart';
import 'package:calculator/features/calculator/data/models/calculation_model.dart';
import 'package:calculator/features/calculator/data/models/catalog_model.dart';
import 'package:calculator/features/calculator/data/models/product_template_model.dart';
import 'package:calculator/features/calculator/data/repositories/calculator_repository.dart';

// --- Локальные модели ---

class ProcessingInput {
  String name;
  double pricePerMeter;
  double? originalPricePerMeter;
  ProcessingInput({this.name = '', this.pricePerMeter = 0, this.originalPricePerMeter});
}

class PieceWorkInput {
  String name;
  int quantity;
  double unitPrice;
  double? originalUnitPrice;
  PieceWorkInput({this.name = '', this.quantity = 1, this.unitPrice = 0, this.originalUnitPrice});
}

class ProductInput {
  String name;
  String? productTemplateId;
  String? productTemplateName;
  double width;
  double height;
  int quantity;
  bool isTempered;
  double pricePerSqm;
  double? originalPricePerSqm;
  List<ProcessingInput> processings;
  List<PieceWorkInput> pieceWorks;
  double temperedPrice;

  ProductInput({
    this.name = '',
    this.productTemplateId,
    this.productTemplateName,
    this.width = 0,
    this.height = 0,
    this.quantity = 1,
    this.isTempered = false,
    this.pricePerSqm = 0,
    this.originalPricePerSqm,
    List<ProcessingInput>? processings,
    List<PieceWorkInput>? pieceWorks,
    this.temperedPrice = 100,
  })  : processings = processings ?? [],
        pieceWorks = pieceWorks ?? [];

  double get area => (width / 1000) * (height / 1000);
  double get perimeter => 2 * (width / 1000 + height / 1000);
  double get baseTotal => area * pricePerSqm;
  double get processingsTotal =>
      processings.fold(0, (s, p) => s + perimeter * p.pricePerMeter);
  double get pieceWorksTotal =>
      pieceWorks.fold(0, (s, p) => s + p.quantity * p.unitPrice);
  double get unitTotal =>
      baseTotal + processingsTotal + pieceWorksTotal + (isTempered ? temperedPrice : 0);
  double get total => unitTotal * quantity;

  bool get hasPriceChanges {
    if (originalPricePerSqm != null && pricePerSqm != originalPricePerSqm) return true;
    for (final p in processings) {
      if (p.originalPricePerMeter != null && p.pricePerMeter != p.originalPricePerMeter) return true;
    }
    for (final p in pieceWorks) {
      if (p.originalUnitPrice != null && p.unitPrice != p.originalUnitPrice) return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        'productTemplateId': productTemplateId,
        'name': productTemplateName ?? 'Изделие',
        'width': width,
        'height': height,
        'quantity': quantity,
        'isTempered': isTempered,
        'pricePerSqm': pricePerSqm,
        'originalPricePerSqm': originalPricePerSqm,
        'area': area,
        'totalPrice': unitTotal,
        'processings': processings.map((p) => {
              'name': p.name,
              'pricePerMeter': p.pricePerMeter,
              'originalPricePerMeter': p.originalPricePerMeter,
              'totalPrice': perimeter * p.pricePerMeter,
            }).toList(),
        'pieceWorks': pieceWorks.map((p) => {
              'name': p.name,
              'quantity': p.quantity,
              'unitPrice': p.unitPrice,
              'originalUnitPrice': p.originalUnitPrice,
              'totalPrice': p.quantity * p.unitPrice,
            }).toList(),
      };

  static ProductInput fromModel(CalcProductModel m, {double temperedPrice = 100}) => ProductInput(
        name: m.name,
        productTemplateId: m.productTemplateId,
        productTemplateName: m.materialName,
        width: m.width,
        height: m.height,
        quantity: m.quantity,
        isTempered: m.isTempered,
        pricePerSqm: m.pricePerSqm,
        originalPricePerSqm: m.originalPricePerSqm,
        temperedPrice: temperedPrice,
        processings: m.processings
            .map((p) => ProcessingInput(
                  name: p.name,
                  pricePerMeter: p.pricePerMeter,
                  originalPricePerMeter: p.originalPricePerMeter,
                ))
            .toList(),
        pieceWorks: m.pieceWorks
            .map((p) => PieceWorkInput(
                  name: p.name,
                  quantity: p.quantity,
                  unitPrice: p.unitPrice,
                  originalUnitPrice: p.originalUnitPrice,
                ))
            .toList(),
      );
}

// --- Главный экран ---

class NewCalculationScreen extends StatefulWidget {
  final List<ProductTemplateModel> productTemplates;
  final CalculationModel? editCalculation;
  final bool isWorker;

  const NewCalculationScreen({
    super.key,
    required this.productTemplates,
    this.editCalculation,
    this.isWorker = false,
  });

  @override
  State<NewCalculationScreen> createState() => _NewCalculationScreenState();
}

class _NewCalculationScreenState extends State<NewCalculationScreen> {
  late TextEditingController _clientNameController;
  late TextEditingController _clientPhoneController;
  late TextEditingController _clientAddressController;
  late TextEditingController _commentController;
  late TextEditingController _deliveryController;
  late TextEditingController _liftingController;
  late TextEditingController _consumablesController;
  late TextEditingController _measurementController;
  late TextEditingController _installationController;
  late TextEditingController _reviewCommentController;
  late TextEditingController _discountValueController;
  late TextEditingController _complexityValueController;

  String _discountType = 'none';
  String _complexityType = 'none';
  final List<ProductInput> _products = [];
  bool _saving = false;
  double _temperedPrice = 100;
  List<ProcessingTemplateModel> _processingTemplates = [];
  List<PieceWorkTemplateModel> _pieceWorkTemplates = [];

  bool get _isEditing => widget.editCalculation != null;
  // Работник редактирует существующий расчёт → обязательная модерация
  bool get _requiresReview => _isEditing && widget.isWorker;
  bool get _hasPriceChanges => _products.any((p) => p.hasPriceChanges);

  bool get _isDraft {
  return _clientNameController.text.isEmpty ||
      _products.isEmpty ||
      _products.every((p) => p.area == 0);
}

  @override
  void initState() {
    super.initState();
    final e = widget.editCalculation;
    _clientNameController = TextEditingController(text: e?.clientName ?? '');
    _clientPhoneController = TextEditingController(text: e?.clientPhone ?? '');
    _clientAddressController = TextEditingController(text: e?.clientAddress ?? '');
    _commentController = TextEditingController(text: e?.comment ?? '');
    _deliveryController = TextEditingController(text: (e?.delivery ?? 0).toString());
    _liftingController = TextEditingController(text: (e?.lifting ?? 0).toString());
    _consumablesController = TextEditingController(text: (e?.consumables ?? 0).toString());
    _measurementController = TextEditingController(text: (e?.measurement ?? 0).toString());
    _installationController = TextEditingController(text: (e?.installation ?? 0).toString());
    _reviewCommentController = TextEditingController();
    _discountType = e?.discountType ?? 'none';
    _discountValueController = TextEditingController(
        text: (e?.discountValue ?? 0) > 0 ? e!.discountValue.toString() : '');
    _complexityType = e?.complexityType ?? 'none';
    _complexityValueController = TextEditingController(
        text: (e?.complexityValue ?? 0) > 0 ? e!.complexityValue.toString() : '');

    if (e != null) {
      _products.addAll(e.products.map(ProductInput.fromModel));
    } else {
      _products.add(ProductInput(temperedPrice: _temperedPrice));
    }

    _loadSettings();

    for (final c in [
      _deliveryController, _liftingController, _consumablesController,
      _measurementController, _installationController,
      _discountValueController, _complexityValueController,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _clientNameController, _clientPhoneController,
      _clientAddressController, _commentController, _deliveryController,
      _liftingController, _consumablesController, _measurementController,
      _installationController, _discountValueController, _complexityValueController,
      _reviewCommentController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final results = await Future.wait([
        getIt<CalculatorRepository>().getSettings(),
        getIt<CalculatorRepository>().getProcessingTemplates(),
        getIt<CalculatorRepository>().getPieceWorkTemplates(),
      ]);
      if (!mounted) return;
      final settings = results[0] as AppSettingsModel;
      setState(() {
        _temperedPrice = settings.temperedPrice;
        _processingTemplates = results[1] as List<ProcessingTemplateModel>;
        _pieceWorkTemplates = results[2] as List<PieceWorkTemplateModel>;
        for (final p in _products) {
          p.temperedPrice = settings.temperedPrice;
        }
      });
    } catch (_) {}
  }

  double _parseD(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  double get _productsTotal => _products.fold(0, (s, p) => s + p.total);
  double get _servicesTotal =>
      _parseD(_deliveryController) + _parseD(_liftingController) +
      _parseD(_consumablesController) + _parseD(_measurementController) +
      _parseD(_installationController);

  double get _complexityAmount {
    final base = _productsTotal + _servicesTotal;
    final val = _parseD(_complexityValueController);
    if (_complexityType == 'percent') return base * val / 100;
    if (_complexityType == 'fixed') return val;
    return 0;
  }

  double get _discountAmount {
    final base = _productsTotal + _servicesTotal + _complexityAmount;
    final val = _parseD(_discountValueController);
    if (_discountType == 'percent') return base * val / 100;
    if (_discountType == 'fixed') return val;
    return 0;
  }

  double get _grandTotal =>
      (_productsTotal + _servicesTotal + _complexityAmount - _discountAmount)
          .clamp(0, double.infinity);

  Map<String, dynamic> _buildRequestData() => {
        'clientName': _clientNameController.text,
        'clientPhone': _clientPhoneController.text.isEmpty ? null : _clientPhoneController.text,
        'clientAddress': _clientAddressController.text.isEmpty ? null : _clientAddressController.text,
        'comment': _commentController.text.isEmpty ? null : _commentController.text,
        'delivery': _parseD(_deliveryController),
        'lifting': _parseD(_liftingController),
        'consumables': _parseD(_consumablesController),
        'measurement': _parseD(_measurementController),
        'installation': _parseD(_installationController),
        'discountType': _discountType,
        'discountValue': _parseD(_discountValueController),
        'complexityType': _complexityType,
        'complexityValue': _parseD(_complexityValueController),
        'hasPriceChanges': _hasPriceChanges,
        'products': _products.map((p) => p.toJson()).toList(),
        'isDraft': _isDraft,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать расчёт' : 'Новый расчёт'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildClientInfoCard(),
            const SizedBox(height: 16),
            _buildProductsSection(),
            const SizedBox(height: 16),
            _buildServicesCard(),
            const SizedBox(height: 16),
            _buildTotalsCard(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfoCard() {
    return _SectionCard(
      icon: Icons.description_outlined,
      title: 'Информация о заказе',
      child: Column(
        children: [
          _Field(controller: _clientNameController, label: 'Заказчик'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Field(controller: _clientPhoneController, label: 'Телефон', keyboard: TextInputType.phone)),
            const SizedBox(width: 12),
            Expanded(child: _Field(controller: _clientAddressController, label: 'Адрес')),
          ]),
          const SizedBox(height: 12),
          _Field(controller: _commentController, label: 'Комментарий', maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Изделия', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text('${_products.length} / 30',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._products.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProductBlock(
                key: ValueKey('product_${e.key}'),
                index: e.key,
                product: e.value,
                productTemplates: widget.productTemplates,
                processingTemplates: _processingTemplates,
                pieceWorkTemplates: _pieceWorkTemplates,
                onChanged: () => setState(() {}),
                onRemove: _products.length > 1
                    ? () => setState(() => _products.removeAt(e.key))
                    : null,
              ),
            )),
        if (_products.length < 30)
          OutlinedButton.icon(
            onPressed: () => setState(() => _products.add(ProductInput(temperedPrice: _temperedPrice))),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Добавить изделие'),
          ),
      ],
    );
  }

  Widget _buildServicesCard() {
    final services = [
      ('Доставка', _deliveryController),
      ('Подъём', _liftingController),
      ('Расходники', _consumablesController),
      ('Замер', _measurementController),
      ('Монтаж', _installationController),
    ];
    return _SectionCard(
      icon: Icons.miscellaneous_services_outlined,
      title: 'Дополнительные услуги',
      child: Column(
        children: services.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                SizedBox(width: 110, child: Text(s.$1, style: const TextStyle(fontSize: 14))),
                Expanded(child: _NumField(controller: s.$2, suffix: '₽', rightAlign: true)),
              ]),
            )).toList(),
      ),
    );
  }

  Widget _buildTotalsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Итоговая смета',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _TotalRow('Сумма по изделиям', _productsTotal),
          const SizedBox(height: 8),
          _TotalRow('Дополнительные услуги', _servicesTotal),

          // Коэффициент сложности
          const SizedBox(height: 16),
          const Text('Коэффициент сложности',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            _TypeBtn('Нет', 'none', _complexityType,
                (v) => setState(() { _complexityType = v; _complexityValueController.clear(); })),
            const SizedBox(width: 8),
            _TypeBtn('%', 'percent', _complexityType, (v) => setState(() => _complexityType = v)),
            const SizedBox(width: 8),
            _TypeBtn('₽', 'fixed', _complexityType, (v) => setState(() => _complexityType = v)),
            if (_complexityType != 'none') ...[
              const SizedBox(width: 12),
              Expanded(child: _NumField(controller: _complexityValueController,
                  suffix: _complexityType == 'percent' ? '%' : '₽', light: true)),
              if (_complexityAmount > 0) ...[
                const SizedBox(width: 8),
                Text('+${_complexityAmount.toStringAsFixed(2)} ₽',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
              ],
            ],
          ]),

          // Скидка
          const SizedBox(height: 16),
          const Text('Скидка', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            _TypeBtn('Нет', 'none', _discountType,
                (v) => setState(() { _discountType = v; _discountValueController.clear(); })),
            const SizedBox(width: 8),
            _TypeBtn('%', 'percent', _discountType, (v) => setState(() => _discountType = v)),
            const SizedBox(width: 8),
            _TypeBtn('₽', 'fixed', _discountType, (v) => setState(() => _discountType = v)),
            if (_discountType != 'none') ...[
              const SizedBox(width: 12),
              Expanded(child: _NumField(controller: _discountValueController,
                  suffix: _discountType == 'percent' ? '%' : '₽', light: true)),
              if (_discountAmount > 0) ...[
                const SizedBox(width: 8),
                Text('-${_discountAmount.toStringAsFixed(2)} ₽',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
            ],
          ]),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white24),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ИТОГО', style: TextStyle(color: Colors.white70, fontSize: 16)),
              Text('${_grandTotal.toStringAsFixed(2)} ₽',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),

          // Плашка изменения цен (только не в режиме обязательной модерации)
          if (_hasPriceChanges && !_requiresReview) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade400),
              ),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade300, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Цены изменены — требуется одобрение администрации',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewCommentController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Комментарий для администратора...',
                hintStyle: const TextStyle(color: Colors.white38),
                isDense: true,
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                contentPadding: const EdgeInsets.all(10),
              ),
              maxLines: 2,
            ),
          ],

          const SizedBox(height: 16),

          if (_requiresReview) ...[
            // Работник редактирует существующий расчёт — только модерация
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade400),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.orange.shade300, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Изменения требуют одобрения администратора',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : () => _save(download: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _saving
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_outlined, size: 18),
                  label: const Text('Отправить на модерацию'),
                ),
              ),
            ]),
          ] else ...[
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _save(download: false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Сохранить'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : () => _save(download: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('PDF'),
                ),
              ),
            ]),

            if (_hasPriceChanges) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: const Text('Отправить на модерацию'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _TotalRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54)),
        Text('${value.toStringAsFixed(2)} ₽',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _TypeBtn(String label, String value, String current, Function(String) onTap) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.black87 : Colors.white70,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13)),
      ),
    );
  }

  Future<void> _save({required bool download}) async {
    setState(() => _saving = true);
    try {
      final data = _buildRequestData();
      final CalculationModel calculation;
      if (_isEditing) {
        calculation = await getIt<CalculatorRepository>().update(widget.editCalculation!.id, data);
      } else {
        calculation = await getIt<CalculatorRepository>().create(data);
      }
      if (download && context.mounted) {
        await PdfService.generateAndPrint(calculation);
      }
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitReview() async {
  setState(() => _saving = true);
  try {
    final data = _buildRequestData();
    final CalculationModel calculation;

    if (_isEditing) {
      calculation = await getIt<CalculatorRepository>().update(widget.editCalculation!.id, data);
    } else {
      calculation = await getIt<CalculatorRepository>().create(data);
    }

    await getIt<CalculatorRepository>().submitReview(
      calculation.id,
      comment: _reviewCommentController.text.isEmpty ? null : _reviewCommentController.text,
    );
    if (context.mounted) context.pop();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}
}

// --- Блок изделия ---

class _ProductBlock extends StatefulWidget {
  final int index;
  final ProductInput product;
  final List<ProductTemplateModel> productTemplates;
  final List<ProcessingTemplateModel> processingTemplates;
  final List<PieceWorkTemplateModel> pieceWorkTemplates;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _ProductBlock({
    super.key,
    required this.index,
    required this.product,
    required this.productTemplates,
    required this.processingTemplates,
    required this.pieceWorkTemplates,
    required this.onChanged,
    this.onRemove,
  });

  @override
  State<_ProductBlock> createState() => _ProductBlockState();
}

class _ProductBlockState extends State<_ProductBlock> {
  late TextEditingController _widthCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _quantityCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _widthCtrl = TextEditingController(text: p.width == 0 ? '' : p.width.toString());
    _heightCtrl = TextEditingController(text: p.height == 0 ? '' : p.height.toString());
    _priceCtrl = TextEditingController(text: p.pricePerSqm == 0 ? '' : p.pricePerSqm.toString());
    _quantityCtrl = TextEditingController(text: p.quantity.toString());
  }

  @override
  void dispose() {
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _priceCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  void _update() {
    widget.product.width = double.tryParse(_widthCtrl.text.replaceAll(',', '.')) ?? 0;
    widget.product.height = double.tryParse(_heightCtrl.text.replaceAll(',', '.')) ?? 0;
    widget.product.pricePerSqm = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
    widget.product.quantity = int.tryParse(_quantityCtrl.text) ?? 1;
    setState(() {});
    widget.onChanged();
  }

  ProductTemplateModel? get _selectedTemplate => widget.product.productTemplateId == null
      ? null
      : widget.productTemplates.where((t) => t.id == widget.product.productTemplateId).firstOrNull;

  List<ProcessingTemplateModel> get _allowedProcessings {
    final tmpl = _selectedTemplate;
    if (tmpl == null) return widget.processingTemplates;
    return widget.processingTemplates
        .where((t) => tmpl.allowedProcessingIds.contains(t.id))
        .toList();
  }

  List<PieceWorkTemplateModel> get _allowedPieceWorks {
    final tmpl = _selectedTemplate;
    if (tmpl == null) return widget.pieceWorkTemplates;
    return widget.pieceWorkTemplates
        .where((t) => tmpl.allowedPieceWorkIds.contains(t.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final tmpl = _selectedTemplate;
    final canTemper = tmpl?.allowTempered ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: p.isTempered ? Border.all(color: Colors.blueGrey.shade400, width: 2) : null,
        boxShadow: p.isTempered
            ? [
                BoxShadow(color: Colors.blueGrey.withOpacity(0.3), blurRadius: 12, spreadRadius: 2),
                BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 24, spreadRadius: 4),
              ]
            : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: p.isTempered ? Colors.blueGrey.shade50 : Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(
                    color: p.isTempered ? Colors.blueGrey.shade200 : Colors.grey.shade200)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (p.isTempered)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.shield, size: 18, color: Colors.blueGrey.shade600),
                    ),
                  Text('Изделие #${widget.index + 1}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16,
                          color: p.isTempered ? Colors.blueGrey.shade800 : Colors.black87)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: p.isTempered ? Colors.blueGrey.shade100 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${p.total.toStringAsFixed(2)} ₽',
                        style: TextStyle(
                            color: p.isTempered ? Colors.blueGrey.shade700 : Colors.blue.shade700,
                            fontWeight: FontWeight.bold)),
                  ),
                  if (widget.onRemove != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: widget.onRemove,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductTemplateSelector(
                    productTemplates: widget.productTemplates,
                    selectedId: p.productTemplateId,
                    currentPrice: p.pricePerSqm,
                    onSelected: (id, name, price, originalPrice) {
                      final newTmpl = id == null
                          ? null
                          : widget.productTemplates.where((t) => t.id == id).firstOrNull;
                      setState(() {
                        p.productTemplateId = id;
                        p.productTemplateName = name;
                        p.pricePerSqm = price;
                        p.originalPricePerSqm = originalPrice;
                        _priceCtrl.text = price > 0 ? price.toString() : '';
                        if (newTmpl != null && !newTmpl.allowTempered) {
                          p.isTempered = false;
                        }
                      });
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: 12),

                  Row(children: [
                    Expanded(child: _NumField(controller: _widthCtrl, label: 'Ширина (мм)', onChanged: (_) => _update())),
                    const SizedBox(width: 8),
                    Expanded(child: _NumField(controller: _heightCtrl, label: 'Высота (мм)', onChanged: (_) => _update())),
                    const SizedBox(width: 8),
                    Expanded(child: _NumField(controller: _priceCtrl, label: '₽/м²', onChanged: (_) => _update())),
                  ]),

                  if (p.area > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _CalcInfo('Площадь', '${p.area.toStringAsFixed(3)} м²'),
                          _CalcInfo('Периметр', '${p.perimeter.toStringAsFixed(2)} м'),
                          _CalcInfo('Материал', '${p.baseTotal.toStringAsFixed(2)} ₽'),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Количество
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.quantity > 1 ? Colors.orange.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: p.quantity > 1 ? Colors.orange.shade300 : Colors.grey.shade300,
                        width: p.quantity > 1 ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.content_copy_outlined, size: 18,
                              color: p.quantity > 1 ? Colors.orange.shade700 : Colors.grey.shade500),
                          const SizedBox(width: 8),
                          Text('Количество изделий',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: p.quantity > 1 ? Colors.orange.shade800 : Colors.grey.shade700)),
                          const Spacer(),
                          SizedBox(
                            width: 80,
                            child: _NumField(controller: _quantityCtrl, isInteger: true, onChanged: (_) => _update()),
                          ),
                        ]),
                        if (p.quantity > 1) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.warning_amber_rounded, size: 15, color: Colors.orange.shade600),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Все ${p.quantity} изделия считаются абсолютно идентичными — одинаковые размеры, материал и работы.',
                                style: TextStyle(fontSize: 12, color: Colors.orange.shade700, height: 1.4),
                              ),
                            ),
                          ]),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Закалка — только если материал поддерживает
                  if (canTemper)
                    InkWell(
                      onTap: () {
                        setState(() => p.isTempered = !p.isTempered);
                        widget.onChanged();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: p.isTempered ? Colors.blueGrey.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: p.isTempered ? Colors.blueGrey.shade300 : Colors.grey.shade300),
                        ),
                        child: Row(children: [
                          Icon(Icons.shield_outlined, size: 18,
                              color: p.isTempered ? Colors.blueGrey.shade600 : Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Text('Закалка (+${p.temperedPrice.toStringAsFixed(0)} ₽)',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: p.isTempered ? Colors.blueGrey.shade700 : Colors.grey.shade600)),
                          const Spacer(),
                          Switch(
                            value: p.isTempered,
                            onChanged: (v) {
                              setState(() => p.isTempered = v);
                              widget.onChanged();
                            },
                            activeColor: Colors.blueGrey.shade600,
                          ),
                        ]),
                      ),
                    ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  _ProcessingsSection(
                    product: p,
                    templates: _allowedProcessings,
                    onChanged: () { setState(() {}); widget.onChanged(); },
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  _PieceWorksSection(
                    product: p,
                    templates: _allowedPieceWorks,
                    onChanged: () { setState(() {}); widget.onChanged(); },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Выбор наименования изделия ---

class _ProductTemplateSelector extends StatelessWidget {
  final List<ProductTemplateModel> productTemplates;
  final String? selectedId;
  final double currentPrice;
  final Function(String? id, String? name, double price, double? originalPrice) onSelected;

  const _ProductTemplateSelector({
    required this.productTemplates,
    required this.selectedId,
    required this.currentPrice,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedId != null
        ? productTemplates.where((t) => t.id == selectedId).firstOrNull
        : null;

    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Наименование',
          border: OutlineInputBorder(),
          isDense: true,
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          selected?.displayName ?? 'Выбрать...',
          style: TextStyle(
            color: selected != null ? Colors.black87 : Colors.grey.shade500,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    // Группируем по materialName
    final groups = <String, List<ProductTemplateModel>>{};
    for (final t in productTemplates) {
      groups.putIfAbsent(t.materialName, () => []).add(t);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Выбор наименования', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  ListTile(
                    dense: true,
                    title: const Text('Без наименования'),
                    leading: const Icon(Icons.close, size: 20),
                    onTap: () { onSelected(null, null, 0, null); Navigator.pop(ctx); },
                  ),
                  ...groups.entries.map((entry) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(entry.key,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600, letterSpacing: 0.5)),
                      ),
                      ...entry.value.map((t) => ListTile(
                            dense: true,
                            title: Text(t.thickness),
                            subtitle: Text('${t.unitPrice.toStringAsFixed(0)} ₽/м²'),
                            trailing: selectedId == t.id
                                ? const Icon(Icons.check, color: Colors.blue)
                                : null,
                            onTap: () {
                              onSelected(t.id, t.displayName, t.unitPrice, t.unitPrice);
                              Navigator.pop(ctx);
                            },
                          )),
                    ],
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Секция обработки ---

class _ProcessingsSection extends StatefulWidget {
  final ProductInput product;
  final List<ProcessingTemplateModel> templates;
  final VoidCallback onChanged;
  const _ProcessingsSection({
    required this.product,
    required this.templates,
    required this.onChanged,
  });

  @override
  State<_ProcessingsSection> createState() => _ProcessingsSectionState();
}

class _ProcessingsSectionState extends State<_ProcessingsSection> {
  final List<TextEditingController> _priceCtrl = [];

  void _syncControllers() {
    while (_priceCtrl.length < widget.product.processings.length) {
      final i = _priceCtrl.length;
      _priceCtrl.add(TextEditingController(
          text: widget.product.processings[i].pricePerMeter == 0
              ? ''
              : widget.product.processings[i].pricePerMeter.toString()));
    }
  }

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void dispose() {
    for (final c in _priceCtrl) c.dispose();
    super.dispose();
  }

  void _showPicker() {
    final added = widget.product.processings.map((p) => p.name).toSet();
    final available = widget.templates.where((t) => !added.contains(t.name)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Все доступные обработки уже добавлены')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Выбрать обработку',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...available.map((t) => ListTile(
                title: Text(t.name),
                subtitle: Text('${t.pricePerMeter} ₽/м'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    widget.product.processings.add(ProcessingInput(
                      name: t.name,
                      pricePerMeter: t.pricePerMeter,
                      originalPricePerMeter: t.pricePerMeter,
                    ));
                    _priceCtrl.add(TextEditingController(text: t.pricePerMeter.toString()));
                  });
                  widget.onChanged();
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _syncControllers();
    final canAdd = widget.product.processings.length < 3 && widget.templates.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              const Text('Обработка (м/пог)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              _Badge('${widget.product.processings.length}/3'),
            ]),
            if (canAdd)
              TextButton.icon(
                onPressed: _showPicker,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Добавить'),
              )
            else if (widget.templates.isEmpty && widget.product.processings.length < 3)
              Tooltip(
                message: 'Для выбранного материала нет доступных видов обработки',
                child: Text('Нет доступных',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.product.processings.isEmpty)
          _EmptyHint('Нет обработок')
        else
          ...widget.product.processings.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      child: Text(e.value.name, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: _NumField(
                      controller: _priceCtrl[e.key],
                      hint: '₽/м',
                      onChanged: (v) {
                        e.value.pricePerMeter = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                        widget.onChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        widget.product.processings.removeAt(e.key);
                        _priceCtrl.removeAt(e.key).dispose();
                      });
                      widget.onChanged();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ]),
              )),
      ],
    );
  }
}

// --- Секция штучных работ ---

class _PieceWorksSection extends StatefulWidget {
  final ProductInput product;
  final List<PieceWorkTemplateModel> templates;
  final VoidCallback onChanged;
  const _PieceWorksSection({
    required this.product,
    required this.templates,
    required this.onChanged,
  });

  @override
  State<_PieceWorksSection> createState() => _PieceWorksSectionState();
}

class _PieceWorksSectionState extends State<_PieceWorksSection> {
  final List<TextEditingController> _qtyCtrl = [];
  final List<TextEditingController> _priceCtrl = [];

  void _syncControllers() {
    while (_qtyCtrl.length < widget.product.pieceWorks.length) {
      final i = _qtyCtrl.length;
      _qtyCtrl.add(TextEditingController(text: widget.product.pieceWorks[i].quantity.toString()));
      _priceCtrl.add(TextEditingController(
          text: widget.product.pieceWorks[i].unitPrice == 0
              ? ''
              : widget.product.pieceWorks[i].unitPrice.toString()));
    }
  }

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void dispose() {
    for (final c in _qtyCtrl) c.dispose();
    for (final c in _priceCtrl) c.dispose();
    super.dispose();
  }

  void _showPicker() {
    final added = widget.product.pieceWorks.map((p) => p.name).toSet();
    final available = widget.templates.where((t) => !added.contains(t.name)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Все доступные штучные работы уже добавлены')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Выбрать штучную работу',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...available.map((t) => ListTile(
                title: Text(t.name),
                subtitle: Text('${t.unitPrice} ₽/шт'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    widget.product.pieceWorks.add(PieceWorkInput(
                      name: t.name,
                      quantity: 1,
                      unitPrice: t.unitPrice,
                      originalUnitPrice: t.unitPrice,
                    ));
                    _qtyCtrl.add(TextEditingController(text: '1'));
                    _priceCtrl.add(TextEditingController(text: t.unitPrice.toString()));
                  });
                  widget.onChanged();
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _syncControllers();
    final canAdd = widget.product.pieceWorks.length < 5 && widget.templates.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              const Text('Штучные работы', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              _Badge('${widget.product.pieceWorks.length}/5'),
            ]),
            if (canAdd)
              TextButton.icon(
                onPressed: _showPicker,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Добавить'),
              )
            else if (widget.templates.isEmpty && widget.product.pieceWorks.length < 5)
              Tooltip(
                message: 'Для выбранного материала нет доступных штучных работ',
                child: Text('Нет доступных',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.product.pieceWorks.isEmpty)
          _EmptyHint('Нет штучных работ')
        else
          ...widget.product.pieceWorks.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(
                    flex: 3,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      child: Text(e.value.name, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NumField(
                      controller: _qtyCtrl[e.key],
                      hint: 'Кол',
                      isInteger: true,
                      onChanged: (v) {
                        e.value.quantity = int.tryParse(v) ?? 1;
                        widget.onChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _NumField(
                      controller: _priceCtrl[e.key],
                      hint: 'Цена ₽',
                      onChanged: (v) {
                        e.value.unitPrice = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                        widget.onChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        widget.product.pieceWorks.removeAt(e.key);
                        _qtyCtrl.removeAt(e.key).dispose();
                        _priceCtrl.removeAt(e.key).dispose();
                      });
                      widget.onChanged();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ]),
              )),
      ],
    );
  }
}

// --- Вспомогательные виджеты ---

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _SectionCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboard;

  const _Field({required this.controller, required this.label, this.maxLines = 1, this.keyboard});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? suffix;
  final bool rightAlign;
  final bool light;
  final bool isInteger;
  final Function(String)? onChanged;

  const _NumField({
    required this.controller,
    this.label, this.hint, this.suffix,
    this.rightAlign = false, this.light = false, this.isInteger = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: isInteger ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        if (isInteger) FilteringTextInputFormatter.digitsOnly
        else FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
      ],
      textAlign: rightAlign ? TextAlign.right : TextAlign.start,
      style: light ? const TextStyle(color: Colors.white) : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        isDense: true,
        border: OutlineInputBorder(borderSide: BorderSide(color: light ? Colors.white30 : Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: light ? Colors.white30 : Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: light ? Colors.white : Colors.blue)),
        labelStyle: light ? const TextStyle(color: Colors.white70) : null,
        hintStyle: light ? const TextStyle(color: Colors.white38) : null,
        suffixStyle: light ? const TextStyle(color: Colors.white70) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      onChanged: onChanged,
    );
  }
}

class _CalcInfo extends StatelessWidget {
  final String label;
  final String value;
  const _CalcInfo(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(child: Text(text, style: TextStyle(color: Colors.grey.shade400, fontSize: 13))),
    );
  }
}
