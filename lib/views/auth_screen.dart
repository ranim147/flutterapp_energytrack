import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:energy_app/widgets/bottom_nav.dart';
import 'package:energy_app/views/reset_password.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    debugPrint('Initialisation de AuthScreen');

    // Vérifier l'état de connexion au démarrage
    _checkCurrentUser();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
  }

  Future<void> _checkCurrentUser() async {
    debugPrint('Vérification de l\'utilisateur actuel...');
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        debugPrint('Utilisateur déjà connecté: ${user.email}');
        debugPrint('Email vérifié: ${user.emailVerified}');
        debugPrint('UID: ${user.uid}');

        if (user.emailVerified) {
          debugPrint('Redirection vers l\'accueil...');
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BottomNav()),
            );
          }
        } else {
          debugPrint('Email non vérifié - Envoyer un nouvel email de vérification');
          await user.sendEmailVerification();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Un email de vérification a été envoyé')),
            );
          }
        }
      } else {
        debugPrint('Aucun utilisateur connecté');
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'utilisateur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    debugPrint('Dispose de AuthScreen');
    _animationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez entrer un mot de passe';
    if (value.length < 8) return 'Minimum 8 caractères';
    if (!value.contains(RegExp(r'[A-Z]'))) return '1 majuscule requise';
    if (!value.contains(RegExp(r'[0-9]'))) return '1 chiffre requis';
    if (!value.contains(RegExp(r'[!@#\\$%^&*(),.?":{}|<>]'))) return '1 caractère spécial requis';
    return null;
  }

  Future<void> _submit() async {
    debugPrint('Tentative de ${_isLogin ? 'connexion' : 'inscription'}');

    if (_isLoading) {
      debugPrint('Déjà en cours de traitement - bloqué');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      debugPrint('Validation du formulaire échouée');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        debugPrint('Tentative de connexion avec Firebase...');
        debugPrint('Email: ${_emailController.text.trim()}');

        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        debugPrint('Connexion réussie !');
        debugPrint('Utilisateur: ${userCredential.user}');

        // Suppression de la vérification d'email
        if (!mounted) {
          debugPrint('Widget non monté - annulation');
          return;
        }

        debugPrint('Redirection vers BottomNav...');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNav()),
        );
      } else {
        // [Le reste du code pour l'inscription reste inchangé]
        debugPrint('Tentative d\'inscription avec Firebase...');
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        debugPrint('Inscription réussie, mise à jour du profil...');
        await userCredential.user?.updateDisplayName(_usernameController.text.trim());
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': _emailController.text.trim(),
          'displayName': _usernameController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('Envoi de l\'email de vérification...');
        await userCredential.user?.sendEmailVerification();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Inscription réussie! Veuillez vérifier votre email.")),
          );
        }

        debugPrint('Passage en mode connexion');
        setState(() => _isLogin = true);
      }
    } on FirebaseAuthException catch (e) {
      print("Erreur Firebase : ${e.code}");
      debugPrint('Erreur FirebaseAuth: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Le mot de passe est trop faible (min. 8 caractères)';
          break;
        case 'email-already-in-use':
          errorMessage = 'Un compte existe déjà avec cet email';
          break;
        case 'user-not-found':
          errorMessage = 'Aucun compte trouvé avec cet email';
          break;
        case 'wrong-password':
          errorMessage = 'Mot de passe incorrect';
          break;
        case 'invalid-email':
          errorMessage = 'Email invalide';
          break;
        case 'too-many-requests':
          errorMessage = 'Trop de tentatives. Réessayez plus tard';
          break;
        case 'user-disabled':
          errorMessage = 'Ce compte a été désactivé';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Opération non autorisée';
          break;
        case 'network-request-failed':
          errorMessage = 'Erreur réseau. Vérifiez votre connexion';
          break;
        default:
          errorMessage = 'Erreur inattendue: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      debugPrint('Erreur inattendue: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      debugPrint('Fin du traitement - isLoading = false');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez entrer un email valide pour réinitialiser le mot de passe')),
        );
      }
      return;
    }

    try {
      debugPrint('Envoi de l\'email de réinitialisation à $email');
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email de réinitialisation envoyé')),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi de l\'email de réinitialisation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Widget _buildEnergyField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.blueGrey[50]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF64B5F6).withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 10),
            child: Icon(
              icon,
              color: const Color(0xFF1976D2),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  color: Colors.blueGrey,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(15),
                suffixIcon: suffixIcon,
              ),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyTabButton(String text, bool isActive, VoidCallback onPressed) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: isActive
            ? const LinearGradient(
          colors: [
            Color(0xFF42A5F5),
            Color(0xFF0D47A1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        boxShadow: isActive
            ? [
          BoxShadow(
            color: const Color(0xFF42A5F5).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.blueGrey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFBBDEFB),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Opacity(
                opacity: 0.05,
                child: Icon(
                  Icons.bolt,
                  size: 300,
                  color: Colors.blue[900],
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Opacity(
                            opacity: _opacityAnimation.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF64B5F6).withOpacity(0.3),
                                      width: 8,
                                    ),
                                  ),
                                ),
                                Image.asset(
                                  'assets/brain71.png',
                                  width: 120,
                                  height: 120,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF1976D2),
                          Color(0xFF0D47A1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        'EnergyTrack',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildEnergyTabButton('CONNEXION', _isLogin, () {
                            if (!_isLogin) setState(() => _isLogin = true);
                          }),
                          _buildEnergyTabButton('INSCRIPTION', !_isLogin, () {
                            if (_isLogin) setState(() => _isLogin = false);
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueGrey.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (!_isLogin) ...[
                              _buildEnergyField(
                                controller: _usernameController,
                                icon: Icons.person_outline,
                                label: "Nom d'utilisateur",
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Veuillez entrer un nom';
                                  if (value.length < 3) return 'Minimum 3 caractères';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                            ],

                            _buildEnergyField(
                              controller: _emailController,
                              icon: Icons.email_outlined,
                              label: 'Email',
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Veuillez entrer votre email';
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Email invalide';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            _buildEnergyField(
                              controller: _passwordController,
                              icon: Icons.lock_outline,
                              label: 'Mot de passe',
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: const Color(0xFF1976D2),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Veuillez entrer un mot de passe';
                                if (!_isLogin) return _validatePassword(value);
                                return null;
                              },
                            ),

                            if (!_isLogin) ...[
                              const SizedBox(height: 20),
                              _buildEnergyField(
                                controller: _confirmPasswordController,
                                icon: Icons.lock_reset_outlined,
                                label: 'Confirmer le mot de passe',
                                obscureText: _obscureConfirmPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: const Color(0xFF1976D2),
                                  ),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Veuillez confirmer votre mot de passe';
                                  if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                                  return null;
                                },
                              ),
                            ],

                            const SizedBox(height: 30),

                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: double.infinity,
                              height: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF42A5F5),
                                    Color(0xFF1976D2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF42A5F5).withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  onTap: _submit,
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                        : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isLogin ? Icons.bolt : Icons.person_add_alt_1,
                                          color: Colors.amber[100],
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _isLogin ? 'SE CONNECTER' : 'CRÉER UN COMPTE',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            if (_isLogin) ...[
                              const SizedBox(height: 15),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
                                  );
                                },
                                child: Text(
                                  'Mot de passe oublié ?',
                                  style: TextStyle(
                                    color: Colors.blueGrey[600],
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}