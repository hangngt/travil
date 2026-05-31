import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travil/widget/product_card.dart';
import '../../viewmodel/willgo_viewmodel.dart';
import '../detail/detail_screen.dart';

class WillGoScreen extends StatefulWidget {
  const WillGoScreen({super.key});

  @override
  State<WillGoScreen> createState() => _WillGoScreenState();
}

class _WillGoScreenState extends State<WillGoScreen> {
  @override
  void initState() {
    super.initState();
    // Giả sử user đã login
    Future.microtask(() {
      context.read<WillGoViewModel>().loadWillGoList("current_user_uid");
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WillGoViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Will Go List"),
        backgroundColor: Colors.blue,
      ),
      body:
          vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : vm.willGoList.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_border, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "Bạn chưa có kế hoạch nào",
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: vm.willGoList.length,
                itemBuilder: (context, index) {
                  final product = vm.willGoList[index];
                  return ProductCard(
                    product: product,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(product: product),
                          ),
                        ),
                  );
                },
              ),
    );
  }
}
