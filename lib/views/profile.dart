import 'package:energy_app/views/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  File? _imageFile;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      _user = _auth.currentUser;
      if (_user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(_user!.uid).get();

        if (doc.exists) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>;
            _nameController.text = _userData?['name'] ?? '';
            _emailController.text = _userData?['email'] ?? _user?.email ?? '';
            _phoneController.text = _userData?['phone'] ?? '';
            _isLoading = false;
          });
        } else {
          await _createUserDocument();
        }
      }
    } catch (e) {
      print("Erreur de chargement des données: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createUserDocument() async {
    if (_user != null) {
      await _firestore.collection('users').doc(_user!.uid).set({
        'name': _user!.displayName ?? 'Nouvel utilisateur',
        'email': _user!.email,
        'phone': '',
        'photoUrl': _user!.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _loadUserData();
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  ImageProvider<Object>? _getProfileImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (_userData?['photoUrl'] != null) {
      return NetworkImage(_userData!['photoUrl'] as String);
    }
    return null;
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isLoading = true);

        if (_nameController.text != _user?.displayName) {
          await _user?.updateDisplayName(_nameController.text);
        }

        if (_emailController.text != _user?.email) {
          await _user?.verifyBeforeUpdateEmail(_emailController.text);
        }

        await _firestore.collection('users').doc(_user!.uid).update({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        await _loadUserData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: ${e.toString()}"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmLogout() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de déconnexion: $e')),
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1976D2)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.blueGrey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withAlpha((0.3 * 255).toInt()),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).toInt()),
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
              enabled: enabled,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Photo de profil
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _getProfileImage(),
                  child: _imageFile == null && _userData?['photoUrl'] == null
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                    onPressed: _pickImage,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Nom et email
            Text(
              _userData?['name'] ?? 'Aucun nom',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D47A1),
              ),
            ),
            Text(
              _userData?['email'] ?? 'Aucun email',
              style: TextStyle(
                color: Colors.blueGrey[700],
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            // Carte d'informations
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.phone, 'Téléphone',
                        _userData?['phone']?.isNotEmpty == true ? _userData!['phone'] : 'Non renseigné'),
                    const Divider(),
                    _buildInfoRow(Icons.email, 'Email',
                        _userData?['email'] ?? 'Non renseigné'),
                    const Divider(),
                    _buildInfoRow(Icons.date_range, 'Membre depuis',
                        _userData?['createdAt'] != null
                            ? DateFormat('dd/MM/yyyy').format((_userData!['createdAt'] as Timestamp).toDate())
                            : 'Inconnu'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bouton de modification
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _showEditDialog,
                child: const Text(
                  'MODIFIER LE PROFIL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Section sécurité du compte
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sécurité du compte',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Se déconnecter',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      tileColor: Colors.red.withOpacity(0.05),
                      onTap: _confirmLogout,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.black87),
                      title: const Text(
                        'Supprimer mon compte',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      tileColor: Colors.grey.withOpacity(0.1),
                      onTap: _confirmDeleteAccount,
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
  Future<void> _confirmDeleteAccount() async {
    final _passwordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez entrer votre mot de passe pour confirmer.'),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount(_passwordController.text);
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(String password) async {
    try {
      setState(() => _isLoading = true);

      if (_user != null) {
        final cred = EmailAuthProvider.credential(
          email: _user!.email!,
          password: password,
        );

        // 🔐 Ré-authentification
        await _user!.reauthenticateWithCredential(cred);

        // 🔄 Supprimer les données Firestore
        await _firestore.collection('users').doc(_user!.uid).delete();

        // ❌ Supprimer le compte Firebase
        await _user!.delete();

        // 🔁 Redirection
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe incorrect.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }



  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Modifier le profil',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildEnergyField(
                      controller: _nameController,
                      icon: Icons.person_outline,
                      label: "Nom complet",
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ce champ est obligatoire';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildEnergyField(
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      label: 'Email',
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ce champ est obligatoire';
                        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildEnergyField(
                      controller: _phoneController,
                      icon: Icons.phone,
                      label: 'Téléphone',
                      validator: (value) => null,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _updateProfile();
                              Navigator.pop(context);
                            }
                          },
                          child: const Text(
                            'Enregistrer',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}