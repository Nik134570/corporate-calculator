import 'package:go_router/go_router.dart';
import 'package:calculator/core/di/injection.dart';
import 'package:calculator/core/storage/secure_storage.dart';
import 'package:calculator/features/auth/presentation/screens/login_screen.dart';
import 'package:calculator/features/calculator/data/models/calculation_model.dart';
import 'package:calculator/features/calculator/data/models/product_template_model.dart';
import 'package:calculator/features/calculator/presentation/screens/calculation_detail_screen.dart';
import 'package:calculator/features/calculator/presentation/screens/calculations_list_screen.dart';
import 'package:calculator/features/calculator/presentation/screens/new_calculation_screen.dart';
import 'package:calculator/features/admin/presentation/screens/admin_screen.dart';
import 'package:calculator/features/admin/presentation/screens/catalog_edit_screen.dart';
import 'package:calculator/features/admin/presentation/screens/catalog_relations_screen.dart';
import 'package:calculator/features/admin/presentation/screens/admin_settings_screen.dart';
import 'package:calculator/features/admin/presentation/screens/audit_screen.dart';


final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final token = await getIt<SecureStorage>().getAccessToken();
    final isLoggedIn = token != null;
    final isLoginPage = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoginPage) return '/login';

    if (isLoggedIn && isLoginPage) {
      final role = await getIt<SecureStorage>().getUserRole();
      if (role == 'ADMIN' || role == 'MANAGER') return '/admin';
      return '/calculations';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

    // Работник
    GoRoute(path: '/calculations', builder: (_, __) => const CalculationsListScreen()),
    GoRoute(
      path: '/new-calculation',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return NewCalculationScreen(productTemplates: extra['productTemplates'] as List<ProductTemplateModel>);
      },
    ),
    GoRoute(
      path: '/edit-calculation',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return NewCalculationScreen(
          productTemplates: (extra['productTemplates'] as List).cast<ProductTemplateModel>(),
          editCalculation: extra['calculation'] as CalculationModel,
          isWorker: extra['isWorker'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      path: '/calculation-detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return CalculationDetailScreen(
          calculation: extra['calculation'] as CalculationModel,
          productTemplates: (extra['productTemplates'] as List).cast<ProductTemplateModel>(),
          highlightChanges: extra['highlightChanges'] as bool? ?? false,
          showEditButton: extra['showEditButton'] as bool? ?? true,
        );
      },
    ),

    // Админ
    GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
    GoRoute(path: '/admin/settings', builder: (_, __) => const AdminSettingsScreen()),
    GoRoute(
      path: '/admin/catalog/materials',
      builder: (_, __) => const MaterialsAdminScreen(),
    ),
    GoRoute(
      path: '/admin/catalog/product-templates',
      builder: (_, __) => const ProductTemplatesAdminScreen(),
    ),
    GoRoute(
      path: '/admin/catalog/processings',
      builder: (_, __) => const ProcessingsAdminScreen(),
    ),
    GoRoute(
      path: '/admin/catalog/piece-works',
      builder: (_, __) => const PieceWorksAdminScreen(),
    ),
    GoRoute(
      path: '/admin/catalog/services',
      builder: (_, __) => CatalogEditScreen(
        title: 'Дополнительные услуги',
        apiPath: '/catalog/services',
        fields: [
          CatalogField(key: 'name', label: 'Название'),
          CatalogField(key: 'defaultPrice', label: 'Цена по умолчанию', isNumber: true),
        ],
      ),
    ),

    GoRoute(path: '/admin/audit', builder: (_, __) => const AuditScreen()),
  ],
);
