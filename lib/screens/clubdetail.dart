import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'club_model.dart'; // Your Club model
import 'events.dart';    // contains ClubEventListPage(isAdmin,currentUserId)
import 'event_receipt_page.dart';

class ClubSplashScreen extends StatefulWidget {
  final Club club;
  const ClubSplashScreen({super.key, required this.club});

  @override
  State<ClubSplashScreen> createState() => _ClubSplashScreenState();
}

class ClubDetailsPage extends StatefulWidget {
  final Club club;
  const ClubDetailsPage({super.key, required this.club});

  @override
  State<ClubDetailsPage> createState() => _ClubDetailsPageState();
}

class _ClubSplashScreenState extends State<ClubSplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ClubDetailsPage(club: widget.club)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF00BFA5),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Hero(
                  tag: widget.club.imageUrl,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(70),
                      child: Image.network(
                        widget.club.imageUrl,
                        height: 140,
                        width: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Padding(
                      padding: EdgeInsets.only(top: (1 - value) * 20),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  widget.club.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ABOUT BLOCK
class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAboutCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "About Us",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange),
              ),
              SizedBox(height: 12),
              Text(
                "Our club is a dynamic student-driven community focused on innovation, leadership, and hands-on learning.",
                style: TextStyle(fontSize: 16, height: 1.6, color: Colors.black),
              ),
              SizedBox(height: 10),
              Text(
                "By organizing workshops, events, hackathons, and outreach activities, the club bridges academics and industry expectations.",
                style: TextStyle(fontSize: 16, height: 1.6, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// WHY CHOOSE US
class WhyChooseUsWidget extends StatelessWidget {
  final List<String> items;

  const WhyChooseUsWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Why Choose Us?",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 50,
            runSpacing: 20,
            children: items.asMap().entries.map((entry) {
              return WhyPoint(
                index: entry.key,
                text: entry.value,
                icon: _getIcon(entry.key),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(int index) {
    const icons = [
      Icons.rocket_launch,
      Icons.auto_awesome,
      Icons.code,
      Icons.groups,
      Icons.terminal,
      Icons.workspace_premium
    ];
    return icons[index % icons.length];
  }
}

class WhyPoint extends StatelessWidget {
  final String text;
  final IconData icon;
  final int index;

  const WhyPoint({
    super.key,
    required this.text,
    required this.icon,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    double cardWidth =
        (MediaQuery.of(context).size.width - 32 - 40) / 3; // 3 columns

    return Container(
      width: cardWidth,
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.teal : Colors.blue.shade700,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// MAIN DETAILS PAGE
class _ClubDetailsPageState extends State<ClubDetailsPage>
    with TickerProviderStateMixin {
  bool _showNavbar = false;
  late AnimationController _navbarController;
  late Animation<double> _navbarAnimation;
  final ScrollController _scrollController = ScrollController();

  late PageController _eventsPageController;
  int _currentEventIndex = 0;
  Timer? _autoScrollTimer;

  final GlobalKey _teamKey = GlobalKey();
  final GlobalKey _eventsKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  final List<Map<String, dynamic>> eventsData = [
    {
      'title': 'Hackathon 2025',
      'date': 'Feb 15-16, 2025',
      'attendees': '200+ Participants',
      'image':
      'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=400&h=250&fit=crop',
      'description': '24-hour coding challenge',
      'details': 'Winning teams get internships + ₹50K prizes. 50+ companies.',
      'color': Colors.deepOrange,
    },
    {
      'title': 'Flutter Workshop',
      'date': 'Jan 25, 2025',
      'attendees': '150 Attendees',
      'image':
      'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400&h=250&fit=crop',
      'description': 'Build real apps',
      'details': 'Hands-on with Google certified trainers. Certificates.',
      'color': Colors.orange.shade600,
    },
    {
      'title': 'AI/ML Summit',
      'date': 'Mar 10, 2025',
      'attendees': '300+ Participants',
      'image':
      'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=400&h=250&fit=crop',
      'description': 'Latest AI trends',
      'details': 'IIT professors + Google AI experts. Live projects.',
      'color': Colors.orange.shade700,
    },
    {
      'title': 'Cybersecurity Bootcamp',
      'date': 'Apr 5-6, 2025',
      'attendees': '100+ Attendees',
      'image':
      'https://images.unsplash.com/photo-1611593736516-fb350403d30b?w=400&h=250&fit=crop',
      'description': 'Ethical hacking',
      'details': 'CEH certified training with CTF challenges.',
      'color': Colors.orange.shade800,
    },
  ];

  @override
  void initState() {
    super.initState();
    _navbarController =
        AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _navbarAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _navbarController, curve: Curves.easeInOut),
    );
    _eventsPageController = PageController();
    _autoScrollTimer =
        Timer.periodic(const Duration(seconds: 4), (timer) => _nextEvent());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _navbarController.dispose();
    _autoScrollTimer?.cancel();
    _eventsPageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 0) {
      if (!_showNavbar) {
        setState(() => _showNavbar = true);
        _navbarController.forward();
      }
    } else if (_showNavbar) {
      _navbarController.reverse();
      Future.delayed(const Duration(milliseconds: 400),
              () => setState(() => _showNavbar = false));
    }
  }

  void _nextEvent() {
    _currentEventIndex = (_currentEventIndex + 1) % eventsData.length;
    _eventsPageController.animateToPage(
      _currentEventIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.network(widget.club.imageUrl, fit: BoxFit.cover),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          Center(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20).copyWith(bottom: 150),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    Hero(
                      tag: widget.club.imageUrl,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(widget.club.imageUrl,
                            height: 160, width: 160, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.club.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.club.motto,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    _buildInfoCard(context),
                    const SizedBox(height: 40),
                    _buildScrollableSections(),
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _navbarAnimation,
            builder: (context, child) {
              return Positioned(
                bottom: _showNavbar ? 20 + (1 - _navbarAnimation.value) * 80 : -100,
                left: 24 * _navbarAnimation.value,
                right: 24 * _navbarAnimation.value,
                child: Transform.scale(
                  scale: _navbarAnimation.value,
                  child: Opacity(
                    opacity: _navbarAnimation.value,
                    child: Material(
                      elevation: 12 * _navbarAnimation.value,
                      borderRadius:
                      BorderRadius.circular(32 * _navbarAnimation.value),
                      child: _buildNavbar(context),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDetailRow(Icons.label_important, 'Category',
                widget.club.category),
            const Divider(),
            _buildDetailRow(
                Icons.code, 'Developed By', widget.club.developedBy),
            const Divider(),
            _buildDescription(
              'About the Club',
              "The ${widget.club.name} is a dynamic community dedicated to fostering innovation and collaboration. Our mission is to provide students with tools and opportunities.",
            ),
            const Divider(),
            _buildDescription(
              'Our Vision',
              "To be a leading hub of creativity, empowering the next generation of leaders and innovators.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.teal.shade700, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 14, color: Colors.teal.shade800)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900)),
        const SizedBox(height: 8),
        Text(
          desc,
          style: const TextStyle(
              fontSize: 15, height: 1.5, color: Colors.black87),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }

  Widget _buildNavbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.white.withOpacity(0.98),
          Colors.white.withOpacity(0.92)
        ]),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 15))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(context, 'Our Team', Icons.group, Colors.pinkAccent),
          _buildNavItem(context, 'Events', Icons.event, Colors.orange),
          _buildNavItem(context, 'Contact', Icons.contact_mail, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, String title, IconData icon, Color color) {
    return GestureDetector(
      onTapDown: (_) => _scrollToSectionWithEffect(title),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToSectionWithEffect(String sectionName) {
    HapticFeedback.mediumImpact();
    GlobalKey? targetKey;
    switch (sectionName) {
      case 'Our Team':
        targetKey = _teamKey;
        break;
      case 'Events':
        targetKey = _eventsKey;
        break;
      case 'Contact':
        targetKey = _contactKey;
        break;
    }
    final ctx = targetKey?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Widget _buildScrollableSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Explore Our Club",
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 30),
        const _AboutSection(),
        const SizedBox(height: 40),
        _buildTeamSection(),
        const SizedBox(height: 40),
        _buildEventsSection(),
        const SizedBox(height: 40),
        _buildCertificationsSection(),
        const SizedBox(height: 40),
        WhyChooseUsWidget(
          items: const [
            "Hands-on Coding",
            "Industry Mentors",
            "Hackathons",
            "Networking",
            "Open Source",
            "Bootcamps",
          ],
        ),
        const SizedBox(height: 40),
        _buildContactSection(),
      ],
    );
  }

  /// TEAM SECTION
  Widget _buildTeamSection() {
    return Container(
      key: _teamKey,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient:
        LinearGradient(colors: [Colors.white, Colors.grey.shade50]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 20)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.green, Colors.green.shade600]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Our Team',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                    Text('Leadership & Members',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _showMembersDialog(context),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('View All'),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildTeamCard('Priya Sharma', 'President',
                    'CSE-2021-045', Colors.deepPurple, true, 'lib/img/img1.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTeamCard('Amit Patel', 'Vice President',
                    'CSE-2021-078', Colors.orange, true, 'assets/vp.png'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Core Team',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildTeamCard('Dr. Rajesh K.', 'Faculty Advisor', 'Faculty',
                    Colors.indigo, false, 'assets/advisor.png'),
                const SizedBox(width: 12),
                _buildTeamCard('Priyanka M.', 'Tech Lead', 'CSE-2022-089',
                    Colors.pink, false, 'assets/tech_lead.png'),
                const SizedBox(width: 12),
                _buildTeamCard('Vikram R.', 'Events Head', 'ECE-2021-112',
                    Colors.teal, false, 'assets/events_head.png'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(String name, String role, String rollNo, Color color,
      bool isExecutive, String imagePath) {
    return GestureDetector(
      onTap: () =>
          _showMemberDetails(context, name, role, rollNo, imagePath),
      child: Container(
        width: 150,
        padding:
        const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
          Border.all(color: color.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                Border.all(color: color.withOpacity(0.3), width: 2),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(0.1),
                backgroundImage: AssetImage(imagePath),
                onBackgroundImageError: (_, __) => const Icon(Icons.person),
                child: imagePath.isEmpty
                    ? Icon(Icons.person, color: color)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              role.toUpperCase(),
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              rollNo,
              style:
              TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberDetails(
      BuildContext context, String name, String role, String rollNo, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage(imagePath),
                backgroundColor: Colors.green.withOpacity(0.1),
              ),
              const SizedBox(height: 16),
              Text(name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(role,
                  style: const TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const Divider(height: 32),
              _buildDetailRow(Icons.badge, "Roll Number", rollNo),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close'),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showMembersDialog(BuildContext context) {
    final List<Map<String, String>> allMembers = [
      {
        'name': 'Rahul Verma',
        'rollNo': 'CSE-2021-001',
        'role': 'Member',
        'img': 'assets/m1.png'
      },
      {
        'name': 'Anita Desai',
        'rollNo': 'ECE-2022-045',
        'role': 'Member',
        'img': 'assets/m2.png'
      },
      {
        'name': 'Vikram Singh',
        'rollNo': 'IT-2021-089',
        'role': 'Member',
        'img': 'assets/m3.png'
      },
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Club Members',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  itemCount: allMembers.length,
                  separatorBuilder: (context, index) =>
                  const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final m = allMembers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage(m['img']!),
                        onBackgroundImageError: (_, __) =>
                        const Icon(Icons.person),
                      ),
                      title: Text(m['name']!,
                          style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle:
                      Text("${m['role']} • ${m['rollNo']}"),
                      trailing: const Icon(Icons.chevron_right,
                          color: Colors.green),
                      onTap: () {
                        Navigator.pop(context);
                        _showMemberDetails(context, m['name']!, m['role']!,
                            m['rollNo']!, m['img']!);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// CERTIFICATIONS SECTION
  Widget _buildCertificationsSection() {
    final certifications = [
      {
        "title": "ISO Certified",
        "issuer": "Int. Org",
        "year": "2025",
        "image": "https://img.icons8.com/color/96/certificate.png"
      },
      {
        "title": "Innovation Award",
        "issuer": "Tech Fest",
        "year": "2025",
        "image": "https://img.icons8.com/color/96/trophy.png"
      },
      {
        "title": "Community Service",
        "issuer": "Local NGO",
        "year": "2024",
        "image": "https://img.icons8.com/color/96/medal.png"
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Certifications",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: certifications.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final cert = certifications[index];
                return _CertificationCard(
                  width: 150,
                  title: cert["title"]!,
                  issuer: cert["issuer"]!,
                  year: cert["year"]!,
                  imageUrl: cert["image"]!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// EVENTS SECTION
  Widget _buildEventsSection() {
    return Container(
      key: _eventsKey,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.orange.shade50],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange, Colors.orange.shade700],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child:
                    const Icon(Icons.event, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Events',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        '${_currentEventIndex + 1}/${eventsData.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClubEventListPage(
                        isAdmin: false,
                        currentUserId: 'participant', // plug auth id
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'View More',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _eventsPageController,
                  onPageChanged: (index) {
                    setState(() => _currentEventIndex = index);
                  },
                  itemCount: eventsData.length,
                  itemBuilder: (context, index) {
                    return _buildEventImageCard(
                      event: eventsData[index],
                    );
                  },
                ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      eventsData.length,
                          (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin:
                        const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentEventIndex == index ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentEventIndex == index
                              ? Colors.orange
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventImageCard({required Map<String, dynamic> event}) {
    final Color color = event['color'] ?? Colors.orange;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              event['image'] ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: color.withOpacity(0.4),
                child: const Icon(
                  Icons.event,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Text(
                event['title'] ?? 'Event Name',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// CONTACT SECTION
  Widget _buildContactSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          key: _contactKey,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 120),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 25,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.contact_mail_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Get In Touch',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              isMobile
                  ? Column(
                children: [
                  _buildContactRow(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: 'contact@clubhub.edu',
                  ),
                  const SizedBox(height: 20),
                  _buildContactRow(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    value: '+91 98765 43210',
                  ),
                ],
              )
                  : Row(
                children: [
                  Expanded(
                    child: _buildContactRow(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: 'contact@clubhub.edu',
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildContactRow(
                      icon: Icons.phone_outlined,
                      title: 'Phone',
                      value: '+91 98765 43210',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.tealAccent.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.tealAccent,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CertificationCard extends StatelessWidget {
  final String title, issuer, year, imageUrl;
  final double? width;

  const _CertificationCard({
    super.key,
    required this.title,
    required this.issuer,
    required this.year,
    required this.imageUrl,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.teal.shade300, Colors.teal.shade500]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(imageUrl, height: 60, width: 60),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(issuer,
              style:
              const TextStyle(fontSize: 11, color: Colors.white70),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(year,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
