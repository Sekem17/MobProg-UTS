import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_page.dart';
import 'main_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMINumber? _numLook;
  SMIBool? _successBool;
  SMIBool? _failBool;

  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameCtrl.addListener(_onUsernameChanged);
    _usernameFocus.addListener(_onUsernameFocusChange);
    _passwordFocus.addListener(_onPasswordFocusChange);

    _loadLastUsername();
  }

  void _loadLastUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUser = prefs.getString('last_registered_user');
    if (lastUser != null) {
      _usernameCtrl.text = lastUser;
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'Login Machine',
    );

    if (controller != null) {
      artboard.addController(controller);

      _isChecking = controller.findInput<bool>('isChecking') as SMIBool?;
      _isHandsUp = controller.findInput<bool>('isHandsUp') as SMIBool?;
      _numLook = controller.findInput<double>('numLook') as SMINumber?;
      _successBool =
          controller.findInput<bool>('success')
              as SMIBool?; // ini gabisa karena harus edit file rive (owner ga kasih buat edit file animasinya T-T)
      _failBool = controller.findInput<bool>('fail') as SMIBool?;

      _isChecking?.value = false;
      _isHandsUp?.value = false;
      _successBool?.value = false;
      _failBool?.value = false;
    }
  }

  void _onUsernameChanged() {
    final textLength = _usernameCtrl.text.length.clamp(0, 20);
    final lookValue = textLength * 1.5;
    _numLook?.value = lookValue.toDouble();
  }

  void _onUsernameFocusChange() {
    if (_usernameFocus.hasFocus) {
      _isChecking?.value = true;
      _isHandsUp?.value = false;
    } else {
      _isChecking?.value = false;
    }
  }

  void _onPasswordFocusChange() {
    if (_passwordFocus.hasFocus) {
      _isHandsUp?.value = true;
    } else {
      _isHandsUp?.value = false;
    }
  }

  void _login() async {
    if (_isLoading) return;

    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi username & password ~~')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final storedPassword = prefs.getString('user_$username');

    if (storedPassword == null) {
      _successBool?.value = false;
      _failBool?.value = true;

      await Future.delayed(const Duration(milliseconds: 1000));
      _failBool?.value = false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username belum terdaftar :v')),
      );
    } else if (storedPassword == password) {
      await prefs.setString('current_user', username);
      _failBool?.value = false;
      _successBool?.value = true;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Welcome brother, $username!')));

      await Future.delayed(const Duration(milliseconds: 1500));
      _successBool?.value = false;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      _successBool?.value = false;
      _failBool?.value = true;

      await Future.delayed(const Duration(milliseconds: 1000));
      _failBool?.value = false;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hayo password salah!')));
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const inputPadding = EdgeInsets.symmetric(vertical: 8, horizontal: 10);

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,

      body: Stack(
        children: [
          Positioned.fill(
            child: RiveAnimation.asset(
              'assets/rive/animated_login_character.riv',
              fit: BoxFit.cover,
              onInit: _onRiveInit,
            ),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 32.0,
                  right: 32.0,
                  top: 470.0,
                  bottom: 40,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Card(
                      color: Theme.of(
                        context,
                      ).cardTheme.color?.withOpacity(0.95),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 16.0,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              height: 30,
                              child: Center(
                                child: Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),

                            TextFormField(
                              controller: _usernameCtrl,
                              focusNode: _usernameFocus,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                prefixIcon: const Icon(Icons.person),
                                border: const OutlineInputBorder(),
                                contentPadding: inputPadding,
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _passwordCtrl,
                              focusNode: _passwordFocus,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock),
                                border: const OutlineInputBorder(),
                                contentPadding: inputPadding,
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Login'),
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Belum punya akun?'),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterPage(),
                                      ),
                                    );
                                  },
                                  child: const Text('Daftar'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
