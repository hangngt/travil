import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodel/willgo_viewmodel.dart';
import '../detail/detail_screen.dart';

class WillGoScreen extends StatefulWidget {
  const WillGoScreen({super.key});

  @override
  State<WillGoScreen> createState() => _WillGoScreenState();
}

class _WillGoScreenState extends State<WillGoScreen> {
  Set<int> selectedProducts = {};

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<WillGoViewModel>().loadWillGoList(
            FirebaseAuth.instance.currentUser!.uid,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final vm = context.watch<WillGoViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Will Go List"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              for (final id in selectedProducts) {
                await vm.removeFromWillGo(uid, id);
              }

              setState(() {
                selectedProducts.clear();
              });
            },
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : vm.willGoList.isEmpty
              ? const Center(
                  child: Text("No planned places"),
                )
              : ListView.builder(
                  itemCount: vm.willGoList.length,
                  itemBuilder: (context, index) {
                    final product = vm.willGoList[index];

                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: ListTile(
                        leading: Checkbox(
                          value: selectedProducts.contains(product.productId),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedProducts.add(product.productId);
                              } else {
                                selectedProducts.remove(product.productId);
                              }
                            });
                          },
                        ),
                        title: Text(product.title),
                        subtitle: Text(product.location),
                        trailing: Text(
                          "\$${product.price}",
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(
                                product: product,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
