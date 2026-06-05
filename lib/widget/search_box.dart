import 'package:flutter/material.dart';
import 'package:travil/viewmodel/home_viewmodel.dart';
import 'package:travil/views/detail/detail_screen.dart';

class SearchBox extends StatelessWidget {
  const SearchBox({super.key, required this.vm});
  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return
        // Widget _buildSearchBox(
        Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: TextField(
            onChanged: (value) async {
              await vm.searchProducts(
                value,
              );
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Search place or location...",
              icon: const Icon(
                Icons.search,
              ),
              suffixIcon: vm.searchResults.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                      ),
                      onPressed: () {
                        vm.clearSearch();
                      },
                    )
                  : null,
            ),
          ),
        ),

        // SEARCH RESULT BOX

        if (vm.searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(
              top: 12,
            ),
            constraints: const BoxConstraints(
              maxHeight: 350,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                20,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: vm.searchResults.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
              ),
              itemBuilder: (
                context,
                index,
              ) {
                final product = vm.searchResults[index];

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                    child: Image.network(
                      product.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Expanded(
                        child: Text(
                          product.location,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    vm.clearSearch();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(
                          product: product,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
