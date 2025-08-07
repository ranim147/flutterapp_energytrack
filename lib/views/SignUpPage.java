import 'package:flutter/material.dart';
import 'package:flutter_banking_app/widgets/bottom_nav.dart'; // Ta page home
import 'package:flutter_banking_app/views/login.dart';

class SignUpPage extends StatefulWidget {
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Couleurs choisies
  final Color textColor = Colors.black87;                 // Texte noir doux
  final Color buttonColor = Colors.blue[600]!;            // Bleu apaisant pour bouton
  final Color iconAndBorderColor = Colors.black54;        // Icônes en noir doux

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Logique d'inscription ici

      // Navigation vers Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNav()),
      );
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    final upperCaseRegex = RegExp(r'[A-Z]');
    final lowerCaseRegex = RegExp(r'[a-z]');
    final digitRegex = RegExp(r'\d');
    if (!upperCaseRegex.hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une lettre majuscule';
    }
    if (!lowerCaseRegex.hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une lettre minuscule';
    }
    if (!digitRegex.hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: Container(
              margin: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        "Créer un compte",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Veuillez remplir le formulaire pour créer un compte",
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Prénom
                      TextFormField(
                        controller: firstNameController,
                        decoration: InputDecoration(
                          hintText: "Prénom",
                          prefixIcon: Icon(Icons.person, color: iconAndBorderColor),
                          filled: true,
                          fillColor: iconAndBorderColor.withOpacity(0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: iconAndBorderColor, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre prénom';
                          }
                          return null;
                        },
                        style: TextStyle(color: textColor),
                      ),
                      SizedBox(height: 10),
                      // Nom
                      TextFormField(
                        controller: lastNameController,
                        decoration: InputDecoration(
                          hintText: "Nom",
                          prefixIcon: Icon(Icons.person_outline, color: iconAndBorderColor),
                          filled: true,
                          fillColor: iconAndBorderColor.withOpacity(0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: iconAndBorderColor, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre nom';
                          }
                          return null;
                        },
                        style: TextStyle(color: textColor),
                      ),
                      SizedBox(height: 10),
                      // Email
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "Email",
                          prefixIcon: Icon(Icons.email, color: iconAndBorderColor),
                          filled: true,
                          fillColor: iconAndBorderColor.withOpacity(0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: iconAndBorderColor, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre adresse e-mail';
                          }
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Adresse e-mail invalide';
                          }
                          return null;
                        },
                        style: TextStyle(color: textColor),
                      ),
                      SizedBox(height: 10),
                      // Mot de passe
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Mot de passe",
                          prefixIcon: Icon(Icons.lock, color: iconAndBorderColor),
                          filled: true,
                          fillColor: iconAndBorderColor.withOpacity(0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: iconAndBorderColor, width: 2),
                          ),
                        ),
                        validator: _validatePassword,
                        style: TextStyle(color: textColor),
                      ),
                      SizedBox(height: 10),
                      // Confirmer mot de passe
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Confirmer le mot de passe",
                          prefixIcon: Icon(Icons.lock, color: iconAndBorderColor),
                          filled: true,
                          fillColor: iconAndBorderColor.withOpacity(0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: iconAndBorderColor, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez confirmer votre mot de passe';
                          }
                          if (value != passwordController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                        style: TextStyle(color: textColor),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: StadiumBorder(),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: buttonColor, // bouton bleu apaisant
                        ),
                        onPressed: _submit,
                        child: Text(
                          "S'inscrire",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Vous avez déjà un compte ? ", style: TextStyle(color: textColor)),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        },
                        child: Text("Se connecter", style: TextStyle(color: buttonColor)),
                      ),

                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}