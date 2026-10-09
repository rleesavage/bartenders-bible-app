import 'package:flutter/material.dart';

import 'api.dart';
import 'theme.dart';
import 'widgets.dart';

class LoginScreen extends StatefulWidget {
  final Api api;
  final VoidCallback onLogin;
  final VoidCallback create;

  const LoginScreen({
    super.key,
    required this.api,
    required this.onLogin,
    required this.create,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  String? error;
  bool busy = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });

    try {
      await widget.api.login(email.text, password.text);
      widget.onLogin();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const BbHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  const SizedBox(height: 16),
                  const SectionTitle(
                    'Member Login',
                    subtitle: 'Enter the Bartender’s Bible.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const <String>[AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    onSubmitted: (_) => submit(),
                    autofillHints: const <String>[AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  if (error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: busy ? null : submit,
                    child: Text(busy ? 'Logging in…' : 'Login'),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: widget.create,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('New Users must CREATE ACCOUNT'),
                  ),
                ],
              ),
            ),
            const _AuthFooter(),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  final Api api;
  final VoidCallback back;

  const RegisterScreen({
    super.key,
    required this.api,
    required this.back,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final repeat = TextEditingController();

  String? message;
  bool success = false;
  bool busy = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    repeat.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (password.text.length < 12) {
      setState(() {
        success = false;
        message = 'Password must contain at least 12 characters.';
      });
      return;
    }

    if (password.text != repeat.text) {
      setState(() {
        success = false;
        message = 'The two passwords do not match.';
      });
      return;
    }

    setState(() {
      busy = true;
      message = null;
    });

    try {
      final response = await widget.api.post('register.php', <String, dynamic>{
        'name': name.text,
        'email': email.text,
        'password': password.text,
      });
      if (mounted) {
        setState(() {
          success = true;
          message = response['message'].toString();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          success = false;
          message = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const BbHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: <Widget>[
                  const SectionTitle(
                    'Create Account',
                    subtitle:
                        'Your email must be verified before you can log in.',
                  ),
                  const SizedBox(height: 14),
                  if (!success) ...<Widget>[
                    TextField(
                      controller: name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: password,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Password must contain at least 12 characters.',
                      ),
                    ),
                    TextField(
                      controller: repeat,
                      obscureText: true,
                      onSubmitted: (_) => submit(),
                      decoration:
                          const InputDecoration(labelText: 'Repeat Password'),
                    ),
                  ],
                  if (message != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          message!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: success ? BbColors.brown : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (!success)
                    ElevatedButton(
                      onPressed: busy ? null : submit,
                      child: Text(busy ? 'Creating…' : 'Create Account'),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: widget.back,
                    child: const Text('Existing Users LOGIN'),
                  ),
                ],
              ),
            ),
            const _AuthFooter(),
          ],
        ),
      ),
    );
  }
}

class _AuthFooter extends StatelessWidget {
  const _AuthFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: BbColors.brown,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: const Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Webolium',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: BbColors.parchment,
                fontWeight: FontWeight.bold,
                fontSize: 8.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Bartenders Bible v1.0',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: BbColors.parchment,
                fontStyle: FontStyle.italic,
                fontSize: 8,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '© RL Savage 2026',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: BbColors.parchment,
                fontSize: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
