import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class EditProfilePage extends StatefulWidget {
  final String currentUsername;
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _profileBannerPath = '';
  File? _pickedBannerFile;

  String _profileAvatarPath = '';
  File? _pickedAvatarFile;

  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _usernameController.text = widget.currentUsername;
    _loadExistingProfileImages();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfileImages() async {
    final prefs = await SharedPreferences.getInstance();
    final usernameKey = widget.currentUsername;

    final bannerPath = prefs.getString('banner_url_$usernameKey') ?? '';
    final avatarPath = prefs.getString('avatar_url_$usernameKey') ?? '';

    if (!mounted) return;

    setState(() {
      _profileBannerPath = bannerPath;
      _pickedBannerFile =
          (bannerPath.isNotEmpty && File(bannerPath).existsSync())
          ? File(bannerPath)
          : null;

      _profileAvatarPath = avatarPath;
      _pickedAvatarFile =
          (avatarPath.isNotEmpty && File(avatarPath).existsSync())
          ? File(avatarPath)
          : null;
    });
  }

  void _importBannerImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(image.path);
        final uniqueFileName =
            'banner_${DateTime.now().millisecondsSinceEpoch}_$fileName';
        final savedImage = File(p.join(appDir.path, uniqueFileName));
        final File permanentFile = await File(image.path).copy(savedImage.path);

        setState(() {
          _profileBannerPath = permanentFile.path;
          _pickedBannerFile = permanentFile;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banner berhasil dipilih dan disimpan.'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat atau menyimpan banner: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pemilihan banner dibatalkan.')),
      );
    }
  }

  void _importAvatarImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxHeight: 400,
      maxWidth: 400,
    );
    if (image != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(image.path);
        final uniqueFileName =
            'avatar_${DateTime.now().millisecondsSinceEpoch}_$fileName';
        final savedImage = File(p.join(appDir.path, uniqueFileName));
        final File permanentFile = await File(image.path).copy(savedImage.path);

        if (!mounted) return;
        setState(() {
          _profileAvatarPath = permanentFile.path;
          _pickedAvatarFile = permanentFile;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar berhasil dipilih dan disimpan.'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat atau menyimpan avatar: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pemilihan avatar dibatalkan.')),
      );
    }
  }

  String _cleanUsername(String username) {
    final cleaned = username.trim();
    return cleaned.startsWith('@') ? cleaned.substring(1) : cleaned;
  }

  Future<void> _moveUserData(
    SharedPreferences prefs,
    String oldUsername,
    String newUsername,
  ) async {
    if (oldUsername == newUsername) return; 

    final keysToMove = [
      'user', 
      'name', 
      'banner_url', 
      'avatar_url', 
      'registered_date',
      'user_following_list', 
      'notif_list',
      'last_registered_user', 
    ];

    for (var key in keysToMove) {
      final oldKey = '${key}_$oldUsername';
      final newKey = '${key}_$newUsername';
      
      final value = prefs.get(oldKey);

      if (value != null) {
        await prefs.remove(oldKey);
        
        if (value is String) {
          await prefs.setString(newKey, value);
        } else if (value is bool) {
          await prefs.setBool(newKey, value);
        } else if (value is int) {
          await prefs.setInt(newKey, value);
        } else if (value is double) {
          await prefs.setDouble(newKey, value);
        } else if (value is List<String>) {
          await prefs.setStringList(newKey, value);
        }
      }
    }
    
    await prefs.setString('current_user', newUsername);
    await prefs.setString('last_registered_user', newUsername);
  }

  void _saveProfile() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    
    final newName = _nameController.text.trim();
    final newUsernameInput = _usernameController.text.trim();
    
    final oldUsername = widget.currentUsername;
    final newUsername = _cleanUsername(newUsernameInput); 

    if (newName.isEmpty || newUsername.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama dan Username tidak boleh kosong.')));
      return;
    }
    if (newUsername.contains('@') || newUsername.contains(' ')) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username tidak boleh mengandung "@" atau spasi.')),
        );
        return;
    }


    setState(() {
      _isSaving = true;
    });

    final prefs = await SharedPreferences.getInstance();

    if (newUsername != oldUsername) {
      final isUsernameTaken = prefs.containsKey('user_$newUsername');
      if (isUsernameTaken) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username sudah digunakan oleh akun lain.')),
        );
        return;
      }

      await _moveUserData(prefs, oldUsername, newUsername);

    }
    
    final usernameKey = newUsername; 
    await prefs.setString('name_$usernameKey', newName);
    await prefs.setString('banner_url_$usernameKey', _profileBannerPath);
    await prefs.setString('avatar_url_$usernameKey', _profileAvatarPath);

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      Navigator.of(context).pop(true); 
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bannerContent;
    if (_pickedBannerFile != null && _pickedBannerFile!.existsSync()) {
      bannerContent = Image.file(
        _pickedBannerFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade800,
          alignment: Alignment.center,
          child: const Text(
            'File Tidak Ditemukan/Invalid',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } else {
      bannerContent = Container(
        color: Colors.deepPurple.shade700,
        alignment: Alignment.center,
        child: const Text(
          'Tap ikon untuk Pilih Banner',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    Widget avatarContent;
    if (_pickedAvatarFile != null && _pickedAvatarFile!.existsSync()) {
      avatarContent = Image.file(_pickedAvatarFile!, fit: BoxFit.cover);
    } else {
      avatarContent = Container(
        color: Colors.transparent,
        child: const Icon(Icons.photo_camera, size: 40, color: Colors.white),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ],
        backgroundColor: Colors.deepPurple,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: bannerContent,
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                          ),
                          iconSize: 40,
                          onPressed: _importBannerImage,
                          tooltip: 'Ubah Gambar Latar Belakang',
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: 16,
                    child: GestureDetector(
                      onTap: _importAvatarImage,
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.pink.shade300,
                        child: ClipOval(
                          child: SizedBox(
                            width: 70,
                            height: 70,
                            child: avatarContent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              TextFormField(
                controller: _nameController,
                validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong.' : null,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _usernameController,
                validator: (value) {
                   if (value == null || value.isEmpty) return 'Username tidak boleh kosong.';
                   if (value.contains(RegExp(r'\s')) || value.contains('@')) return 'Username tidak boleh mengandung spasi atau "@".';
                   return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.alternate_email),
                  prefixText: '@',
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
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
      ),
    );
  }
}