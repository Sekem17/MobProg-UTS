import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'login_page.dart';
import 'register_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard, 
      'Login Machine', 
    );
    
    if (controller != null) {
      artboard.addController(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
              alignment: Alignment.topCenter, 
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YAPP', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Spacer(), 
                  
                  Text('Selamat Datang di Projek UTS Mobile Programming', style: theme.textTheme.headlineLarge?.copyWith(color: const Color.fromARGB(214, 255, 255, 255), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Semoga konten pembelajaran ini dapat dimanfaatkan dan berguna untuk kedepannya, Tema aplikasi ini ialah media sosial (kami mengambil contoh seperti aplikasi "X" yang dulunya bernama Twitter).',
                    style: theme.textTheme.titleMedium?.copyWith(color: const Color.fromARGB(149, 255, 255, 255)),
                  ),
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                      ),
                      child: const Text('Log in'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Colors.white),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Sign up'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}