import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travil/data/model/product_model.dart';
import 'package:travil/data/services/auth_service.dart';
import 'package:travil/viewmodel/map_viewmodel.dart';
import 'package:travil/viewmodel/willgo_viewmodel.dart';
import 'package:travil/views/detail/detail_screen.dart';
import 'package:travil/views/home/map_screen.dart';
import 'package:travil/views/home/willgo_screen.dart';
import 'package:travil/widget/product_card.dart';
import 'package:travil/widget/search_box.dart';
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
      context.read<HomeViewModel>().loadData();
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
                    // SEARCH
                    SearchBox(vm: vm),
                    const SizedBox(height: 32), // HERO
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

                    // TOP RATED
                    _buildSectionTitle("Top Rated"),
                    const SizedBox(height: 16),
                    _buildHorizontalList(vm.topRated),
                    const SizedBox(height: 30),
                    // NEARBY
                    _buildSectionTitle("Nearby You"),
                    const SizedBox(height: 16),
                    _buildHorizontalList(vm.recommendations),
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
        // LOCATION
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
              const SizedBox(height: 4),
              DropdownButton<String>(
                isExpanded: true,
                value: vm.selectedCity,
                hint: const Text(
                  "Select location",
                ),
                items: vm.locations.map((location) {
                  return DropdownMenuItem<String>(
                    value: location,
                    child: Text(
                      location,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) async {
                  if (value != null) {
                    await vm.changeCity(value);
                  }
                },
              )
            ],
          ),
        ),

        const SizedBox(width: 8),
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => WillGoViewModel(),
                  child: const WillGoScreen(),
                ),
              ),
            );
          },
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
        // TextButton(
        //   onPressed: () {},
        //   child: const Text("See all"),
        // ),
      ],
    );
  }

  Widget _buildHorizontalList(List<ProductModel> list) {
    if (list.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.place_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              "This city does not yet feature curated tourist experiences.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              "Try selecting a different city.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
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
}
