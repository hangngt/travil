import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:travil/widget/trip_status_chip.dart';

import '../../data/model/product_model.dart';
import '../../viewmodel/willgo_viewmodel.dart';

class DetailScreen extends StatefulWidget {
  final ProductModel product;

  const DetailScreen({super.key, required this.product});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  GoogleMapController? mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar với hình ảnh
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                widget.product.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: widget.product.rating,
                        itemBuilder:
                            (context, index) =>
                                const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${widget.product.rating} • ${widget.product.reviewCount} reviews",
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      Expanded(child: Text(widget.product.location)),
                      Text(
                        "\$${widget.product.price}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text(
                    widget.product.description,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),

                  const SizedBox(height: 24),

                  // Google Maps
                  const Text(
                    "Vị trí",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
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
                            markerId: const MarkerId('product_location'),
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
                        mapType: MapType.normal,
                        onMapCreated: (GoogleMapController controller) {
                          mapController = controller;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Nút Will Go
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<WillGoViewModel>().addToWillGo(
                        "current_user_uid", // Thay bằng uid thật sau
                        widget.product,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Đã thêm vào danh sách Will Go!"),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bookmark_add),
                    label: const Text("Thêm vào Will Go"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: Colors.blue,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Trạng thái chuyến đi
                  TripStatusChip(productId: widget.product.productId),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
