import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travil/widget/product_card.dart';
import '../../viewmodel/willgo_viewmodel.dart';

class WillGoScreen extends StatelessWidget {
  const WillGoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WillGoViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Will Go List")),
      body:
          vm.willGoList.isEmpty
              ? const Center(child: Text("Bạn chưa có kế hoạch nào"))
              : ListView.builder(
                itemCount: vm.willGoList.length,
                itemBuilder: (context, index) {
                  final product = vm.willGoList[index];
                  return ProductCard(product: product, onTap: () {});
                },
              ),
    );
  }
}
