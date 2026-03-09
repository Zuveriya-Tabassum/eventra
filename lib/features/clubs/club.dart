import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/club_model.dart';
import 'club_detail.dart';
import '../../core/presentation/app_drawer.dart';

class ClubHubHomePage extends StatefulWidget {
  const ClubHubHomePage({super.key});

  @override
  State<ClubHubHomePage> createState() => _ClubHubHomePageState();
}

class _ClubHubHomePageState extends State<ClubHubHomePage> {
  final TextEditingController _searchController = TextEditingController();
  String selectedCategory = 'All';
  final ScrollController _scrollController = ScrollController();

  final List<String> categories = [
    'All', 'Tech', 'Service', 'Sports', 'Innovation', 'Personality',
  ];

  final List<Club> clubs = [
    Club(
      name: 'NSS',
      motto: 'Not Me But You',
      developedBy: 'Developed by Team NSS',
      category: 'Service',
      imageUrl: 'assets/images/eventra_logo.png',
      // description: 'The National Service Scheme is an Indian government-sponsored public service program.',
    ),
    Club(
      name: 'NCC',
      motto: 'Unity and Discipline',
      developedBy: 'Developed by Team NCC',
      category: 'Service',
      imageUrl: 'assets/images/eventra_logo.png',
      // description: 'The National Cadet Corps is the youth wing of Armed Forces.',
    ),
    Club(
      name: 'Technical Club',
      motto: 'Innovation through coding',
      developedBy: 'Developed by CSE Dept',
      category: 'Tech',
      imageUrl: 'assets/images/eventra_logo.png',
      // description: 'A hub for tech enthusiasts to build and innovate.',
    ),
  ];

  List<Club> get filteredClubs {
    return clubs.where((club) {
      final matchesCategory = selectedCategory == 'All' || club.category == selectedCategory;
      final matchesSearch = club.name.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Club Hub'),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: filteredClubs.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filteredClubs.length,
                    itemBuilder: (context, index) => _buildClubCard(filteredClubs[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() {}),
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Search for clubs...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = selectedCategory == categories[index];
                return FilterChip(
                  label: Text(categories[index]),
                  selected: isSelected,
                  onSelected: (val) => setState(() => selectedCategory = categories[index]),
                  // backgroundColor: Colors.white24,
                  // selectedColor: Colors.white,
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubCard(Club club) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClubDetailsPage(club: club))),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: club.name,
                child: Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(club.imageUrl, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                club.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  club.category,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                club.motto,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No clubs found',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
