import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:medsos/storage/post_storage.dart'; 
import 'package:medsos/fitur/fitur_edit_profile.dart'; 

class ProfilePage extends StatefulWidget {
  final String targetUsername;

  const ProfilePage({super.key, required this.targetUsername});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Data Profil
  String _profileName = "Memuat...";
  String _profileUsername = "@memuat";
  String _profileAvatarChar = "U";
  String _joinedDate = "Memuat Tanggal...";
  int _followingCount = 0;
  int _followersCount = 0;
  int _postCount = 0;
  bool _isCurrentUser = false;

  // Data Post yang Tersinkronisasi
  List<Map<String, dynamic>> _userPosts = [];
  List<Map<String, dynamic>> _userReplies = [];
  List<Map<String, dynamic>> _userLikes = [];
  List<Map<String, dynamic>> _userShares = [];
  
  bool _isLoading = true;
  String _profileBannerUrl = ''; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); 
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // --- Navigasi & Reload ---

  // FUNGSI BARU: Navigasi ke Edit Profile dan Muat Ulang Data
  void _navigateToEditProfile() async {
      final result = await Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => EditProfilePage(
                  // Pastikan Anda mengirim username tanpa '@' ke halaman edit
                  currentUsername: _profileUsername.substring(1), 
                  currentName: _profileName,
              ),
          ),
      );

      // Jika kembali dengan hasil 'true', muat ulang data
      if (result == true) {
          _loadAllData(); 
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Profil berhasil diperbarui.')),
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

  // --- Logika Pemuatan Data ---

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentLoggedInUser = prefs.getString('current_user') ?? 'guest';

    final targetUserWithoutAt = widget.targetUsername.startsWith('@') 
                               ? widget.targetUsername.substring(1) 
                               : widget.targetUsername;
    
    // Muat URL Banner dari SharedPreferences
    final bannerUrl = prefs.getString('banner_url_$targetUserWithoutAt');

    final name = prefs.getString('name_$targetUserWithoutAt') ?? 'Nama Pengguna';
    
    final List<String> userFollowingList = prefs.getStringList('user_following_list_$targetUserWithoutAt') ?? [];
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

    final registeredTimestamp = prefs.getString('registered_date_$targetUserWithoutAt');
    String formattedJoinedDate = "Joined N/A";
    if (registeredTimestamp != null) {
      try {
        final dateTime = DateTime.parse(registeredTimestamp);
        formattedJoinedDate = "Joined ${DateFormat('MMMM yyyy').format(dateTime)}";
      } catch (e) {
        formattedJoinedDate = "Joined N/A";
      }
    } else {
        formattedJoinedDate = "Joined ${DateFormat('MMMM yyyy').format(DateTime.now())}";
    }

    setState(() {
      _isCurrentUser = (widget.targetUsername == "@$currentLoggedInUser");
      _profileName = name;
      _profileUsername = widget.targetUsername;
      _profileAvatarChar = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
      _followingCount = userFollowingList.length;
      _followersCount = tempFollowersCount;
      _joinedDate = formattedJoinedDate;
      _profileBannerUrl = bannerUrl ?? ''; // Set banner URL
    });
  }
  
  Future<void> _loadPostData() async {
    final allPosts = await PostStorage.loadPosts();
    final targetUser = widget.targetUsername; 
    final targetUserWithoutAt = targetUser.substring(1);

    final posts = allPosts.where((p) => p['username'] == targetUser).toList();

    final replies = allPosts.where((p) {
        final comments = List<Map<String, dynamic>>.from(p['comments_list'] ?? []);
        return comments.any((c) => 
            c['username'] == targetUser && 
            c.containsKey('reply_to_user') && 
            c['reply_to_user'] != null && 
            c['reply_to_user']!.isNotEmpty
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
  
  // Helper Widget untuk menampilkan daftar post di setiap tab
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
    
    // Placeholder Post Tile
    return ListView.builder(
      primary: false, 
      shrinkWrap: true,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            leading: CircleAvatar(child: Text(post['name']![0])),
            title: Text(post['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post['username'] ?? '', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  (post['title']!.isNotEmpty ? post['title']! + '\n' : '') + (post['content'] ?? 'No Content'), 
                  maxLines: 3, 
                  overflow: TextOverflow.ellipsis,
                ),
                if (posts == _userShares) 
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text('REPOSTED', style: TextStyle(color: Colors.green, fontSize: 12)),
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
                    // Area banner (Background Ungu atau Gambar dari SharedPreferences)
                    Container(
                      color: Colors.deepPurple.shade700,
                      child: _profileBannerUrl.isNotEmpty
                          ? Image.network(
                              'https://via.placeholder.com/600x150/9370DB/FFFFFF?text=Custom+Banner',
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    
                    // Avatar & Tombol di bagian bawah banner
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.pink.shade300,
                        child: Text(
                          _profileAvatarChar,
                          style: const TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      right: 16,
                      child: _isCurrentUser 
                        ? OutlinedButton(
                            onPressed: _navigateToEditProfile, // <<< NAVIGASI KE EDIT PROFILE
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text("Edit profile", style: TextStyle(color: Colors.white)),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Follow/Unfollow clicked!")),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                        // CENTANG BIRU MODERN
                        Icon(Icons.verified, color: Colors.blue.shade600, size: 22),
                      ],
                    ),
                    Text(
                      _profileUsername,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(_joinedDate, style: const TextStyle(color: Colors.grey)),
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
                  labelColor: Colors.deepPurple,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.deepPurple,
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

// Delegate untuk membuat TabBar tetap "pinned" di bawah SliverAppBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
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