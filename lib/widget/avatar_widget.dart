import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class UserAvatar extends StatefulWidget {
  final String username;
  final double radius;
  final bool isProfilePage;

  const UserAvatar({
    required this.username,
    this.radius = 20.0,
    this.isProfilePage = false,
    super.key,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String _avatarPath = '';
  String _nameInitial = 'U';
  Color _backgroundColor = Colors.pink.shade300;

  @override
  void initState() {
    super.initState();
    _loadAvatarData();
  }

  @override
  void didUpdateWidget(covariant UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username) {
      _loadAvatarData();
    }
  }

  Future<void> _loadAvatarData() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('avatar_url_${widget.username}') ?? '';
    final name = prefs.getString('name_${widget.username}') ?? '';

    setState(() {
      _avatarPath = path;
      _nameInitial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    final size = widget.radius * 2;

    if (_avatarPath.isNotEmpty && File(_avatarPath).existsSync()) {
      content = Image.file(
        File(_avatarPath),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) => Text(
          _nameInitial,
          style: TextStyle(fontSize: widget.radius, color: Colors.white),
        ),
      );
    } else {
      content = Text(
        _nameInitial,
        style: TextStyle(
          fontSize: widget.radius * (widget.isProfilePage ? 0.9 : 1.0),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: _backgroundColor,
      child: ClipOval(child: content),
    );
  }
}
