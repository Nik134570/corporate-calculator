import 'package:calculator/core/api/api_client.dart';
import 'package:calculator/features/calculator/data/models/calculation_model.dart';
import 'package:calculator/features/calculator/data/models/catalog_model.dart';
import 'package:calculator/features/calculator/data/models/product_template_model.dart';

class CalculatorRepository {
  final ApiClient _apiClient;

  CalculatorRepository(this._apiClient);

  Future<List<ProductTemplateModel>> getProductTemplates() async {
    final response = await _apiClient.dio.get('/product-templates');
    return (response.data['data'] as List).map((e) => ProductTemplateModel.fromJson(e)).toList();
  }

  Future<List<CalculationModel>> getAll() async {
    final response = await _apiClient.dio.get('/calculations');
    return (response.data['data'] as List).map((e) => CalculationModel.fromJson(e)).toList();
  }

  Future<CalculationModel> create(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/calculations', data: data);
    return CalculationModel.fromJson(response.data['data']);
  }

  Future<CalculationModel> update(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/calculations/$id', data: data);
    return CalculationModel.fromJson(response.data['data']);
  }

  Future<void> delete(String id) async {
    await _apiClient.dio.delete('/calculations/$id');
  }

  Future<void> submitReview(String id, {String? comment}) async {
    await _apiClient.dio.post('/calculations/$id/submit-review', data: {'comment': comment});
  }

  Future<void> approveReview(String id, {String? comment}) async {
    await _apiClient.dio.post('/calculations/$id/approve', data: {'comment': comment});
  }

  Future<void> rejectReview(String id, {String? comment}) async {
    await _apiClient.dio.post('/calculations/$id/reject', data: {'comment': comment});
  }

  Future<List<Map<String, dynamic>>> getPendingReviews() async {
    final response = await _apiClient.dio.get('/calculations/reviews/pending');
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  // Каталог
  Future<List<ProcessingTemplateModel>> getProcessingTemplates() async {
    final response = await _apiClient.dio.get('/catalog/processings');
    return (response.data['data'] as List).map((e) => ProcessingTemplateModel.fromJson(e)).toList();
  }

  Future<List<PieceWorkTemplateModel>> getPieceWorkTemplates() async {
    final response = await _apiClient.dio.get('/catalog/piece-works');
    return (response.data['data'] as List).map((e) => PieceWorkTemplateModel.fromJson(e)).toList();
  }

  Future<List<DiscountTemplateModel>> getDiscountTemplates() async {
    final response = await _apiClient.dio.get('/catalog/discounts');
    return (response.data['data'] as List).map((e) => DiscountTemplateModel.fromJson(e)).toList();
  }

  Future<AppSettingsModel> getSettings() async {
    final response = await _apiClient.dio.get('/settings');
    return AppSettingsModel.fromJson(response.data['data']);
  }
}
