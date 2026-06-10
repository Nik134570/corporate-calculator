import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:calculator/core/api/api_client.dart';
import 'package:calculator/core/di/injection.dart';
import 'package:calculator/core/theme/app_styles.dart';

class CatalogEditScreen extends StatefulWidget {
  final String title;
  final String apiPath;
  final List<CatalogField> fields;

  const CatalogEditScreen({
    super.key,
    required this.title,
    required this.apiPath,
    required this.fields,
  });

  @override
  State<CatalogEditScreen> createState() => _CatalogEditScreenState();
}

class CatalogField {
  final String key;
  final String label;
  final bool isNumber;

  CatalogField({required this.key, required this.label, this.isNumber = false});
}

class _CatalogEditScreenState extends State<CatalogEditScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await getIt<ApiClient>().dio.get(widget.apiPath);
      setState(() {
        _items = List<Map<String, dynamic>>.from(response.data['data']);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppStyles.appBarBg,
        foregroundColor: AppStyles.appBarFg,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(context, null),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text('Нет элементов', style: AppStyles.subtitleStyle))
              : ListView.builder(
                  padding: AppStyles.listPadding,
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final subtitle = widget.fields
                        .where((f) => f.isNumber)
                        .map((f) => '${f.label}: ${item[f.key]} ₽')
                        .join(', ');

                    return Card(
                      margin: AppStyles.cardMarginSmall,
                      shape: AppStyles.cardShape(10),
                      child: ListTile(
                        title: Text(item['name'] ?? '', style: AppStyles.titleMedium),
                        subtitle: subtitle.isNotEmpty
                            ? Text(subtitle, style: AppStyles.subtitleStyle)
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_outlined,
                                  color: AppStyles.primary, size: 20),
                              onPressed: () => _showDialog(context, item),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: AppStyles.danger, size: 20),
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
    final controllers = {
      for (final f in widget.fields)
        f.key: TextEditingController(text: item?[f.key]?.toString() ?? ''),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Добавить' : 'Редактировать'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.fields.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: controllers[f.key],
                    keyboardType: f.isNumber
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    inputFormatters: f.isNumber
                        ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))]
                        : null,
                    decoration: InputDecoration(
                      labelText: f.label,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final data = {
                for (final f in widget.fields)
                  f.key: f.isNumber
                      ? double.tryParse(controllers[f.key]!.text.replaceAll(',', '.')) ?? 0
                      : controllers[f.key]!.text,
              };
              try {
                if (item == null) {
                  await getIt<ApiClient>().dio.post(widget.apiPath, data: data);
                } else {
                  await getIt<ApiClient>().dio.patch('${widget.apiPath}/${item['id']}', data: data);
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
      try {
        await getIt<ApiClient>().dio.delete('${widget.apiPath}/$id');
        _load();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppStyles.danger),
          );
        }
      }
    }
  }
}