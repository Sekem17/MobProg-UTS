import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:medsos/storage/post_storage.dart';
import 'package:medsos/fitur/fitur_edit_profile.dart';
import 'package:medsos/pages/login_page.dart';
import 'dart:io';
import 'package:medsos/widget/avatar_widget.dart';

class ProfilePage extends StatefulWidget {
  final String targetUsername;

  const ProfilePage({super.key, required this.targetUsername});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _profileName = "Memuat...";
  String _profileUsername = "@memuat";
  String _joinedDate = "Memuat Tanggal...";
  int _followingCount = 0;
  int _followersCount = 0;
  int _postCount = 0;
  bool _isCurrentUser = false;
  String _profileBannerUrl = '';
  List<Map<String, dynamic>> _userPosts = [];
  List<Map<String, dynamic>> _userReplies = [];
  List<Map<String, dynamic>> _userLikes = [];
  List<Map<String, dynamic>> _userShares = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }
  
  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetUsername != oldWidget.targetUsername) {
      _loadAllData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          currentUsername: _profileUsername.substring(1), 
          currentName: _profileName,
        ),
      ),
    );

    if (result == true) {
      _loadAllData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('current_user');

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _loadAllData() async {
    await _loadProfileData();
    await _loadPostData();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentLoggedInUser = prefs.getString('current_user') ?? 'guest';

    final targetUserWithoutAt = widget.targetUsername.startsWith('@')
        ? widget.targetUsername.substring(1)
        : widget.targetUsername;

    final bannerUrl = prefs.getString('banner_url_$targetUserWithoutAt');
    final name =
        prefs.getString('name_$targetUserWithoutAt') ?? 'Nama Pengguna';

    final List<String> userFollowingList =
        prefs.getStringList('user_following_list_$targetUserWithoutAt') ?? [];
    
    int tempFollowersCount = 0;
    final allKeys = prefs.getKeys();
    for (var key in allKeys) {
      if (key.startsWith('user_following_list_')) {
        final List<String> followerList = prefs.getStringList(key) ?? [];
        if (followerList.contains(targetUserWithoutAt)) {
          tempFollowersCount++;
        }
      }
    }

    final registeredTimestamp = prefs.getString(
      'registered_date_$targetUserWithoutAt',
    );
    String formattedJoinedDate = "Joined N/A";
    if (registeredTimestamp != null) {
      try {
        final dateTime = DateTime.parse(registeredTimestamp);
        formattedJoinedDate =
            "Joined ${DateFormat('MMMM yyyy').format(dateTime)}";
      } catch (e) {
        formattedJoinedDate = "Joined N/A";
      }
    } else {
      formattedJoinedDate =
          "Joined ${DateFormat('MMMM yyyy').format(DateTime.now())}";
    }

    setState(() {
      _isCurrentUser = (widget.targetUsername == "@$currentLoggedInUser");
      _profileName = name;
      _profileUsername = widget.targetUsername;
      _followingCount = userFollowingList.length;
      _followersCount = tempFollowersCount;
      _joinedDate = formattedJoinedDate;
      _profileBannerUrl = bannerUrl ?? '';
    });
  }

  Future<void> _loadPostData() async {
    final allPosts = await PostStorage.loadPosts();
    final targetUser = widget.targetUsername;
    final targetUserWithoutAt = targetUser.substring(1);

    final posts = allPosts.where((p) => p['username'] == targetUser).toList();
    final replies = allPosts.where((p) {
      final comments = List<Map<String, dynamic>>.from(
        p['comments_list'] ?? [],
      );
      return comments.any(
        (c) =>
            c['username'] == targetUser &&
            c.containsKey('reply_to_user') &&
            c['reply_to_user'] != null &&
            c['reply_to_user']!.isNotEmpty,
      );
    }).toList();
    final likes = allPosts.where((p) {
      final likedBy = List<String>.from(p['liked_by'] ?? []);
      return likedBy.contains(targetUserWithoutAt);
    }).toList();
    final shares = allPosts.where((p) {
      final sharedBy = List<String>.from(p['shared_by'] ?? []);
      return sharedBy.contains(targetUserWithoutAt);
    }).toList();

    setState(() {
      _userPosts = posts;
      _userReplies = replies;
      _userLikes = likes;
      _userShares = shares;
      _postCount = _userPosts.length;
    });
  }

  Widget _buildPostList(List<Map<String, dynamic>> posts, String emptyMessage) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            emptyMessage,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      primary: false,
      shrinkWrap: true,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final postUserWithoutAt = (post['username'] as String).substring(1);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            leading: UserAvatar(username: postUserWithoutAt, radius: 20),
            title: Text(
              post['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['username'] ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  (post['title']!.isNotEmpty ? post['title']! + '\n' : '') +
                      (post['content'] ?? 'No Content'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (posts == _userShares)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text(
                      'REPOSTED',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bannerWidget;
    if (_profileBannerUrl.isNotEmpty && File(_profileBannerUrl).existsSync()) {
      bannerWidget = Image.file(
        File(_profileBannerUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade800,
          alignment: Alignment.center,
          child: const Text(
            'Banner Hilang/Rusak',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } else {
      bannerWidget = Container(color: Colors.deepPurple.shade700);
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              centerTitle: true,
              title: AnimatedOpacity(
                opacity: innerBoxIsScrolled ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    Text(_profileName, style: const TextStyle(fontSize: 18)),
                    Text(
                      '$_postCount posts',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    bannerWidget,
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: UserAvatar(
                        username: widget.targetUsername.substring(1),
                        radius: 40,
                        isProfilePage: true,
                      ),
                    ),

                    Positioned(
                      bottom: 20,
                      right: 16,
                      child: _isCurrentUser
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  onPressed: _logout,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    "Logout",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                OutlinedButton(
                                  onPressed: _navigateToEditProfile,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    "Edit profile",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            )
                          : ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Follow/Unfollow clicked!"),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text("Follow"),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          _profileName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.verified,
                          color: Colors.blue.shade600,
                          size: 22,
                        ),
                      ],
                    ),
                    Text(
                      _profileUsername,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _joinedDate,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '$_followingCount Following',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$_followersCount Followers',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Theme.of(context).textTheme.titleMedium?.color,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: const [
                    Tab(text: "Posts"),
                    Tab(text: "Replies"),
                    Tab(text: "Shares"),
                    Tab(text: "Likes"),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostList(_userPosts, "Tidak ada postingan."),
            _buildPostList(_userReplies, "Tidak ada balasan yang dibuat."),
            _buildPostList(_userShares, "Belum ada postingan yang di-repost."),
            _buildPostList(_userLikes, "Tidak ada postingan yang disukai."),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}