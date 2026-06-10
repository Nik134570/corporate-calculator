import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:calculator/core/di/injection.dart';
import 'package:calculator/core/theme/app_styles.dart';
import 'package:calculator/features/auth/data/repositories/auth_repository.dart';
import 'package:calculator/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:calculator/core/storage/secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(getIt<AuthRepository>()),
      child: Scaffold(
        backgroundColor: AppStyles.background,
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              getIt<SecureStorage>().getUserRole().then((role) {
                if (context.mounted) {
                  if (role == 'ADMIN' || role == 'MANAGER') {
                    context.go('/admin');
                  } else {
                    context.go('/calculations');
                  }
                }
              });
            }
            if (state is AuthFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppStyles.danger,
                ),
              );
            }
          },
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppStyles.spaceXL),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 4,
                  shape: AppStyles.cardShape(16),
                  child: Padding(
                    padding: const EdgeInsets.all(AppStyles.spaceXXL),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.calculate,
                          size: 56,
                          color: AppStyles.primary,
                        ),
                        const SizedBox(height: AppStyles.spaceS),
                        const Text(
                          'Калькулятор',
                          textAlign: TextAlign.center,
                          style: AppStyles.headingLarge,
                        ),
                        const SizedBox(height: AppStyles.spaceXXL),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: AppStyles.inputDecoration(
                            'Email',
                            prefixIcon: const Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: AppStyles.spaceL),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: AppStyles.inputDecoration(
                            'Пароль',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppStyles.spaceXL),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) => ElevatedButton(
                            onPressed: state is AuthLoading
                                ? null
                                : () {
                                    context.read<AuthBloc>().add(
                                          LoginRequested(
                                            _emailController.text.trim(),
                                            _passwordController.text,
                                          ),
                                        );
                                  },
                            style: AppStyles.primaryButton,
                            child: state is AuthLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Войти',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
