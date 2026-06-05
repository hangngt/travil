import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../../viewmodel/rating_viewmodel.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Set<String> selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rating History"),
        actions: [
          if (selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                for (final id in selectedIds) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('ratings')
                      .doc(id)
                      .delete();
                }

                selectedIds.clear();

                setState(() {});
              },
            ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: context.read<RatingViewModel>().getRatingHistory(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final ratings = snapshot.data!;

          if (ratings.isEmpty) {
            return const Center(
              child: Text("No ratings"),
            );
          }

          return ListView.builder(
            itemCount: ratings.length,
            itemBuilder: (context, index) {
              final item = ratings[index];

              final productId = item['productId'];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Checkbox(
                        value: selectedIds.contains(productId),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedIds.add(productId);
                            } else {
                              selectedIds.remove(productId);
                            }
                          });
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "${item['rating']}",
                                ),
                              ],
                            ),
                            if (item['review'] != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 6,
                                ),
                                child: Text(
                                  item['review'],
                                ),
                              ),
                            const SizedBox(height: 6),
                            if (item['visitedAt'] != null)
                              Text(
                                "Visited: ${(item['visitedAt'] as Timestamp).toDate()}",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          double tempRating = item['rating'].toDouble();

                          final reviewController = TextEditingController(
                            text: item['review'] ?? '',
                          );

                          await showDialog(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                title: const Text(
                                  "Edit Rating",
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // STAR
                                      RatingBar.builder(
                                        initialRating: tempRating,
                                        minRating: 1,
                                        allowHalfRating: true,
                                        itemBuilder: (_, __) {
                                          return const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                          );
                                        },
                                        onRatingUpdate: (value) {
                                          tempRating = value;
                                        },
                                      ),

                                      const SizedBox(height: 20),

                                      // REVIEW
                                      TextField(
                                        controller: reviewController,
                                        maxLines: 4,
                                        decoration: InputDecoration(
                                          hintText: "Edit your review...",
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      await context
                                          .read<RatingViewModel>()
                                          .addRating(
                                            uid: uid,
                                            productId: productId,
                                            title: item['title'],
                                            rating: tempRating,

                                            // FIX
                                            review:
                                                reviewController.text.trim(),
                                          );

                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      "Save",
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
