import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'package:travil/data/model/product_model.dart';
import 'package:travil/viewmodel/rating_viewmodel.dart';
import 'package:travil/viewmodel/trip_status_viewmodel.dart';
import 'package:travil/viewmodel/willgo_viewmodel.dart';

class DetailScreen extends StatefulWidget {
  final ProductModel product;

  const DetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  GoogleMapController? mapController;

  double userRating = 0;
  final TextEditingController reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // APP BAR IMAGE
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.product.productId,
                child: Image.network(
                  widget.product.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE
                  Text(
                    widget.product.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // RATING
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: widget.product.rating,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${widget.product.rating}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "(${widget.product.reviewCount} reviews)",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // LOCATION
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.product.location,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // PRICE
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "\$${widget.product.price}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // BOOKED COUNT
                  Row(
                    children: [
                      const Icon(Icons.people_alt),
                      const SizedBox(width: 8),
                      Text(
                        "${widget.product.bookedCount} people booked",
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // DESCRIPTION
                  const Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.product.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // REVIEW SECTION

                  const SizedBox(height: 30),

                  // MAP TITLE
                  const Text(
                    "Location",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // GOOGLE MAP
                  SizedBox(
                    height: 250,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            widget.product.lat,
                            widget.product.lng,
                          ),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('location'),
                            position: LatLng(
                              widget.product.lat,
                              widget.product.lng,
                            ),
                            infoWindow: InfoWindow(
                              title: widget.product.title,
                              snippet: widget.product.location,
                            ),
                          ),
                        },
                        onMapCreated: (GoogleMapController controller) {
                          mapController = controller;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // WILL GO BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.bookmark_add,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: () async {
                        await context.read<WillGoViewModel>().addToWillGo(
                              uid,
                              widget.product,
                            );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Added to Will Go",
                              ),
                            ),
                          );
                        }
                      },
                      label: const Text("Add To Will Go"),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // TRIP STATUS
                  Consumer<TripStatusViewModel>(
                    builder: (context, vm, child) {
                      return Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2030),
                                );

                                if (pickedDate == null) return;

                                final confirm = await showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Confirm Trip"),
                                    content: Text(
                                      "Plan this trip on ${pickedDate.day}/${pickedDate.month}/${pickedDate.year} ?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Confirm"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm != true) return;

                                await vm.updateStatus(
                                  uid: uid,
                                  product: widget.product.copyWith(
                                    plannedDate: pickedDate,
                                  ),
                                  status: "planned",
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Added to planned trips",
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text("Planned"),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () async {
                                double tempRating = 0;
                                final reviewController =
                                    TextEditingController();

                                final confirm = await showDialog(
                                  context: context,
                                  builder: (_) {
                                    return StatefulBuilder(
                                      builder: (context, setStateDialog) {
                                        return AlertDialog(
                                          title: const Text("Rate your trip"),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                RatingBar.builder(
                                                  initialRating: tempRating,
                                                  minRating: 1,
                                                  allowHalfRating: true,
                                                  itemBuilder: (context, _) {
                                                    return const Icon(
                                                      Icons.star,
                                                      color: Colors.amber,
                                                    );
                                                  },
                                                  onRatingUpdate: (rating) {
                                                    setStateDialog(() {
                                                      tempRating = rating;
                                                    });
                                                  },
                                                ),
                                                const SizedBox(height: 16),
                                                TextField(
                                                  controller: reviewController,
                                                  maxLines: 3,
                                                  decoration:
                                                      const InputDecoration(
                                                    hintText:
                                                        "Write your review...",
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context, false);
                                              },
                                              child: const Text("Cancel"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context, true);
                                              },
                                              child: const Text("Submit"),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );

                                if (confirm != true) return;

                                await vm.updateStatus(
                                  uid: uid,
                                  product: widget.product,
                                  status: "visited",
                                );

                                if (tempRating > 0) {
                                  await context
                                      .read<RatingViewModel>()
                                      .addRating(
                                        uid: uid,
                                        productId:
                                            widget.product.productId.toString(),
                                        title: widget.product.title,
                                        rating: tempRating,
                                        review: reviewController.text,
                                      );
                                }

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Trip completed successfully",
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text("Visited"),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
