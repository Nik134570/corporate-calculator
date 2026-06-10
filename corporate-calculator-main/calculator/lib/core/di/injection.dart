import 'package:get_it/get_it.dart';
import 'package:calculator/core/api/api_client.dart';
import 'package:calculator/core/storage/secure_storage.dart';
import 'package:calculator/features/auth/data/repositories/auth_repository.dart';
import 'package:calculator/features/calculator/data/repositories/calculator_repository.dart';
import 'package:calculator/features/notifications/data/repositories/notification_repository.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorage());
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt<SecureStorage>()));
  getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepository(getIt<ApiClient>(), getIt<SecureStorage>()));
  getIt.registerLazySingleton<CalculatorRepository>(
      () => CalculatorRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton<NotificationRepository>(
      () => NotificationRepository(getIt<ApiClient>()));
}
