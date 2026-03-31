import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:calculator/core/di/injection.dart';
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
        backgroundColor: Colors.grey.shade100,
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
      SnackBar(content: Text(state.message), backgroundColor: Colors.red),
    );
  }
},
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.calculate, size: 56, color: Colors.blue),
                        const SizedBox(height: 8),
                        const Text(
                          'Калькулятор',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Пароль',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) => ElevatedButton(
                            onPressed: state is AuthLoading
                                ? null
                                : () {
                                    context.read<AuthBloc>().add(LoginRequested(
                                          _emailController.text.trim(),
                                          _passwordController.text,
                                        ));
                                  },
                            style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16)),
                            child: state is AuthLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Войти',
                                    style: TextStyle(fontSize: 16)),
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
