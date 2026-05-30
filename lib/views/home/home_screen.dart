import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travil/views/detail/detail_screen.dart';
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
    Future.microtask(() => context.read<HomeViewModel>().loadRecommendations());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: vm.selectedCity,
                      isExpanded: true,
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
                      onChanged: (value) => vm.changeCity(value!),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: () => vm.loadRecommendations(useGPS: true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () {},
                  ),
                  IconButton(icon: const Icon(Icons.logout), onPressed: () {}),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "Recommended For You",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child:
                    vm.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: vm.recommendations.length,
                          itemBuilder: (context, index) {
                            final product = vm.recommendations[index];
                            return ProductCard(
                              product: product,
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => DetailScreen(product: product),
                                    ),
                                  ),
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
}
