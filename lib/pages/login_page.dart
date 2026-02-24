import 'package:cached_network_image/cached_network_image.dart';
import 'package:favorites/main.dart';
import 'package:favorites/models/api.dart';
import 'package:favorites/services/api_service.dart';
import 'package:flutter/material.dart' as material;
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final captchaState = signal<CaptchaRes>(CaptchaRes.empty());
  final isLoading = signal<bool>(true);
  final isRegister = signal<bool>(false);
  final isSubmitting = signal<bool>(false);
  final errorMessage = signal<String?>(null);

  final captchaCodeController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nicknameController = TextEditingController();

  bool get isValidForm {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      return false;
    }
    if (isRegister.value && nicknameController.text.isEmpty) {
      return false;
    }
    if (captchaCodeController.text.isEmpty) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadCaptcha();
  }

  @override
  void dispose() {
    captchaState.dispose();
    isLoading.dispose();
    isRegister.dispose();
    isSubmitting.dispose();
    errorMessage.dispose();
    captchaCodeController.dispose();
    emailController.dispose();
    passwordController.dispose();
    nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadCaptcha() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final r = await captchaCode();
      captchaState.value = CaptchaRes(
        captchaId: r.captchaId,
        success: r.success,
        image: r.image,
      );
    } catch (e) {
      errorMessage.value = '加载验证码失败，请重试';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleLogin() async {
    if (!isValidForm) {
      errorMessage.value = '请填写所有必填项';
      return;
    }

    isSubmitting.value = true;
    errorMessage.value = null;

    try {
      final r = await login(
        LoginReq(
          email: emailController.text.trim(),
          password: passwordController.text,
          captchaId: captchaState.value.captchaId,
          captchaCode: captchaCodeController.text.trim(),
        ),
      );

      if (r.success) {
        loginInfo.value = LoginInfo(
          isLogin: true,
          currentUserName: r.nickname,
          token: r.token,
          currentUserAvatar: r.avatar == null
              ? null
              : 'http://localhost:8081${r.avatar}',
        );
        if (mounted) context.pop();
      } else {
        errorMessage.value = r.message.isNotEmpty ? r.message : '登录失败';
        await _loadCaptcha();
      }
    } catch (e) {
      errorMessage.value = '登录失败，请检查网络连接';
      await _loadCaptcha();
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _handleRegister() async {
    if (!isValidForm) {
      errorMessage.value = '请填写所有必填项';
      return;
    }

    isSubmitting.value = true;
    errorMessage.value = null;

    try {
      await createAccount(
        CreateAccountReq(
          email: emailController.text.trim(),
          password: passwordController.text,
          nickname: nicknameController.text.trim(),
          captchaId: captchaState.value.captchaId,
          captchaCode: captchaCodeController.text.trim(),
        ),
      );
      errorMessage.value = null;
      isRegister.value = false;
      _showSuccessMessage('注册成功，请登录');
    } catch (e) {
      errorMessage.value = '注册失败，请重试';
      await _loadCaptcha();
    } finally {
      isSubmitting.value = false;
    }
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    material.ScaffoldMessenger.of(context).showSnackBar(
      material.SnackBar(
        content: material.Text(message),
        backgroundColor: material.Colors.green,
        behavior: material.SnackBarBehavior.floating,
      ),
    );
  }

  void _switchToRegister(bool value) {
    isRegister.value = value;
    errorMessage.value = null;
    captchaCodeController.clear();
  }

  Widget _buildCaptchaSection() {
    final loading = isLoading.watch(context);
    final captcha = captchaState.watch(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('验证码'),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 120,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.gray),
                borderRadius: BorderRadius.circular(8),
              ),
              child: loading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.memory(captcha.image, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(width: 12),
            Button.outline(
              onPressed: loading ? null : _loadCaptcha,
              child: const Icon(Icons.refresh, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          placeholder: const Text('请输入验证码'),
          controller: captchaCodeController,
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    final error = errorMessage.watch(context);
    if (error == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[400]),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    final submitting = isSubmitting.watch(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Text(
            '欢迎回来',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '请登录您的账号',
            style: TextStyle(fontSize: 14, color: Colors.gray[600]),
          ),
          const SizedBox(height: 32),
          _buildErrorMessage(),
          const Text('邮箱'),
          const SizedBox(height: 8),
          TextField(
            placeholder: const Text('请输入邮箱'),
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          const Text('密码'),
          const SizedBox(height: 8),
          TextField(
            placeholder: const Text('请输入密码'),
            controller: passwordController,
            features: [.passwordToggle(mode: .hold)],
          ),
          const SizedBox(height: 16),
          _buildCaptchaSection(),
          const SizedBox(height: 24),
          Button.primary(
            alignment: Alignment.center,
            onPressed: submitting ? null : _handleLogin,
            child: submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('登录'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('还没有账号？', style: TextStyle(color: Colors.gray[600])),
              Button.ghost(
                onPressed: () => _switchToRegister(true),
                child: const Text('立即注册'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    final submitting = isSubmitting.watch(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Text(
            '创建账号',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '注册一个新账号',
            style: TextStyle(fontSize: 14, color: Colors.gray[600]),
          ),
          const SizedBox(height: 32),
          _buildErrorMessage(),
          const Text('邮箱'),
          const SizedBox(height: 8),
          TextField(
            placeholder: const Text('请输入邮箱'),
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          const Text('密码'),
          const SizedBox(height: 8),
          TextField(
            placeholder: const Text('请输入密码'),
            controller: passwordController,
            features: [.passwordToggle(mode: .hold)],
          ),
          const SizedBox(height: 16),
          const Text('昵称'),
          const SizedBox(height: 8),
          TextField(
            placeholder: const Text('请输入昵称'),
            controller: nicknameController,
          ),
          const SizedBox(height: 16),
          _buildCaptchaSection(),
          const SizedBox(height: 24),
          Button.primary(
            alignment: Alignment.center,
            onPressed: submitting ? null : _handleRegister,
            child: submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('注册'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('已有账号？', style: TextStyle(color: Colors.gray[600])),
              Button.ghost(
                onPressed: () => _switchToRegister(false),
                child: const Text('返回登录'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRegisterMode = isRegister.watch(context);

    return Scaffold(
      child: Row(
        children: [
          Expanded(
            child: CachedNetworkImage(
              fit: BoxFit.fitHeight,
              imageUrl:
                  'https://images.unsplash.com/photo-1770110000218-e9376e581258?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
              placeholder: (context, url) => Container(color: Colors.gray[200]),
              errorWidget: (context, url, error) =>
                  Container(color: Colors.gray[300]),
            ),
          ),
          Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: isRegisterMode ? _buildRegisterForm() : _buildLoginForm(),
            ),
          ),
        ],
      ),
    );
  }
}
