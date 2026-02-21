import 'package:cached_network_image/cached_network_image.dart';
import 'package:favorites/main.dart';
import 'package:favorites/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals_flutter.dart';

class Page3 extends StatefulWidget {
  @override
  State<Page3> createState() => _Page3State();
}

class _Page3State extends State<Page3> {
  var captchaState = signal<CaptchaRes>(CaptchaRes.empty());
  var isLoading = signal<bool>(true);
  var _isRegister = signal(false);
  var captchaCodeController = TextEditingController();
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var nicknameController = TextEditingController();

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
    isLoading.value = true; // 开始 loading
    try {
      var r = await captchaCode();
      captchaState.value = CaptchaRes(
        captchaId: r.captchaId,
        success: r.success,
        image: r.image,
      );
    } finally {
      isLoading.value = false; // 结束 loading
    }
  }

  @override
  Widget build(BuildContext context) {
    var rr = captchaState.watch(context);
    var loading = isLoading.watch(context);
    var rrr = _isRegister.watch(context);

    return Scaffold(
      child: Row(
        children: [
          Expanded(
            child: CachedNetworkImage(
              fit: .fitHeight,
              imageUrl:
                  'https://images.unsplash.com/photo-1770110000218-e9376e581258?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
            ),
          ),
          Container(
            width: 350,
            margin: const EdgeInsets.all(20), // 规范化语法
            child: Switcher(
              index: rrr ? 1 : 0,
              direction: .left,
              children: [
                Column(
                  key: Key('login'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('UI Unicorn'),
                    const Text('Nice to see you again'),
                    const Text('Login'),
                    TextField(
                      placeholder: Text('Email or phone number'),
                      controller: emailController,
                    ),
                    const Text('Password'),
                    TextField(
                      placeholder: Text('Enter password'),
                      controller: passwordController,
                      features: [.passwordToggle(mode: .hold)],
                    ),
                    const Text('captcha'),

                    // 5. 彻底移除 FutureBuilder，直接通过我们 watch 到的状态来渲染！
                    if (loading)
                      const SizedBox(
                        width: 100,
                        height: 50,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            height: 50,
                            // 直接从状态 rr 中读取图片
                            child: Image.memory(rr.image),
                          ),
                          Button.card(
                            child: const Icon(Icons.refresh),
                            onPressed: () {
                              // 6. 点击刷新时，直接调用封装好的 handleData 即可！
                              handleData();
                            },
                          ),
                        ],
                      ),

                    TextField(
                      placeholder: Text('Input captcha'),
                      controller: captchaCodeController,
                    ),

                    Button.card(
                      alignment: .center,
                      style: ButtonVariance.primary,
                      child: Text('Login'),
                      onPressed: () async {
                        var r = await login(
                          .new(
                            email: emailController.text,
                            password: passwordController.text,
                            captchaId: captchaState.value.captchaId,
                            captchaCode: captchaCodeController.text,
                          ),
                        );
                        loginInfo.value = .new(
                          isLogin: true,
                          currentUserName: r.nickname,
                          token: r.token,
                        );
                        context.pop();
                      },
                    ),
                    Row(
                      mainAxisAlignment: .end,
                      children: [
                        Text('没有账号？'),
                        Button.ghost(
                          child: Text('创建'),
                          onPressed: () {
                            _isRegister.value = true;
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  key: Key('register-form'),
                  crossAxisAlignment: .stretch,
                  children: [
                    const Text('UI Unicorn'),
                    const Text('Nice to see you again'),
                    const Text('Email'),
                    TextField(
                      placeholder: Text('Input Email'),
                      controller: emailController,
                    ),
                    const Text('Password'),
                    TextField(
                      placeholder: Text('Enter password'),
                      controller: passwordController,
                      features: [.passwordToggle(mode: .hold)],
                    ),
                    const Text('NickName'),
                    TextField(
                      placeholder: Text('Input nick name'),
                      controller: nicknameController,
                    ),
                    const Text('captcha'),

                    // 5. 彻底移除 FutureBuilder，直接通过我们 watch 到的状态来渲染！
                    if (loading)
                      const SizedBox(
                        width: 100,
                        height: 50,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            height: 50,
                            // 直接从状态 rr 中读取图片
                            child: Image.memory(rr.image),
                          ),
                          Button.card(
                            child: const Icon(Icons.refresh),
                            onPressed: () {
                              // 6. 点击刷新时，直接调用封装好的 handleData 即可！
                              handleData();
                            },
                          ),
                        ],
                      ),
                    TextField(
                      placeholder: Text('Input captcha'),
                      controller: captchaCodeController,
                    ),
                    Button.primary(
                      alignment: .center,
                      child: Text('Create Account'),
                      onPressed: () async {
                        await createAccount(
                          CreateAccountReq(
                            email: emailController.text,
                            password: passwordController.text,
                            nickname: nicknameController.text,
                            captchaId: captchaState.value.captchaId,
                            captchaCode: captchaCodeController.text,
                          ),
                        );
                        //跳转到登录页面
                        _isRegister.value = false;
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
