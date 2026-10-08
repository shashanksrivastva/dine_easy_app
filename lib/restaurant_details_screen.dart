import 'package:flutter/material.dart';

import 'booking_screen.dart';
import 'package:dine_easy_app/theme/app_colors.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? restaurantData;
  final String restaurantName;

  const RestaurantDetailsScreen({
    super.key,
    this.restaurantData,
    this.restaurantName = 'The Urban Bowl',
  });

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  static const Color primaryOrange = AppColors.primaryOrange;
  static const Color cream = AppColors.cream;
  static const Color lightCream = AppColors.lightCream;
  static const Color darkText = AppColors.darkText;
  static const Color greyText = AppColors.greyText;

  int selectedTab = 0;
  bool isFavourite = false;

  final List<String> tabs = ['Overview', 'Menu', 'Reviews', 'Photos'];

  // Dynamic getters from restaurantData
  String get name => widget.restaurantData?['name'] as String? ?? widget.restaurantName;
  String get image =>
      widget.restaurantData?['image'] as String? ??
      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1200';
  String get cuisine =>
      widget.restaurantData?['cuisine'] as String? ?? 'Continental • Italian • North Indian';
  String get rating => widget.restaurantData?['rating']?.toString() ?? '4.5';
  String get distance => widget.restaurantData?['distance'] as String? ?? '2.4 km away';
  String get address =>
      widget.restaurantData?['address'] as String? ?? 'MG Road, Bengaluru, Karnataka';
  String get averageCost => widget.restaurantData?['averageCost'] as String? ?? '₹800 for two';
  String get timing => widget.restaurantData?['timing'] as String? ?? '11:00 AM – 11:00 PM';
  String get phone => widget.restaurantData?['phone'] as String? ?? '+91 98765 43210';
  String get description =>
      widget.restaurantData?['description'] as String? ??
      '$name brings you a unique dining experience with a perfect blend of global cuisines, premium ambience, and exceptional service.';

  final List<Map<String, dynamic>> _cartItems = [];

  double get _cartTotal {
    double total = 0;
    for (var item in _cartItems) {
      final priceStr = (item['price'] as String? ?? '₹0')
          .replaceAll('₹', '')
          .replaceAll(',', '')
          .trim();
      final price = double.tryParse(priceStr) ?? 0;
      final qty = (item['quantity'] as int? ?? 1);
      total += price * qty;
    }
    return total;
  }

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      final existingIndex =
          _cartItems.indexWhere((i) => i['name'] == item['name']);
      if (existingIndex >= 0) {
        _cartItems[existingIndex]['quantity'] =
            (_cartItems[existingIndex]['quantity'] as int) + 1;
      } else {
        _cartItems.add({
          'name': item['name'],
          'price': item['price'],
          'image': item['image'],
          'quantity': 1,
        });
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['name']} added to table order'),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  Widget _buildCartSummaryBar() {
    if (_cartItems.isEmpty) return const SizedBox.shrink();

    int totalCount =
        _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: lightCream,
        border: Border(top: BorderSide(color: Colors.orange.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$totalCount ${totalCount == 1 ? 'Item' : 'Items'} selected',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: darkText,
                ),
              ),
              Text(
                'Total: ₹${_cartTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: primaryOrange,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              _openBookingScreen();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
            ),
            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
            label: const Text(
              'View Cart & Book',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> popularDishes = [
    {
      'name': 'Truffle Pasta',
      'price': '₹420',
      'image':
          'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=600',
    },
    {
      'name': 'Paneer Tikka',
      'price': '₹320',
      'image':
          'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=600',
    },
    {
      'name': 'Margherita Pizza',
      'price': '₹380',
      'image':
          'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600',
    },
  ];

  final List<Map<String, dynamic>> menuItems = [
    {
      'name': 'Paneer Tikka',
      'description': 'Grilled cottage cheese with aromatic spices',
      'price': '₹320',
      'veg': true,
      'image':
          'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=600',
    },
    {
      'name': 'Chicken Wings',
      'description': 'Crispy chicken wings with BBQ sauce',
      'price': '₹340',
      'veg': false,
      'image':
          'https://images.unsplash.com/photo-1527477396000-e27163b481c2?w=600',
    },
    {
      'name': 'Bruschetta',
      'description': 'Toasted bread with tomatoes and fresh basil',
      'price': '₹280',
      'veg': true,
      'image':
          'https://images.unsplash.com/photo-1572695157366-5e585ab2b69f?w=600',
    },
    {
      'name': 'Loaded Nachos',
      'description': 'Crispy nachos with cheese and jalapeños',
      'price': '₹300',
      'veg': true,
      'image':
          'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?w=600',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  _buildRestaurantHeader(),
                  SliverToBoxAdapter(child: _buildRestaurantInfo()),
                  SliverToBoxAdapter(child: _buildTabs()),
                  SliverToBoxAdapter(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildSelectedTab(),
                    ),
                  ),
                ],
              ),
            ),
            _buildCartSummaryBar(),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // HEADER
  // ----------------------------------------------------------

  Widget _buildRestaurantHeader() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _circleButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: _circleButton(
            icon: isFavourite ? Icons.favorite : Icons.favorite_border,
            iconColor: isFavourite ? primaryOrange : darkText,
            onTap: () {
              setState(() {
                isFavourite = !isFavourite;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          child: _circleButton(
            icon: Icons.share_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Share $name')),
              );
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: lightCream,
                  child: const Icon(
                    Icons.restaurant,
                    size: 70,
                    color: primaryOrange,
                  ),
                );
              },
            ),

            // Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 18,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '1/10',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = darkText,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: iconColor, size: 23),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // RESTAURANT INFO
  // ----------------------------------------------------------

  Widget _buildRestaurantInfo() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: darkText,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              _ratingBadge(),
              const SizedBox(width: 8),
              Text(
                rating,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                '(1.2K reviews)',
                style: TextStyle(color: greyText, fontSize: 14),
              ),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: greyText)),
              const SizedBox(width: 8),
              const Text(
                '₹₹₹',
                style: TextStyle(fontWeight: FontWeight.w600, color: greyText),
              ),
              const SizedBox(width: 8),
              _openNowBadge(),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            cuisine,
            style: const TextStyle(
              color: greyText,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 19, color: greyText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$distance  |  $address',
                  style: const TextStyle(color: greyText, fontSize: 14),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildFeatureRow(),
        ],
      ),
    );
  }

  Widget _ratingBadge() {
    return const Icon(Icons.star, color: Colors.amber, size: 21);
  }

  Widget _openNowBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F7E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Open Now',
        style: TextStyle(
          color: Color(0xFF188038),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFeatureRow() {
    final features = [
      {'icon': Icons.eco_outlined, 'title': 'Veg Options'},
      {'icon': Icons.table_restaurant_outlined, 'title': 'Indoor Seating'},
      {'icon': Icons.directions_car_outlined, 'title': 'Parking'},
      {'icon': Icons.groups_outlined, 'title': 'Family Friendly'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: features.map((item) {
        return Expanded(
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: lightCream,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: primaryOrange,
                  size: 25,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                item['title'] as String,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: greyText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ----------------------------------------------------------
  // TABS
  // ----------------------------------------------------------

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEAEAEA))),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = selectedTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTab = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? primaryOrange : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? primaryOrange : greyText,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ----------------------------------------------------------
  // SELECTED TAB
  // ----------------------------------------------------------

  Widget _buildSelectedTab() {
    switch (selectedTab) {
      case 1:
        return _buildMenu();
      case 2:
        return _buildReviews();
      case 3:
        return _buildPhotos();
      default:
        return _buildOverview();
    }
  }

  // ----------------------------------------------------------
  // OVERVIEW
  // ----------------------------------------------------------

  Widget _buildOverview() {
    return Padding(
      key: const ValueKey('overview'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: darkText,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            description,
            style: const TextStyle(color: greyText, fontSize: 15, height: 1.55),
          ),

          const SizedBox(height: 8),

          GestureDetector(
            onTap: () {},
            child: const Row(
              children: [
                Text(
                  'Read More',
                  style: TextStyle(
                    color: primaryOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, color: primaryOrange, size: 19),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildRestaurantDetailsCard(),

          const SizedBox(height: 25),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Dishes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedTab = 1;
                  });
                },
                child: const Text(
                  'View Menu',
                  style: TextStyle(
                    color: primaryOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: popularDishes.length,
              separatorBuilder: (context, _) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                return _buildPopularDish(popularDishes[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE3CE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _detailItem(
                  Icons.access_time,
                  timing,
                  'Opening Hours',
                ),
              ),
              Expanded(
                child: _detailItem(
                  Icons.table_restaurant_outlined,
                  'Available',
                  'Table Booking',
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _detailItem(
                  Icons.payments_outlined,
                  averageCost,
                  'Average Cost',
                ),
              ),
              Expanded(
                child: _detailItem(
                  Icons.phone_outlined,
                  phone,
                  'Call Restaurant',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryOrange, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(color: greyText, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPopularDish(Map<String, dynamic> dish) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            dish['image'] as String,
            height: 105,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 5),
            child: Text(
              dish['name'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              dish['price'] as String,
              style: const TextStyle(
                color: primaryOrange,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // MENU
  // ----------------------------------------------------------

  Widget _buildMenu() {
    return Padding(
      key: const ValueKey('menu'),
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),

          const SizedBox(height: 14),

          _buildCategoryChips(),

          const SizedBox(height: 22),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Starters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              Text(
                '${menuItems.length} items',
                style: const TextStyle(color: greyText, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ...menuItems.map((item) => _buildMenuItem(item)),

          const SizedBox(height: 10),

          _buildMenuSection('Main Course', '18'),
          _buildMenuSection('Pasta', '10'),
          _buildMenuSection('Pizza', '8'),
          _buildMenuSection('Desserts', '6'),
          _buildMenuSection('Beverages', '12'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          const Icon(Icons.search, color: greyText),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Search dishes...',
              style: TextStyle(color: greyText, fontSize: 14),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune, color: darkText),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = [
      'Starters',
      'Main Course',
      'Pasta',
      'Pizza',
      'Desserts',
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final selected = index == 0;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 17),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? primaryOrange : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              categories[index],
              style: TextStyle(
                color: selected ? Colors.white : darkText,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              item['image'] as String,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: SizedBox(
              height: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['name'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _vegIndicator(item['veg'] as bool? ?? true),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    item['description'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: greyText,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),

                  const Spacer(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['price'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () {
                            _addToCart(item);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryOrange,
                            side: const BorderSide(color: primaryOrange),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 17),
                          ),
                          child: const Text(
                            'Add',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vegIndicator(bool isVeg) {
    return Container(
      width: 16,
      height: 16,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: isVeg ? Colors.green : Colors.red),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isVeg ? Colors.green : Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildMenuSection(String title, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEAEAEA))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$title ($count)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: greyText),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // REVIEWS
  // ----------------------------------------------------------

  Widget _buildReviews() {
    return Padding(
      key: const ValueKey('reviews'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Reviews',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Text(
                  rating,
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 20),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Excellent',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Based on 1,200+ reviews',
                      style: TextStyle(color: greyText),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _reviewItem(
            'Rahul Sharma',
            'Amazing food and excellent ambience at $name.',
            '4.8',
          ),
          _reviewItem('Priya Singh', 'Great place for family dinner.', '4.5'),
        ],
      ),
    );
  }

  Widget _reviewItem(String name, String review, String rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEAEAEA)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: lightCream,
                child: Icon(Icons.person, color: primaryOrange),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 3),
              Text(rating, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Text(review, style: const TextStyle(color: greyText, height: 1.4)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // PHOTOS
  // ----------------------------------------------------------

  Widget _buildPhotos() {
    final images = [
      image,
      'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=600',
      'https://images.unsplash.com/photo-1515003197210-e0cd71810b5f?w=600',
      'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=600',
      'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=600',
      'https://images.unsplash.com/photo-1544148103-0773bf10d330?w=600',
    ];

    return Padding(
      key: const ValueKey('photos'),
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: images.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemBuilder: (_, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(images[index], fit: BoxFit.cover),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // BOTTOM BOOKING BAR
  // ----------------------------------------------------------

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    selectedTab = 1;
                  });
                },
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('View Menu'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryOrange,
                  side: const BorderSide(color: primaryOrange, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 1,
            child: SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  _openBookingScreen();
                },
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Book a Table'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openBookingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          restaurantName: name,
          restaurantImage: image,
          cartItems: _cartItems,
          totalAmount: '₹${_cartTotal.toStringAsFixed(0)}',
        ),
      ),
    );
  }
}
