import 'package:favorites/main.dart';
import 'package:favorites/models/api.dart';
import 'package:favorites/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class login_page extends StatefulWidget {
  @override
  State<login_page> createState() => _login_pageState();
}

class _login_pageState extends State<login_page> {
  final captchaState = signal<CaptchaRes>(CaptchaRes.empty());
  final isLoading = signal<bool>(true);
  final _isRegister = signal(false);
  final captchaCodeController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    handleData();
  }

  @override
  void dispose() {
    captchaState.dispose();
    isLoading.dispose();
    _isRegister.dispose();
    captchaCodeController.dispose();
    emailController.dispose();
    passwordController.dispose();
    nicknameController.dispose();
    super.dispose();
  }

  Future<void> handleData() async {
    isLoading.value = true;
    try {
      var r = await captchaCode();
      captchaState.value = CaptchaRes(
        captchaId: r.captchaId,
        success: r.success,
        image: r.image,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Widget _buildSocialButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: Button.outline(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 18),
            const SizedBox(width: 10),
            Text(text),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or sign in with email',
            style: TextStyle(color: Colors.gray, fontSize: 12),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var rr = captchaState.watch(context);
    var loading = isLoading.watch(context);
    var rrr = _isRegister.watch(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      child: Center(
        child: Container(
          width: 900,
          height: 600,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // 左侧渐变色区域
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF8B5CF6),
                        Color(0xFFA855F7),
                        Color(0xFFEC4899),
                        Color(0xFFF97316),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // 装饰性圆形
                      Positioned(
                        top: 80,
                        right: 40,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 120,
                        right: 80,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      // Logo
                      Positioned(
                        top: 40,
                        left: 40,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.bookmark,
                                color: Color(0xFF8B5CF6),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Favorites',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 欢迎文案
                      Positioned(
                        bottom: 80,
                        left: 40,
                        right: 40,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Discover\nsomething\nnew',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Join our community of creators and\nexplorers. Your next adventure awaits.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 右侧表单区域
              Container(
                width: 420,
                padding: const EdgeInsets.all(48),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: rrr
                      ? _buildRegisterForm(rr, loading)
                      : _buildLoginForm(rr, loading),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(CaptchaRes rr, bool loading) {
    return Column(
      key: const Key('login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to continue to your account',
          style: TextStyle(fontSize: 14, color: Colors.gray),
        ),
        const SizedBox(height: 32),
        _buildSocialButton(
          'Continue with Google',
          FontAwesomeIcons.google,
          () {},
        ),
        const SizedBox(height: 12),
        _buildSocialButton(
          'Continue with GitHub',
          FontAwesomeIcons.github,
          () {},
        ),
        const SizedBox(height: 24),
        _buildDivider(),
        const SizedBox(height: 24),
        _buildInputLabel('Email address'),
        const SizedBox(height: 6),
        TextField(
          controller: emailController,
          placeholder: const Text('hello@example.com'),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInputLabel('Password'),
            Button.ghost(
              onPressed: () {},
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontSize: 12, color: Color(0xFF8B5CF6)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: passwordController,
          placeholder: const Text('••••••••'),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        _buildInputLabel('Verification Code'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: captchaCodeController,
                placeholder: const Text('Enter code'),
              ),
            ),
            const SizedBox(width: 12),
            if (loading)
              Container(
                width: 100,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.gray.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: handleData,
                child: Container(
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.gray.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.memory(rr.image, fit: BoxFit.cover),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _buildGradientButton('Sign In', () async {
          var r = await login(
            LoginReq(
              email: emailController.text,
              password: passwordController.text,
              captchaId: captchaState.value.captchaId,
              captchaCode: captchaCodeController.text,
            ),
          );
          if (mounted) {
            loginInfo.value = LoginInfo(
              isLogin: true,
              currentUserName: r.nickname,
              token: r.token,
              currentUserAvatar: r.avatar == null
                  ? null
                  : 'http://localhost:8081${r.avatar}',
            );
            context.pop();
          }
        }),
        const SizedBox(height: 24),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(fontSize: 13, color: Colors.gray),
              ),
              Button.ghost(
                onPressed: () => _isRegister.value = true,
                child: const Text(
                  'Sign up for free',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8B5CF6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(CaptchaRes rr, bool loading) {
    return Column(
      key: const Key('register'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create account',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign up to get started with Favorites',
          style: TextStyle(fontSize: 14, color: Colors.gray),
        ),
        const SizedBox(height: 32),
        _buildInputLabel('Email address'),
        const SizedBox(height: 6),
        TextField(
          controller: emailController,
          placeholder: const Text('hello@example.com'),
        ),
        const SizedBox(height: 16),
        _buildInputLabel('Password'),
        const SizedBox(height: 6),
        TextField(
          controller: passwordController,
          placeholder: const Text('••••••••'),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        _buildInputLabel('Nickname'),
        const SizedBox(height: 6),
        TextField(
          controller: nicknameController,
          placeholder: const Text('Your nickname'),
        ),
        const SizedBox(height: 16),
        _buildInputLabel('Verification Code'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: captchaCodeController,
                placeholder: const Text('Enter code'),
              ),
            ),
            const SizedBox(width: 12),
            if (loading)
              Container(
                width: 100,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.gray.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: handleData,
                child: Container(
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.gray.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.memory(rr.image, fit: BoxFit.cover),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _buildGradientButton('Create Account', () async {
          await createAccount(
            CreateAccountReq(
              email: emailController.text,
              password: passwordController.text,
              nickname: nicknameController.text,
              captchaId: captchaState.value.captchaId,
              captchaCode: captchaCodeController.text,
            ),
          );
          _isRegister.value = false;
        }),
        const SizedBox(height: 24),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(fontSize: 13, color: Colors.gray),
              ),
              Button.ghost(
                onPressed: () => _isRegister.value = false,
                child: const Text(
                  'Sign in',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8B5CF6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
