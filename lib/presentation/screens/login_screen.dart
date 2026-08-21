import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ref.read(authStateProvider.notifier).login(_email, _password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('TaskFlow Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter email' : null,
                onSaved: (value) => _email = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter password' : null,
                onSaved: (value) => _password = value!,
              ),
              const SizedBox(height: 24),
              authState.when(
                data: (_) => ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Login'),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (err, _) => Column(
                  children: [
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Login'),
                    ),
                    const SizedBox(height: 8),
                    Text(err.toString(), style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
