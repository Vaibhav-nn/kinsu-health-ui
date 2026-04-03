import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';

enum _AuthStage {
  splash,
  onboarding,
  choice,
  signIn,
  signUp,
}

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  static const _onboardingSeenKey = 'auth_onboarding_seen_v1';

  _AuthStage _stage = _AuthStage.splash;
  int _slideIndex = 0;
  bool _isLoading = false;

  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      title: 'All Records, One Vault',
      description:
          'Upload prescriptions, lab reports, scans, and summaries. Find everything fast.',
      icon: Icons.folder_copy_outlined,
      color: Color(0xFF0A9B8F),
      gradientStart: Color(0xFFE6F7F6),
      gradientEnd: Color(0xFFF0FDFA),
    ),
    _OnboardingSlide(
      title: 'Family Care, Together',
      description:
          'Add family members and log vitals, symptoms, and medications for loved ones.',
      icon: Icons.shield_outlined,
      color: Color(0xFF3B82F6),
      gradientStart: Color(0xFFEFF6FF),
      gradientEnd: Color(0xFFF0F9FF),
    ),
    _OnboardingSlide(
      title: 'AI-Powered Insights',
      description:
          'Get health summaries and contextual guidance with clear source-backed context.',
      icon: Icons.auto_awesome_outlined,
      color: Color(0xFF8B5CF6),
      gradientStart: Color(0xFFF5F3FF),
      gradientEnd: Color(0xFFFAF5FF),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    super.dispose();
  }

  Future<void> _startFlow() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_onboardingSeenKey) ?? false;
    if (!mounted) return;
    setState(() {
      _stage = seen ? _AuthStage.choice : _AuthStage.onboarding;
    });
  }

  Future<void> _markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }

  Future<void> _signInWithEmail() async {
    if (!_signInFormKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _signInEmailController.text.trim(),
        password: _signInPasswordController.text,
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Sign-in failed.');
    } catch (_) {
      _showError('Unable to sign in right now.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithEmail() async {
    if (!_signUpFormKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _signUpEmailController.text.trim(),
        password: _signUpPasswordController.text,
      );
      final fullName = _signUpNameController.text.trim();
      if (fullName.isNotEmpty) {
        await credential.user?.updateDisplayName(fullName);
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Sign-up failed.');
    } catch (_) {
      _showError('Unable to create account right now.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleUser =
            await GoogleSignIn(scopes: const ['email', 'profile']).signIn();
        if (googleUser == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        final auth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Google sign-in failed.');
    } catch (_) {
      _showError('Unable to continue with Google right now.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: switch (_stage) {
            _AuthStage.splash => _buildSplash(),
            _AuthStage.onboarding => _buildOnboarding(),
            _AuthStage.choice => _buildChoice(),
            _AuthStage.signIn => _buildSignIn(),
            _AuthStage.signUp => _buildSignUp(),
          },
        ),
      ),
    );
  }

  Widget _buildSplash() {
    return Container(
      key: const ValueKey('splash'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A9B8F), Color(0xFF088A7F), Color(0xFF06756B)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'K',
                      style: TextStyle(
                        color: KinsuTheme.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Kinsu Health',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your health, unified.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboarding() {
    final slide = _slides[_slideIndex];
    final isLast = _slideIndex == _slides.length - 1;
    return Padding(
      key: const ValueKey('onboarding'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 136,
            height: 136,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [slide.gradientStart, slide.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(slide.icon, color: slide.color, size: 54),
          ),
          const SizedBox(height: 30),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: KinsuTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: KinsuTheme.textSecondary,
              height: 1.45,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _slides.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _slideIndex == index ? 30 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _slideIndex == index
                      ? KinsuTheme.primary
                      : KinsuTheme.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (_slideIndex < _slides.length - 1) {
                  setState(() => _slideIndex += 1);
                } else {
                  await _markOnboardingSeen();
                  if (!mounted) return;
                  setState(() => _stage = _AuthStage.choice);
                }
              },
              icon: const Icon(Icons.chevron_right),
              label: Text(isLast ? 'Get Started' : 'Continue'),
            ),
          ),
          if (!isLast)
            TextButton(
              onPressed: () async {
                await _markOnboardingSeen();
                if (!mounted) return;
                setState(() => _stage = _AuthStage.choice);
              },
              child: const Text('Skip'),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildChoice() {
    return Center(
      key: const ValueKey('choice'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: KinsuTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Kinsu',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Use your email account or continue with Google.',
                  style: TextStyle(color: KinsuTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Continue with Google'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _stage = _AuthStage.signIn),
                    child: const Text('Sign In with Email'),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _stage = _AuthStage.signUp),
                    child: const Text('Create a new account'),
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignIn() {
    return Center(
      key: const ValueKey('signin'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: KinsuTheme.cardDecoration,
            child: Form(
              key: _signInFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _stage = _AuthStage.choice),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign In',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _signInEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'Email is required';
                      if (!email.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _signInPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) {
                      if ((value ?? '').isEmpty) return 'Password is required';
                      return null;
                    },
                    onFieldSubmitted: (_) => _signInWithEmail(),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signInWithEmail,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUp() {
    return Center(
      key: const ValueKey('signup'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: KinsuTheme.cardDecoration,
            child: Form(
              key: _signUpFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _stage = _AuthStage.choice),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _signUpNameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _signUpEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'Email is required';
                      if (!email.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _signUpPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) {
                      final password = value ?? '';
                      if (password.isEmpty) return 'Password is required';
                      if (password.length < 6) return 'At least 6 characters';
                      return null;
                    },
                    onFieldSubmitted: (_) => _signUpWithEmail(),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUpWithEmail,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color gradientStart;
  final Color gradientEnd;

  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradientStart,
    required this.gradientEnd,
  });
}
