import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _firestore.collection('categories');

  CollectionReference<Map<String, dynamic>> get _restaurantsRef =>
      _firestore.collection('restaurants');

  CollectionReference<Map<String, dynamic>> get _bannersRef =>
      _firestore.collection('banners');

  /// Stream of categories from Firestore
  Stream<List<Map<String, dynamic>>> getCategoriesStream() {
    return _categoriesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Stream of restaurants from Firestore with optional cuisine/category filter
  Stream<List<Map<String, dynamic>>> getRestaurantsStream({String? category}) {
    Query<Map<String, dynamic>> query = _restaurantsRef;

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Stream of promotional banners from Firestore
  Stream<List<Map<String, dynamic>>> getBannersStream() {
    return _bannersRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Seeds initial sample data into Cloud Firestore if collections are empty.
  Future<void> seedInitialDataIfEmpty() async {
    try {
      final snapshot = await _restaurantsRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return; // Data already exists
      }

      debugPrint('Seeding initial Firestore data for DineEasy...');

      // Seed Categories
      final categories = [
        {'name': 'All', 'iconCode': 0xe532, 'sortOrder': 1}, // Icons.restaurant
        {'name': 'Indian', 'iconCode': 0xeeb1, 'sortOrder': 2}, // Icons.ramen_dining
        {'name': 'Chinese', 'iconCode': 0xeeb5, 'sortOrder': 3}, // Icons.rice_bowl
        {'name': 'Italian', 'iconCode': 0xe531, 'sortOrder': 4}, // Icons.local_pizza
        {'name': 'Fast Food', 'iconCode': 0xe25a, 'sortOrder': 5}, // Icons.fastfood
        {'name': 'Desserts', 'iconCode': 0xe116, 'sortOrder': 6}, // Icons.cake
      ];

      for (var cat in categories) {
        await _categoriesRef.add(cat);
      }

      // Seed Restaurants
      final restaurants = [
        {
          'name': 'Spice Villa',
          'category': 'Indian',
          'cuisine': 'North Indian • Chinese',
          'distance': '1.2 km away',
          'rating': '4.5',
          'image':
              'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
          'isOpen': true,
        },
        {
          'name': 'The Urban Bowl',
          'category': 'Italian',
          'cuisine': 'Continental • Italian',
          'distance': '2.4 km away',
          'rating': '4.3',
          'image':
              'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=800&q=80',
          'isOpen': true,
        },
        {
          'name': 'Cafe Aroma',
          'category': 'Fast Food',
          'cuisine': 'Cafe • Beverages',
          'distance': '3.1 km away',
          'rating': '4.4',
          'image':
              'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800&q=80',
          'isOpen': true,
        },
        {
          'name': 'Dragon Express',
          'category': 'Chinese',
          'cuisine': 'Chinese • Asian',
          'distance': '0.8 km away',
          'rating': '4.6',
          'image':
              'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=800&q=80',
          'isOpen': true,
        },
        {
          'name': 'Sweet Delights',
          'category': 'Desserts',
          'cuisine': 'Desserts • Bakery',
          'distance': '1.8 km away',
          'rating': '4.8',
          'image':
              'https://images.unsplash.com/photo-1587314168485-3236d6710814?auto=format&fit=crop&w=800&q=80',
          'isOpen': true,
        },
      ];

      for (var rest in restaurants) {
        await _restaurantsRef.add(rest);
      }

      // Seed Banners
      final banners = [
        {
          'title': 'Taste the Best\nin Your City',
          'subtitle': 'Discover amazing restaurants\nnear you',
          'image':
              'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=1000&q=80',
          'actionText': 'Explore Now',
        },
      ];

      for (var banner in banners) {
        await _bannersRef.add(banner);
      }

      debugPrint('Firestore initial data seeded successfully!');
    } catch (e) {
      debugPrint('Failed to seed Firestore data: $e');
    }
  }

  /// Seeds sample orders for the given user if none exist
  Future<void> seedInitialOrdersIfEmpty(String userId) async {
    try {
      final ordersRef = _firestore.collection('orders');
      final snapshot = await ordersRef.where('userId', isEqualTo: userId).get();
      if (snapshot.docs.isNotEmpty) return;

      final sampleOrders = [
        {
          'userId': userId,
          'restaurantName': 'The Urban Bowl',
          'restaurantImage':
              'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=800&q=80',
          'items': '1x Truffle Pasta, 1x Margherita Pizza',
          'totalAmount': '₹800',
          'status': 'Active',
          'createdAt': Timestamp.now(),
        },
        {
          'userId': userId,
          'restaurantName': 'Spice Villa',
          'restaurantImage':
              'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
          'items': '2x Butter Chicken, 4x Garlic Naan',
          'totalAmount': '₹850',
          'status': 'Delivered',
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 2)),
          ),
        },
        {
          'userId': userId,
          'restaurantName': 'Dragon Express',
          'restaurantImage':
              'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=800&q=80',
          'items': '2x Hakka Noodles, 1x Veg Manchurian',
          'totalAmount': '₹520',
          'status': 'Cancelled',
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 5)),
          ),
        },
      ];

      for (var order in sampleOrders) {
        await ordersRef.add(order);
      }
    } catch (e) {
      debugPrint('Failed to seed sample orders: $e');
    }
  }
}
