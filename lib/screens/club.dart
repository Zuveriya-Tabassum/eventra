import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'clubdetail.dart';
import 'club_model.dart';
import 'home.dart';

/// 🔹 Gradient Text Widget
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;

  const GradientText(
    this.text, {
    super.key,
    required this.style,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

/// 🔹 Home Page
class ClubHubHomePage extends StatefulWidget {
  const ClubHubHomePage({super.key});

  @override
  State<ClubHubHomePage> createState() => _ClubHubHomePageState();
}

class _ClubHubHomePageState extends State<ClubHubHomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String selectedCategory = 'All';
  final ScrollController _scrollController = ScrollController();
  int _hoveredIndex = -1;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<String> categories = [
    'All',
    'Tech',
    'Service',
    'Sports',
    'Innovation',
    'Personality',
  ];

  final List<Club> clubs = [
    // 🔹 SERVICE CLUBS
    Club(
      name: 'NSS',
      motto: 'Not Me But You',
      developedBy: 'Developed by Team NSS',
      category: 'Service',
      imageUrl:
          'assets/images/eventra_logo.png', // Community service hands
    ),
    Club(
      name: 'NCC',
      motto: 'Unity and Discipline',
      developedBy: 'Developed by NCC Cadets',
      category: 'Service',
      imageUrl:
          'assets/images/eventra_logo.png', // Military badge
    ),

    // 🔹 TECH CLUBS
    Club(
      name: 'Infomac',
      motto: 'Tech for All',
      developedBy: 'Developed by Infomac Team',
      category: 'Tech',
      imageUrl:
          'assets/images/eventra_logo.png', // Code laptop
    ),
    Club(
      name: 'IEEE',
      motto: 'Engineering Excellence',
      developedBy: 'Developed by IEEE Chapter',
      category: 'Tech',
      imageUrl:
          'assets/images/eventra_logo.png', // Circuit board
    ),

    // 🔹 SPORTS CLUBS
    Club(
      name: 'Sports Club',
      motto: 'Play. Compete. Win.',
      developedBy: 'Developed by Sports Committee',
      category: 'Sports',
      imageUrl:
          'assets/images/eventra_logo.png', // Sports trophy
    ),

    // 🔹 INNOVATION CLUBS
    Club(
      name: 'Spark',
      motto: 'Igniting Ideas',
      developedBy: 'Developed by Spark Innovators',
      category: 'Innovation',
      imageUrl:
          'assets/images/eventra_logo.png', // Lightbulb innovation
    ),
    Club(
      name: 'E-Cell',
      motto: 'Empowering Entrepreneurs',
      developedBy: 'Developed by E-Cell Team',
      category: 'Innovation',
      imageUrl:
          'assets/images/eventra_logo.png',
    ),
    // 🔹 PERSONALITY DEVELOPMENT
    Club(
      name: 'Jeevan Koushal',
      motto: 'Life Skills for All',
      developedBy: 'Developed by Personality Team',
      category: 'Personality',
      imageUrl:
          'assets/images/eventra_logo.png', // Brain skills
    ),
    Club(
      name: 'Innovation Club',
      motto: 'Think. Create. Innovate.',
      developedBy: 'Developed by Innovation Hub',
      imageUrl:
          'assets/images/eventra_logo.png',
      category: 'Innovation',
    ),
    Club(
      name: 'CSI',
      motto: 'Advancing Computing as a Science & Profession',
      developedBy: 'Developed by CSI Student Branch',
      category: 'Tech',
      imageUrl:
          'assets/images/eventra_logo.png', // Official CSI-style circuit logo [web:11]
    ),
  ];

  List<Club> get filteredClubs {
    String query = _searchController.text.toLowerCase();
    return clubs.where((club) {
      final matchesCategory =
          selectedCategory == 'All' || club.category == selectedCategory;
      final matchesSearch =
          club.name.toLowerCase().contains(query) ||
          club.motto.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 250,
      duration: const Duration(milliseconds: 400),
      curve: Curves.ease,
    );
  }

  void scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 250,
      duration: const Duration(milliseconds: 400),
      curve: Curves.ease,
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: Stack(
        children: [
          // ✅ RESPONSIVE BACKGROUND with overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/bg_img.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 32,
                vertical: 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomeScreen(
                            onToggleTheme:
                                () {}, // replace later with real callback
                            isDark: false, // replace with real theme value
                          ),
                        ),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GradientText(
                        "Club Hub",
                        style: GoogleFonts.montserrat(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.yellowAccent,
                            Colors.pink,
                            Colors.orange,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => setState(() {}),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              onChanged: (value) =>
                                  setState(() => selectedCategory = value!),
                              underline: const SizedBox(),
                              items: categories.map((cat) {
                                return DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: isMobile ? 140 : 200,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: 'Search',
                                border: InputBorder.none,
                                icon: Icon(Icons.search),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: const [
                        Text(
                          '"Explore. Learn. Lead."',
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.pinkAccent,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '"Where Passion Meets Purpose"',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: const Text(
                            "Clubs are established with the vision of excellence in education, "
                            "build life skills, and lead with purpose which promotes student engagement, innovation, and leadership.",
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 70),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: scrollLeft,
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 260,
                          child: ListView.builder(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: filteredClubs.length,
                            itemBuilder: (context, index) {
                              final club = filteredClubs[index];
                              return MouseRegion(
                                onEnter: (_) =>
                                    setState(() => _hoveredIndex = index),
                                onExit: (_) =>
                                    setState(() => _hoveredIndex = -1),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  transform: (_hoveredIndex == index)
                                      ? (Matrix4.identity()..scale(1.05))
                                      : Matrix4.identity(),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  width: isMobile
                                      ? screenWidth * 0.65
                                      : screenWidth * 0.25,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: _hoveredIndex == index
                                            ? 10
                                            : 6,
                                        offset: const Offset(2, 3),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        PhotoHero(
                                          photo: club.imageUrl,
                                          width: 60,
                                          onTap: () {},
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          club.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          club.motto,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          club.developedBy,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                transitionDuration:
                                                    const Duration(
                                                      milliseconds: 500,
                                                    ),
                                                pageBuilder: (_, __, ___) =>
                                                    ClubSplashScreen(
                                                      club: club,
                                                    ),
                                                transitionsBuilder:
                                                    (_, animation, __, child) {
                                                      return FadeTransition(
                                                        opacity: animation,
                                                        child: child,
                                                      );
                                                    },
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            "View More",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                        ),
                        onPressed: scrollRight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔹 Hero widget
class PhotoHero extends StatelessWidget {
  const PhotoHero({
    super.key,
    required this.photo,
    this.onTap,
    required this.width,
  });
  final String photo;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Hero(
        tag: photo,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Image.asset(photo, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
