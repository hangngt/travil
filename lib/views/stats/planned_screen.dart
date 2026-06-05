import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodel/planned_viewmodel.dart';
import '../../widget/product_card.dart';
import '../detail/detail_screen.dart';

class PlannedScreen extends StatefulWidget {
  final int month;
  final String monthName;

  const PlannedScreen({
    super.key,
    required this.month,
    required this.monthName,
  });

  @override
  State<PlannedScreen> createState() => _PlannedScreenState();
}

class _PlannedScreenState extends State<PlannedScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<PlannedViewModel>().loadPlannedByMonth(
            uid: FirebaseAuth.instance.currentUser!.uid,
            month: widget.month,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlannedViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.monthName} Planned Trips"),
      ),
      body: vm.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : vm.plannedProducts.isEmpty
              ? const Center(
                  child: Text("No planned trips"),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.plannedProducts.length,
                  itemBuilder: (context, index) {
                    final product = vm.plannedProducts[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ProductCard(
                        product: product,
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
