import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:calculator/core/di/injection.dart';
import 'package:calculator/core/storage/secure_storage.dart';
import 'package:calculator/core/theme/app_styles.dart';
import 'package:calculator/features/auth/data/repositories/auth_repository.dart';
import 'package:calculator/features/calculator/data/models/calculation_model.dart';
import 'package:calculator/features/calculator/data/repositories/calculator_repository.dart';
import 'package:calculator/features/calculator/presentation/bloc/calculator_bloc.dart';
import 'package:calculator/features/notifications/data/repositories/notification_repository.dart';
import 'package:calculator/features/notifications/presentation/screens/notifications_screen.dart';

const int _kPageSize = 5;

class CalculationsListScreen extends StatefulWidget {
  const CalculationsListScreen({super.key});

  @override
  State<CalculationsListScreen> createState() => _CalculationsListScreenState();
}

class _CalculationsListScreenState extends State<CalculationsListScreen> {
  int _currentTab = 0;
  int _unreadCount = 0;
  String _userRole = 'WORKER';
  late final CalculatorBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = CalculatorBloc(getIt<CalculatorRepository>())
      ..add(CalculatorLoadRequested());
    _loadMeta();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    try {
      final role = await getIt<SecureStorage>().getUserRole();
      final count = await getIt<NotificationRepository>().getUnreadCount();
      if (mounted) {
        setState(() {
          _userRole = role ?? 'WORKER';
          _unreadCount = count;
        });
      }
    } catch (_) {}
  }

  void _onNotificationsRead() {
    getIt<NotificationRepository>().getUnreadCount().then((count) {
      if (mounted) setState(() => _unreadCount = count);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: AppStyles.background,
        appBar: AppBar(
          title: Text(_currentTab == 0 ? 'Мои расчёты' : 'Уведомления'),
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
        floatingActionButton: _currentTab == 0
            ? BlocBuilder<CalculatorBloc, CalculatorState>(
                builder: (context, state) => FloatingActionButton(
                  onPressed: () async {
                    if (state is CalculatorLoaded) {
                      await context.push('/new-calculation', extra: {
                        'productTemplates': state.productTemplates,
                      });
                      if (context.mounted) {
                        _bloc.add(CalculatorLoadRequested());
                      }
                    }
                  },
                  child: const Icon(Icons.add),
                ),
              )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (i) {
            setState(() => _currentTab = i);
            if (i == 0) _bloc.add(CalculatorLoadRequested());
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.calculate_outlined),
              activeIcon: Icon(Icons.calculate),
              label: 'Расчёты',
            ),
            BottomNavigationBarItem(
              icon: _unreadCount > 0
                  ? Badge(
                      label: Text('$_unreadCount'),
                      child: const Icon(Icons.notifications_outlined),
                    )
                  : const Icon(Icons.notifications_outlined),
              activeIcon: _unreadCount > 0
                  ? Badge(
                      label: Text('$_unreadCount'),
                      child: const Icon(Icons.notifications),
                    )
                  : const Icon(Icons.notifications),
              label: 'Уведомления',
            ),
          ],
        ),
        body: _currentTab == 0
            ? _CalculationsTab(userRole: _userRole)
            : NotificationsScreen(onRead: _onNotificationsRead),
      ),
    );
  }
}

class _CalculationsTab extends StatefulWidget {
  final String userRole;
  const _CalculationsTab({required this.userRole});

  @override
  State<_CalculationsTab> createState() => _CalculationsTabState();
}

class _CalculationsTabState extends State<_CalculationsTab> {
  final ScrollController _scrollController = ScrollController();
  int _visibleCount = _kPageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= maxScroll * 0.8) {
      final state = context.read<CalculatorBloc>().state;
      if (state is CalculatorLoaded && _visibleCount < state.calculations.length) {
        setState(() => _visibleCount += _kPageSize);
      }
    }
  }

  void _resetPagination() {
    setState(() => _visibleCount = _kPageSize);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CalculatorBloc, CalculatorState>(
      listenWhen: (prev, curr) => curr is CalculatorLoaded && prev is! CalculatorLoaded,
      listener: (context, state) {
        _resetPagination();
      },
      builder: (context, state) {
        if (state is CalculatorLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CalculatorError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppStyles.danger),
                const SizedBox(height: AppStyles.spaceL),
                Text(state.message),
                const SizedBox(height: AppStyles.spaceL),
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
                  const SizedBox(height: AppStyles.spaceL),
                  Text(
                    'Нет расчётов',
                    style: AppStyles.subtitleStyle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: AppStyles.spaceS),
                  Text(
                    'Нажмите + чтобы создать новый',
                    style: AppStyles.captionStyle,
                  ),
                ],
              ),
            );
          }

          final allCalcs = state.calculations;
          final shown = _visibleCount.clamp(0, allCalcs.length);
          final visibleCalcs = allCalcs.take(shown).toList();
          final hasMore = shown < allCalcs.length;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<CalculatorBloc>().add(CalculatorLoadRequested());
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: AppStyles.listPadding,
              itemCount: visibleCalcs.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == visibleCalcs.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(height: AppStyles.spaceS),
                          Text(
                            'Прокрутите вниз, чтобы показать ещё '
                            '(${allCalcs.length - shown} из ${allCalcs.length})',
                            style: AppStyles.captionStyle,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return _CalculationCard(
                  calculation: visibleCalcs[index],
                  productTemplates: state.productTemplates,
                  userRole: widget.userRole,
                );
              },
            ),
          );
        }

        return const SizedBox();
      },
    );
  }
}

class _CalculationCard extends StatelessWidget {
  final CalculationModel calculation;
  final List productTemplates;
  final String userRole;

  const _CalculationCard({
    required this.calculation,
    required this.productTemplates,
    required this.userRole,
  });

  bool get _isWorker => userRole == 'WORKER';

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final inReview = calculation.status == 'IN_REVIEW';
    final statusColor = AppStyles.statusColor(
      calculation.status,
      isDraft: calculation.isDraft,
    );

    return Card(
      margin: AppStyles.cardMargin,
      child: InkWell(
        borderRadius: AppStyles.radiusM,
        onTap: () async {
          final bloc = context.read<CalculatorBloc>();
          await context.push('/calculation-detail', extra: {
            'calculation': calculation,
            'productTemplates': productTemplates,
          });
          if (context.mounted) bloc.add(CalculatorLoadRequested());
        },
        child: Padding(
          padding: AppStyles.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(calculation.title, style: AppStyles.titleBold),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: inReview
                          ? Colors.grey.shade400
                          : AppStyles.primary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: inReview ? 'Расчёт на модерации' : 'Редактировать',
                    onPressed: inReview
                        ? () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Расчёт на модерации — дождитесь решения администратора',
                                ),
                              ),
                            )
                        : () async {
                            final bloc = context.read<CalculatorBloc>();
                            await context.push('/edit-calculation', extra: {
                              'productTemplates': productTemplates,
                              'calculation': calculation,
                              'isWorker': _isWorker,
                            });
                            if (context.mounted) {
                              bloc.add(CalculatorLoadRequested());
                            }
                          },
                  ),
                  if (!_isWorker) ...[
                    const SizedBox(width: AppStyles.spaceM),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppStyles.danger,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Удалить',
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: AppStyles.spaceXS),
              Text(calculation.clientName, style: AppStyles.subtitleStyle),
              if (calculation.clientPhone != null) ...[
                const SizedBox(height: 2),
                Text(calculation.clientPhone!, style: AppStyles.captionStyle),
              ],
              const SizedBox(height: AppStyles.spaceS),

              if (calculation.products.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.layers_outlined,
                        size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: AppStyles.spaceXS),
                    Text(
                      '${calculation.products.length} изд. — '
                      '${calculation.productsTotal.toStringAsFixed(2)} ₽',
                      style: AppStyles.captionStyle,
                    ),
                    if (calculation.servicesTotal > 0) ...[
                      const SizedBox(width: AppStyles.spaceM),
                      Icon(Icons.miscellaneous_services_outlined,
                          size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: AppStyles.spaceXS),
                      Text(
                        'Услуги — ${calculation.servicesTotal.toStringAsFixed(2)} ₽',
                        style: AppStyles.captionStyle,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppStyles.spaceS),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(calculation.createdAt),
                    style: AppStyles.captionStyle,
                  ),
                  Text(
                    '${calculation.totalPrice.toStringAsFixed(2)} ₽',
                    style: AppStyles.amountLarge,
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.spaceS),

              _StatusBadge(
                status: calculation.status,
                isDraft: calculation.isDraft,
                color: statusColor,
              ),

              if (calculation.reviewRequest?.adminComment != null) ...[
                const SizedBox(height: AppStyles.spaceS),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: AppStyles.infoBoxDecoration(statusColor),
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 13,
                        color: statusColor,
                      ),
                      const SizedBox(width: AppStyles.spaceS),
                      Expanded(
                        child: Text(
                          calculation.reviewRequest!.adminComment!,
                          style: AppStyles.captionStyle.copyWith(
                            color: statusColor,
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
            style: AppStyles.dangerButton,
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
  final Color color;

  const _StatusBadge({
    required this.status,
    required this.isDraft,
    required this.color,
  });

  IconData get _icon {
    switch (status) {
      case 'DRAFT':
        return isDraft ? Icons.edit_note_outlined : Icons.check_circle_outline;
      case 'PENDING':
        return Icons.radio_button_unchecked;
      case 'IN_REVIEW':
        return Icons.pending_outlined;
      case 'APPROVED':
        return Icons.verified_outlined;
      case 'REJECTED':
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, size: 13, color: color),
        const SizedBox(width: AppStyles.spaceXS),
        Text(
          AppStyles.statusText(status, isDraft: isDraft),
          style: AppStyles.captionStyle.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
