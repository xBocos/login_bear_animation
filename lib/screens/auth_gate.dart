import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_bear_animation/screens/home_screen.dart';
import 'package:login_bear_animation/screens/login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _authStream;
  bool _isCelebrating = false;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
  }

  void _setCelebrating(bool value) {
    if (!mounted) return;
    setState(() {
      _isCelebrating = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && !_isCelebrating) {
          return HomeScreen(key: ValueKey(snapshot.data!.uid));
        }

        return LoginScreen(
          key: const ValueKey('login_screen'),
          onSuccessAnimationStart: () => _setCelebrating(true),
          onSuccessAnimationEnd: () => _setCelebrating(false),
        );
      },
    );
  }
}
