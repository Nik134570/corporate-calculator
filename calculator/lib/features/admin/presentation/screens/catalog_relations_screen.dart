import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:calculator/core/api/api_client.dart';
import 'package:calculator/core/di/injection.dart';

// ─── Экран управления материалами (упрощён — только название) ─────────────────

class MaterialsAdminScreen extends StatefulWidget {
  const MaterialsAdminScreen({super.key});

  @override
  State<MaterialsAdminScreen> createState() => _MaterialsAdminScreenState();
}

class _MaterialsAdminScreenState extends State<MaterialsAdminScreen> {
  List<Map<String, dynamic>> _materials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await getIt<ApiClient>().dio.get('/materials');
      setState(() {
        _materials = List<Map<String, dynamic>>.from(result.data['data']);
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
      appBar: AppBar(
        title: const Text('Материалы'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(context, null),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _materials.isEmpty
              ? Center(child: Text('Нет материалов', style: TextStyle(color: Colors.grey.shade500)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _materials.length,
                  itemBuilder: (context, index) {
                    final m = _materials[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                              onPressed: () => _showDialog(context, m),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _delete(context, m['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showDialog(BuildContext context, Map<String, dynamic>? item) {
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Добавить материал' : 'Редактировать материал'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Название',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (item == null) {
                  await getIt<ApiClient>().dio.post('/materials', data: {'name': nameCtrl.text});
                } else {
                  await getIt<ApiClient>().dio.patch('/materials/${item['id']}', data: {'name': nameCtrl.text});
                }
                _load();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await getIt<ApiClient>().dio.delete('/materials/$id');
      _load();
    }
  }
}

// ─── Экран управления наименованиями изделий ──────────────────────────────────

class ProductTemplatesAdminScreen extends StatefulWidget {
  const ProductTemplatesAdminScreen({super.key});

  @override
  State<ProductTemplatesAdminScreen> createState() => _ProductTemplatesAdminScreenState();
}

class _ProductTemplatesAdminScreenState extends State<ProductTemplatesAdminScreen> {
  List<Map<String, dynamic>> _templates = [];
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _processings = [];
  List<Map<String, dynamic>> _pieceWorks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        getIt<ApiClient>().dio.get('/product-templates'),
        getIt<ApiClient>().dio.get('/materials'),
        getIt<ApiClient>().dio.get('/catalog/processings'),
        getIt<ApiClient>().dio.get('/catalog/piece-works'),
      ]);
      setState(() {
        _templates = List<Map<String, dynamic>>.from(results[0].data['data']);
        _materials = List<Map<String, dynamic>>.from(results[1].data['data']);
        _processings = List<Map<String, dynamic>>.from(results[2].data['data']);
        _pieceWorks = List<Map<String, dynamic>>.from(results[3].data['data']);
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
      appBar: AppBar(
        title: const Text('Наименования изделий'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(context, null),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? Center(child: Text('Нет наименований', style: TextStyle(color: Colors.grey.shade500)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final t = _templates[index];
                    final matName = _materials.firstWhere(
                      (m) => m['id'] == t['materialId'],
                      orElse: () => {'name': '?'},
                    )['name'] as String;
                    final procCount = (t['allowedProcessingIds'] as List? ?? []).length;
                    final pwCount = (t['allowedPieceWorkIds'] as List? ?? []).length;
                    final tempered = t['allowTempered'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text('$matName ${t['thickness']}',
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${t['unitPrice']} ₽/м²'),
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 4,
                              children: [
                                if (tempered) _Chip('Закалка', Colors.blueGrey),
                                if (procCount > 0) _Chip('Обработок: $procCount', Colors.blue),
                                if (pwCount > 0) _Chip('Штучных: $pwCount', Colors.green),
                              ],
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                              onPressed: () => _showDialog(context, t),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _delete(context, t['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showDialog(BuildContext context, Map<String, dynamic>? item) {
    final thicknessCtrl = TextEditingController(text: item?['thickness'] ?? '');
    final priceCtrl = TextEditingController(text: item?['unitPrice']?.toString() ?? '');
    String? selectedMaterialId = item?['materialId'];
    bool allowTempered = item?['allowTempered'] == true;
    final selectedProcessingIds = Set<String>.from(item?['allowedProcessingIds'] ?? []);
    final selectedPieceWorkIds = Set<String>.from(item?['allowedPieceWorkIds'] ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Добавить наименование' : 'Редактировать наименование'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedMaterialId,
                    decoration: const InputDecoration(
                      labelText: 'Материал',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _materials.map((m) => DropdownMenuItem<String>(
                          value: m['id'] as String,
                          child: Text(m['name'] as String),
                        )).toList(),
                    onChanged: (v) => setDialogState(() => selectedMaterialId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: thicknessCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Толщина (например: 4мм)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                    decoration: const InputDecoration(
                      labelText: 'Цена за м²',
                      suffixText: '₽',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text('Доступные функции', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Закалка'),
                    subtitle: const Text('Разрешить добавлять закалку к изделию'),
                    value: allowTempered,
                    onChanged: (v) => setDialogState(() => allowTempered = v),
                    dense: true,
                  ),
                  if (_processings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Виды обработки', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ..._processings.map((p) => CheckboxListTile(
                          title: Text(p['name']),
                          subtitle: Text('${p['pricePerMeter']} ₽/м'),
                          value: selectedProcessingIds.contains(p['id']),
                          onChanged: (v) => setDialogState(() {
                            if (v == true) {
                              selectedProcessingIds.add(p['id']);
                            } else {
                              selectedProcessingIds.remove(p['id']);
                            }
                          }),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                        )),
                  ],
                  if (_pieceWorks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Штучные работы', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ..._pieceWorks.map((p) => CheckboxListTile(
                          title: Text(p['name']),
                          subtitle: Text('${p['unitPrice']} ₽/шт'),
                          value: selectedPieceWorkIds.contains(p['id']),
                          onChanged: (v) => setDialogState(() {
                            if (v == true) {
                              selectedPieceWorkIds.add(p['id']);
                            } else {
                              selectedPieceWorkIds.remove(p['id']);
                            }
                          }),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                        )),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                if (selectedMaterialId == null) return;
                Navigator.pop(context);
                final data = {
                  'materialId': selectedMaterialId,
                  'thickness': thicknessCtrl.text,
                  'unitPrice': double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0,
                  'allowTempered': allowTempered,
                  'processingIds': selectedProcessingIds.toList(),
                  'pieceWorkIds': selectedPieceWorkIds.toList(),
                };
                try {
                  if (item == null) {
                    await getIt<ApiClient>().dio.post('/product-templates', data: data);
                  } else {
                    await getIt<ApiClient>().dio.patch('/product-templates/${item['id']}', data: data);
                  }
                  _load();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await getIt<ApiClient>().dio.delete('/product-templates/$id');
      _load();
    }
  }
}

// ─── Экран управления обработками ────────────────────────────────────────────

class ProcessingsAdminScreen extends StatefulWidget {
  const ProcessingsAdminScreen({super.key});

  @override
  State<ProcessingsAdminScreen> createState() => _ProcessingsAdminScreenState();
}

class _ProcessingsAdminScreenState extends State<ProcessingsAdminScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _productTemplates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        getIt<ApiClient>().dio.get('/catalog/processings'),
        getIt<ApiClient>().dio.get('/product-templates'),
      ]);
      setState(() {
        _items = List<Map<String, dynamic>>.from(results[0].data['data']);
        _productTemplates = List<Map<String, dynamic>>.from(results[1].data['data']);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CatalogWithTemplatesScreen(
      title: 'Виды обработки',
      items: _items,
      productTemplates: _productTemplates,
      loading: _loading,
      priceLabel: 'Цена за м/пог',
      priceSuffix: '₽/м',
      priceKey: 'pricePerMeter',
      apiPath: '/catalog/processings',
      onReload: _load,
    );
  }
}

// ─── Экран управления штучными работами ───────────────────────────────────────

class PieceWorksAdminScreen extends StatefulWidget {
  const PieceWorksAdminScreen({super.key});

  @override
  State<PieceWorksAdminScreen> createState() => _PieceWorksAdminScreenState();
}

class _PieceWorksAdminScreenState extends State<PieceWorksAdminScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _productTemplates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        getIt<ApiClient>().dio.get('/catalog/piece-works'),
        getIt<ApiClient>().dio.get('/product-templates'),
      ]);
      setState(() {
        _items = List<Map<String, dynamic>>.from(results[0].data['data']);
        _productTemplates = List<Map<String, dynamic>>.from(results[1].data['data']);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CatalogWithTemplatesScreen(
      title: 'Штучные работы',
      items: _items,
      productTemplates: _productTemplates,
      loading: _loading,
      priceLabel: 'Цена за штуку',
      priceSuffix: '₽/шт',
      priceKey: 'unitPrice',
      apiPath: '/catalog/piece-works',
      onReload: _load,
    );
  }
}

// ─── Общий виджет для обработок и штучных работ ───────────────────────────────

class _CatalogWithTemplatesScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> productTemplates;
  final bool loading;
  final String priceLabel;
  final String priceSuffix;
  final String priceKey;
  final String apiPath;
  final VoidCallback onReload;

  const _CatalogWithTemplatesScreen({
    required this.title,
    required this.items,
    required this.productTemplates,
    required this.loading,
    required this.priceLabel,
    required this.priceSuffix,
    required this.priceKey,
    required this.apiPath,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(context, null),
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(child: Text('Нет элементов', style: TextStyle(color: Colors.grey.shade500)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final tmplIds = List<String>.from(item['productTemplateIds'] ?? []);
                    final tmplNames = tmplIds.map((id) {
                      final tmpl = productTemplates.firstWhere(
                        (t) => t['id'] == id,
                        orElse: () => <String, dynamic>{},
                      );
                      if (tmpl.isEmpty) return '?';
                      final mat = tmpl['materialName'] ?? '';
                      final thickness = tmpl['thickness'] ?? '';
                      return '$mat $thickness';
                    }).toList();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item[priceKey]} $priceSuffix'),
                            if (tmplNames.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Изделия: ${tmplNames.join(', ')}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ] else ...[
                              const SizedBox(height: 2),
                              Text('Нет привязанных наименований',
                                  style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                            ],
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                              onPressed: () => _showDialog(context, item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _delete(context, item['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showDialog(BuildContext context, Map<String, dynamic>? item) {
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final priceCtrl = TextEditingController(text: item?[priceKey]?.toString() ?? '');
    final selectedTemplateIds = Set<String>.from(item?['productTemplateIds'] ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Добавить' : 'Редактировать'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Название',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                    decoration: InputDecoration(
                      labelText: priceLabel,
                      suffixText: priceSuffix,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  if (productTemplates.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text('Доступно для наименований',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...productTemplates.map((t) {
                      final matName = t['material']?['name'] ?? '';
                      final thickness = t['thickness'] ?? '';
                      return CheckboxListTile(
                        title: Text('$matName $thickness'),
                        subtitle: Text('${t['unitPrice']} ₽/м²'),
                        value: selectedTemplateIds.contains(t['id']),
                        onChanged: (v) => setDialogState(() {
                          if (v == true) {
                            selectedTemplateIds.add(t['id'] as String);
                          } else {
                            selectedTemplateIds.remove(t['id']);
                          }
                        }),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final data = {
                  'name': nameCtrl.text,
                  priceKey: double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0,
                  'productTemplateIds': selectedTemplateIds.toList(),
                };
                try {
                  if (item == null) {
                    await getIt<ApiClient>().dio.post(apiPath, data: data);
                  } else {
                    await getIt<ApiClient>().dio.patch('$apiPath/${item['id']}', data: data);
                  }
                  onReload();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await getIt<ApiClient>().dio.delete('$apiPath/$id');
      onReload();
    }
  }
}

// ─── Вспомогательный виджет ───────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
