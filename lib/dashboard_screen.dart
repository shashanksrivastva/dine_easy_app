import 'package:flutter/material.dart';

import 'package:dine_easy_app/theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;

  const DashboardScreen({super.key, this.userName = 'Guest'});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.restaurant},
    {'name': 'Indian', 'icon': Icons.ramen_dining},
    {'name': 'Chinese', 'icon': Icons.rice_bowl},
    {'name': 'Italian', 'icon': Icons.local_pizza},
    {'name': 'Fast Food', 'icon': Icons.fastfood},
    {'name': 'Desserts', 'icon': Icons.cake},
  ];

  final List<Map<String, dynamic>> _restaurants = [
    {
      'name': 'Spice Villa',
      'cuisine': 'North Indian • Chinese',
      'distance': '1.2 km away',
      'rating': '4.5',
      'image':
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4'
          '?auto=format&fit=crop&w=800&q=80',
    },
    {
      'name': 'The Urban Bowl',
      'cuisine': 'Continental • Italian',
      'distance': '2.4 km away',
      'rating': '4.3',
      'image':
          'https://images.unsplash.com/photo-1552566626-52f8b828add9'
          '?auto=format&fit=crop&w=800&q=80',
    },
    {
      'name': 'Cafe Aroma',
      'cuisine': 'Cafe • Beverages',
      'distance': '3.1 km away',
      'rating': '4.4',
      'image':
          'https://images.unsplash.com/photo-1554118811-1e0d58224f24'
          '?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeScreen(),
            _buildSimpleScreen(
              Icons.calendar_month,
              'My Bookings',
              'Your bookings will appear here.',
            ),
            _buildSimpleScreen(
              Icons.favorite_border,
              'Favourites',
              'Your favourite restaurants will appear here.',
            ),
            _buildSimpleScreen(
              Icons.receipt_long,
              'Orders',
              'Your orders will appear here.',
            ),
            _buildSimpleScreen(
              Icons.person_outline,
              'Profile',
              'Your profile details will appear here.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ----------------------------------------------------------
  // HOME SCREEN
  // ----------------------------------------------------------

  Widget _buildHomeScreen() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildHeader()),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildSearchBar()),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildBanner()),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader('Explore Cuisines', 'See All', () {}),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.only(top: 15),
          sliver: SliverToBoxAdapter(child: _buildCategories()),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader('Popular Near You', 'See All', () {}),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.only(top: 15),
          sliver: SliverToBoxAdapter(child: _buildRestaurantList()),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildOfferBanner()),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader('Recommended For You', 'See All', () {}),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // HEADER
  // ----------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${widget.userName}! 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Good food makes a great day!',
                style: TextStyle(fontSize: 14, color: AppColors.greyText),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 17,
                    color: AppColors.primaryOrange,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Your Location',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.darkText,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.notifications_none,
                  color: AppColors.darkText,
                  size: 25,
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  height: 9,
                  width: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // SEARCH BAR
  // ----------------------------------------------------------

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 25, color: AppColors.greyText),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Search restaurants, cuisines or dishes...',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: AppColors.greyText),
            ),
          ),
          Container(
            height: 35,
            width: 35,
            decoration: BoxDecoration(
              color: AppColors.lightCream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.tune,
              color: AppColors.darkOrange,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // PROMOTIONAL BANNER
  // ----------------------------------------------------------

  Widget _buildBanner() {
    return Container(
      height: 185,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColors.darkOrange,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1547592180-85f173990554'
              '?auto=format&fit=crop&w=1000&q=80',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: AppColors.darkOrange);
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.82),
                    Colors.black.withValues(alpha: 0.25),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Taste the Best\nin Your City',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Discover amazing restaurants\nnear you',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore Now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 7),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // CATEGORIES
  // ----------------------------------------------------------

  Widget _buildCategories() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 18);
        },
        itemBuilder: (context, index) {
          final category = _categories[index];
          final bool isSelected = index == 0;

          return GestureDetector(
            onTap: () {},
            child: SizedBox(
              width: 62,
              child: Column(
                children: [
                  Container(
                    height: 62,
                    width: 62,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.lightCream : Colors.white,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: AppColors.primaryOrange,
                              width: 1.3,
                            )
                          : null,
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: isSelected
                          ? AppColors.darkOrange
                          : AppColors.darkText,
                      size: 27,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.darkOrange
                          : AppColors.greyText,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // SECTION HEADER
  // ----------------------------------------------------------

  Widget _buildSectionHeader(
    String title,
    String actionText,
    VoidCallback onTap,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Text(
                actionText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkOrange,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.arrow_forward_ios,
                size: 11,
                color: AppColors.darkOrange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // RESTAURANT LIST
  // ----------------------------------------------------------

  Widget _buildRestaurantList() {
    return SizedBox(
      height: 286,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _restaurants.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 15);
        },
        itemBuilder: (context, index) {
          final restaurant = _restaurants[index];

          return _buildRestaurantCard(restaurant);
        },
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    return Container(
      width: 235,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 135,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    restaurant['image'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.lightCream,
                        child: const Icon(
                          Icons.restaurant,
                          size: 40,
                          color: AppColors.primaryOrange,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          restaurant['rating'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  restaurant['cuisine'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.greyText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.greyText,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      restaurant['distance'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Open Now',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF247524),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // OFFER BANNER
  // ----------------------------------------------------------

  Widget _buildOfferBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9DE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_offer_outlined,
              color: AppColors.darkOrange,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Great Food, Greater Deals!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6D2415),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Get up to 50% off at top restaurants.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8A5545)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              'Offers',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // BOTTOM NAVIGATION
  // ----------------------------------------------------------

  Widget _buildBottomNavigationBar() {
    const items = [
      {'label': 'Home', 'icon': Icons.home_outlined, 'activeIcon': Icons.home},
      {
        'label': 'Bookings',
        'icon': Icons.calendar_month_outlined,
        'activeIcon': Icons.calendar_month,
      },
      {
        'label': 'Favourites',
        'icon': Icons.favorite_border,
        'activeIcon': Icons.favorite,
      },
      {
        'label': 'Orders',
        'icon': Icons.receipt_long_outlined,
        'activeIcon': Icons.receipt_long,
      },
      {
        'label': 'Profile',
        'icon': Icons.person_outline,
        'activeIcon': Icons.person,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final bool isSelected = _selectedIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                            ? item['activeIcon'] as IconData
                            : item['icon'] as IconData,
                        color: isSelected
                            ? AppColors.darkOrange
                            : AppColors.greyText,
                        size: 23,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.darkOrange
                              : AppColors.greyText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // TEMPORARY OTHER SCREENS
  // ----------------------------------------------------------

  Widget _buildSimpleScreen(IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 70, color: AppColors.primaryOrange),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.greyText),
            ),
          ],
        ),
      ),
    );
  }
}
