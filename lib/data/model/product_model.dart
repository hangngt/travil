import 'package:cloud_firestore/cloud_firestore.dart';

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

  final DateTime? plannedDate;

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
    this.plannedDate,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: int.tryParse(
            json['product_id']?.toString() ?? "0",
          ) ??
          0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      location: json['location'] ?? '',
      url: json['url'] ?? '',
      rating: double.tryParse(
            json['rating']?.toString() ?? "0",
          ) ??
          0,
      price: double.tryParse(
            json['price']?.toString() ?? "0",
          ) ??
          0,
      bookedCount: int.tryParse(
            json['booked_count']?.toString() ?? "0",
          ) ??
          0,
      reviewCount: int.tryParse(
            json['review_count']?.toString() ?? "0",
          ) ??
          0,
      lat: double.tryParse(
            json['lat']?.toString() ?? "0",
          ) ??
          0,
      lng: double.tryParse(
            json['lng']?.toString() ?? "0",
          ) ??
          0,
      plannedDate: json['plannedDate'] is Timestamp
          ? (json['plannedDate'] as Timestamp).toDate()
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'title': title,
      'location': location,
      'rating': rating,
      'price': price,
      'lat': lat,
      'lng': lng,
      'image_url': imageUrl,
      'description': description,
      'review_count': reviewCount,
      'booked_count': bookedCount,
      'plannedDate': plannedDate,
    };
  }

  ProductModel copyWith({
    DateTime? plannedDate,
  }) {
    return ProductModel(
      productId: productId,
      title: title,
      description: description,
      imageUrl: imageUrl,
      location: location,
      url: url,
      rating: rating,
      price: price,
      bookedCount: bookedCount,
      reviewCount: reviewCount,
      lat: lat,
      lng: lng,
      plannedDate: plannedDate ?? this.plannedDate,
    );
  }
}
