class ProductModel {
  final int productId;
  final String title;
  final String description;
  final String imageUrl;
  final String location;
  final String url;
  final double rating;
  final double price;
  final int bookedCount;
  final int reviewCount;
  final double lat;
  final double lng;

  ProductModel({
    required this.productId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.url,
    required this.rating,
    required this.price,
    required this.bookedCount,
    required this.reviewCount,
    required this.lat,
    required this.lng,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['product_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json["image_url"] ?? "",
      location: json['location'] ?? '',
      url: json['url'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      price: (json['price'] ?? 0.0).toDouble(),
      bookedCount: json['booked_count'] ?? 0,
      reviewCount: json['review_count'] ?? 0,
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }
}
