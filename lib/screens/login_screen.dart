// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/common_widgets.dart';

enum _LoginMode { loading, setup, login, recovery, newPassword }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _LoginMode _mode = _LoginMode.loading;

  // Controllers
  final _passCtrl        = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmCtrl     = TextEditingController();
  final _codeCtrl        = TextEditingController();

  bool _obscurePass    = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _loading        = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _detectMode();
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    _emailCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectMode() async {
    final auth = context.read<AuthService>();
    final first = await auth.isFirstRun();
    setState(() => _mode = first ? _LoginMode.setup : _LoginMode.login);
  }

  // ── Setup (primeira execução) ─────────────────────────────────────────────
  Future<void> _handleSetup() async {
    setState(() => _error = null);

    if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
      setState(() => _error = 'Informe um e-mail válido para recuperação de senha.');
      return;
    }
    if (_newPassCtrl.text.length < 4) {
      setState(() => _error = 'A senha deve ter pelo menos 4 caracteres.');
      return;
    }
    if (_newPassCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'As senhas não coincidem.');
      return;
    }

    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    await auth.setupPassword(_newPassCtrl.text, _emailCtrl.text.trim());
    await auth.login(_newPassCtrl.text);
    setState(() => _loading = false);
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    setState(() { _error = null; _loading = true; });
    final auth = context.read<AuthService>();
    final ok = await auth.login(_passCtrl.text);
    if (!ok) {
      setState(() {
        _error = 'Senha incorreta. Tente novamente.';
        _loading = false;
      });
    }
  }

  // ── Recuperação: enviar código ────────────────────────────────────────────
  Future<void> _handleSendCode() async {
    setState(() { _error = null; _loading = true; });
    final auth = context.read<AuthService>();
    final ok = await auth.sendRecoveryEmail();
    setState(() => _loading = false);
    if (ok) {
      _showSnack('Código enviado! Verifique seu e-mail.');
      setState(() => _mode = _LoginMode.newPassword);
    } else {
      setState(() => _error = 'Não foi possível enviar o e-mail. Verifique se há um app de e-mail configurado.');
    }
  }

  // ── Recuperação: verificar código e redefinir senha ───────────────────────
  Future<void> _handleResetPassword() async {
    setState(() => _error = null);
    if (_codeCtrl.text.trim().length != 6) {
      setState(() => _error = 'O código deve ter 6 dígitos.');
      return;
    }
    if (_newPassCtrl.text.length < 4) {
      setState(() => _error = 'A nova senha deve ter pelo menos 4 caracteres.');
      return;
    }
    if (_newPassCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'As senhas não coincidem.');
      return;
    }

    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final valid = await auth.verifyResetCode(_codeCtrl.text.trim());
    if (!valid) {
      setState(() { _error = 'Código inválido ou expirado.'; _loading = false; });
      return;
    }
    await auth.updatePassword(_newPassCtrl.text);
    setState(() => _loading = false);
    _showSnack('Senha redefinida com sucesso!');
    setState(() {
      _mode = _LoginMode.login;
      _newPassCtrl.clear();
      _confirmCtrl.clear();
      _codeCtrl.clear();
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? constraints.maxWidth * 0.28 : 24,
                vertical: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppLogo(size: 36),
                      IconButton(
                        onPressed: themeProvider.toggleTheme,
                        icon: Icon(
                          themeProvider.isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Form body
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildBody(),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    switch (_mode) {
      case _LoginMode.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      case _LoginMode.setup:
        return _buildSetup();
      case _LoginMode.login:
        return _buildLogin();
      case _LoginMode.recovery:
        return _buildRecovery();
      case _LoginMode.newPassword:
        return _buildNewPassword();
    }
  }

  // ── TELA: Configuração inicial ────────────────────────────────────────────
  Widget _buildSetup() {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('setup'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Bem-vindo!', style: theme.textTheme.displayMedium),
        const SizedBox(height: 6),
        Text(
          'Configure sua senha e e-mail de recuperação para começar.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),

        // E-mail de recuperação
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'E-mail de recuperação *',
            prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 14),

        // Nova senha
        TextField(
          controller: _newPassCtrl,
          obscureText: _obscureNew,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Criar senha *',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(_obscureNew
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Confirmar senha
        TextField(
          controller: _confirmCtrl,
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleSetup(),
          decoration: InputDecoration(
            labelText: 'Confirmar senha *',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),

        _errorWidget(),
        const SizedBox(height: 24),

        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _handleSetup,
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Criar acesso'),
          ),
        ),
      ],
    );
  }

  // ── TELA: Login ───────────────────────────────────────────────────────────
  Widget _buildLogin() {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Bem-vindo de volta', style: theme.textTheme.displayMedium),
        const SizedBox(height: 6),
        Text('Entre com sua senha para continuar.', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 32),

        TextField(
          controller: _passCtrl,
          obscureText: _obscurePass,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleLogin(),
          decoration: InputDecoration(
            labelText: 'Senha',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(_obscurePass
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
        ),

        _errorWidget(),
        const SizedBox(height: 24),

        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _handleLogin,
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Entrar'),
          ),
        ),
        const SizedBox(height: 12),

        TextButton(
          onPressed: () => setState(() { _mode = _LoginMode.recovery; _error = null; }),
          child: const Text('Esqueci minha senha',
              style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }

  // ── TELA: Recuperação (enviar código) ─────────────────────────────────────
  Widget _buildRecovery() {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('recovery'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Recuperar senha', style: theme.textTheme.displayMedium),
        const SizedBox(height: 6),
        Text(
          'Um código de 6 dígitos será enviado para o e-mail cadastrado.',
          style: theme.textTheme.bodyMedium,
        ),
        _errorWidget(),
        const SizedBox(height: 32),

        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _handleSendCode,
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Enviar código por e-mail'),
          ),
        ),
        const SizedBox(height: 12),

        TextButton(
          onPressed: () => setState(() { _mode = _LoginMode.login; _error = null; }),
          child: const Text('← Voltar ao login',
              style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }

  // ── TELA: Redefinir senha com código ──────────────────────────────────────
  Widget _buildNewPassword() {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('newpass'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Nova senha', style: theme.textTheme.displayMedium),
        const SizedBox(height: 6),
        Text('Digite o código recebido por e-mail e defina sua nova senha.',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 32),

        // Código
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Código de 6 dígitos',
            prefixIcon: Icon(Icons.pin_outlined, color: AppColors.primary),
            counterText: '',
          ),
        ),
        const SizedBox(height: 14),

        // Nova senha
        TextField(
          controller: _newPassCtrl,
          obscureText: _obscureNew,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Nova senha',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(_obscureNew
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Confirmar
        TextField(
          controller: _confirmCtrl,
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleResetPassword(),
          decoration: InputDecoration(
            labelText: 'Confirmar nova senha',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),

        _errorWidget(),
        const SizedBox(height: 24),

        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _handleResetPassword,
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Redefinir senha'),
          ),
        ),
        const SizedBox(height: 12),

        TextButton(
          onPressed: () => setState(() { _mode = _LoginMode.recovery; _error = null; }),
          child: const Text('← Reenviar código',
              style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }

  // ── Widget de erro ────────────────────────────────────────────────────────
  Widget _errorWidget() {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(_error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
