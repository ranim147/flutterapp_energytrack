
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:energy_app/utils/styles.dart';
import 'package:energy_app/view_models/view_models.dart';
import 'package:energy_app/views/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Test de connexion Firebase
  try {
    UserCredential user = await FirebaseAuth.instance.signInAnonymously();
    print("🔥 Connexion Firebase réussie ! UID: ${user.user?.uid}");

    // Test Firestore
    await FirebaseFirestore.instance.collection('test').doc('test').set({
      'test': DateTime.now(),
    });
    print("📝 Écriture Firestore réussie");

  } catch (e) {
    print("❌ Erreur Firebase: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ViewModel()),
      ],
      child: MaterialApp(
        title: 'Flutter Banking App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'DMSans',
          primaryColor: Styles.primaryColor,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}