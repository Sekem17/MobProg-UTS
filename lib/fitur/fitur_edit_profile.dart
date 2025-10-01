// edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // Import the picker package
import 'dart:io'; // Required for File object

class EditProfilePage extends StatefulWidget {
  final String currentUsername; // Username tanpa '@'
  final String currentName;

  const EditProfilePage({
    required this.currentUsername,
    required this.currentName,
    super.key,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  
  // Stores the persistent path/URL string
  String _profileBannerPath = ''; 
  
  // Stores the File object for immediate preview
  File? _pickedBannerFile; 
  
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker(); // Initialize ImagePicker

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _usernameController.text = widget.currentUsername;
    _loadExistingBanner();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // Muat path banner yang sudah ada
  Future<void> _loadExistingBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final bannerPath = prefs.getString('banner_url_${widget.currentUsername}') ?? '';
    setState(() {
      _profileBannerPath = bannerPath;
      _pickedBannerFile = bannerPath.isNotEmpty ? File(bannerPath) : null;
    });
  }

  // FUNGSI NYATA: Import Gambar Banner Lokal
  void _importBannerImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        // Simpan path file untuk persistensi
        _profileBannerPath = image.path; 
        // Simpan File object untuk preview segera
        _pickedBannerFile = File(image.path); 
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gambar berhasil dipilih dari: ${image.name}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pemilihan gambar dibatalkan.')),
      );
    }
  }

  // FUNGSI UTAMA: Menyimpan Perubahan Profil
  void _saveProfile() async {
    if (_isSaving) return;

    final newName = _nameController.text.trim();
    final newUsername = _usernameController.text.trim();
    
    if (newName.isEmpty || newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan Username tidak boleh kosong.')),
      );
      return;
    }

    setState(() { _isSaving = true; });

    final prefs = await SharedPreferences.getInstance();
    final oldUsernameKey = widget.currentUsername;
    
    // 1. Simpan Nama Baru
    await prefs.setString('name_$oldUsernameKey', newName);

    // 2. Simpan Path Banner Baru
    await prefs.setString('banner_url_$oldUsernameKey', _profileBannerPath);

    // 3. (Username change logic remains complex and disabled)
    if (newUsername != oldUsernameKey) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perubahan username dinonaktifkan.')),
        );
    }
    
    setState(() { _isSaving = false; });
    
    // Kembali ke halaman profil dan kirim sinyal update (true)
    if (mounted) {
      Navigator.of(context).pop(true); 
    }
  }


  @override
  Widget build(BuildContext context) {
    final usernameWithoutAt = widget.currentUsername;
    
    // Tentukan sumber gambar untuk preview
    DecorationImage? bannerImage;
    if (_pickedBannerFile != null) {
      bannerImage = DecorationImage(
        image: FileImage(_pickedBannerFile!),
        fit: BoxFit.cover,
      );
    } else if (_profileBannerPath.isNotEmpty) {
      // Fallback: Jika path tersimpan tapi file belum dimuat (misalnya setelah restart)
      bannerImage = DecorationImage(
        image: FileImage(File(_profileBannerPath)),
        fit: BoxFit.cover,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Banner dan Tombol Import
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Banner Preview Area
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade700,
                    image: bannerImage, // Menggunakan sumber gambar dinamis
                  ),
                ),
                
                // Tombol Ubah Banner Overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      color: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.photo_library, color: Colors.white),
                        iconSize: 40,
                        onPressed: _importBannerImage, // Panggil fungsi picker nyata
                        tooltip: 'Ubah Gambar Latar Belakang',
                      ),
                    ),
                  ),
                ),
                
                // Avatar Preview
                Positioned(
                  bottom: -30,
                  left: 16,
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.pink.shade300,
                    child: Text(_nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 30, color: Colors.white)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 50), 
            
            // Input Nama
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),
            
            // Input Username
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.alternate_email),
                prefixText: '@',
                enabled: false, // Tetap nonaktifkan edit username
                hintText: usernameWithoutAt,
              ),
            ),
            
            const SizedBox(height: 30),
            
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }
}