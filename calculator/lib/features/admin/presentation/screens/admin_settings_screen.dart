import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:calculator/core/api/api_client.dart';
import 'package:calculator/core/di/injection.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _temperedPriceCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _settingsId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await getIt<ApiClient>().dio.get('/settings');
      final data = response.data['data'];
      _settingsId = data['id'];
      _temperedPriceCtrl.text = data['temperedPrice'].toString();
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Colors.blueGrey.shade600),
                          const SizedBox(width: 8),
                          const Text('Цена закалки',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _temperedPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                        decoration: const InputDecoration(
                          labelText: 'Стоимость закалки (₽)',
                          border: OutlineInputBorder(),
                          suffixText: '₽',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(height: 18, width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Сохранить'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await getIt<ApiClient>().dio.patch('/settings', data: {
        'temperedPrice': double.tryParse(_temperedPriceCtrl.text.replaceAll(',', '.')) ?? 100,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сохранено'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}