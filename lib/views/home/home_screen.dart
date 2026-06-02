import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:travil/data/model/product_model.dart';
import 'package:travil/data/services/auth_service.dart';
import 'package:travil/viewmodel/map_viewmodel.dart';
import 'package:travil/views/detail/detail_screen.dart';
import 'package:travil/views/home/map_screen.dart';
import 'package:travil/widget/product_card.dart';
import '../../../viewmodel/home_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<HomeViewModel>().loadRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xfff7f4fa),
      body: SafeArea(
        child: vm.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    _buildHeader(vm),
                    const SizedBox(height: 38),
                    // HERO
                    const Text(
                      "Explore\nBeautiful Places",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Discover amazing destinations around you",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // MAP
                    _buildMapPreview(vm),
                    const SizedBox(height: 32),
                    // TOP RATED
                    _buildSectionTitle("Top Rated"),
                    const SizedBox(height: 16),
                    _buildHorizontalList(vm.topRated),
                    const SizedBox(height: 30),
                    // NEARBY
                    _buildSectionTitle("Nearby You"),
                    const SizedBox(height: 16),
                    _buildHorizontalList(vm.nearbyPlaces),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(HomeViewModel vm) {
    return Row(
      children: [
        const CircleAvatar(radius: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Current Location",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: vm.selectedCity,
                  isDense: true,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Da Nang',
                      child: Text('Da Nang'),
                    ),
                    DropdownMenuItem(
                      value: 'Hoi An',
                      child: Text('Hoi An'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      vm.changeCity(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.my_location),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => MapViewModel(),
                  child: const MapScreen(),
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.bookmark_border),
          onPressed: () {},
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().logout();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text("See all"),
        ),
      ],
    );
  }

  Widget _buildHorizontalList(List<ProductModel> list) {
    return SizedBox(
      height: 320,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        itemBuilder: (context, index) {
          final product = list[index];

          return ProductCard(
            product: product,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailScreen(product: product),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMapPreview(HomeViewModel vm) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: vm.currentLocation ??
                const LatLng(
                  16.0471,
                  108.2068,
                ),
            zoom: 13,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          markers: vm.markers,
        ),
      ),
    );
  }
}
