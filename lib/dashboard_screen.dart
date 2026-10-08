import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'login_screen.dart';
import 'restaurant_details_screen.dart';
import 'services/firestore_service.dart';
import 'package:dine_easy_app/theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;

  const DashboardScreen({super.key, this.userName = 'Guest'});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _selectedCategory = 'All';
  String _currentLocation = 'Locating...';
  bool _isFetchingLocation = false;

  String _orderSearchQuery = '';
  String _orderFilterStatus = 'All';
  int _ordersLimit = 5;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _firestoreService.seedInitialDataIfEmpty();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestoreService.seedInitialOrdersIfEmpty(user.uid);
    }
    _fetchCurrentLocation();
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _fetchCurrentLocation() async {
    if (_isFetchingLocation) return;

    setState(() {
      _isFetchingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _currentLocation = 'Location disabled';
          });
          _showMessage('Location services are disabled. Please enable GPS.');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _currentLocation = 'Select Location';
            });
            _showMessage('Location permission denied.');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _currentLocation = 'Select Location';
          });
          _showMessage(
            'Location permissions are permanently denied. Please enable in Settings.',
          );
        }
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (e) {
        debugPrint('getCurrentPosition failed, trying last known: $e');
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        throw Exception('No position available');
      }

      String formattedLoc;
      try {
        List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        formattedLoc = placemarks.isNotEmpty
            ? _formatPlacemark(placemarks.first)
            : _formatCoordinates(position);
      } catch (e) {
        // Reverse geocoding failed (e.g. no network) — still show the user's
        // real position instead of a hardcoded city.
        debugPrint('Reverse geocoding failed: $e');
        formattedLoc = _formatCoordinates(position);
      }

      if (mounted) {
        setState(() {
          _currentLocation = formattedLoc;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() {
          _currentLocation = 'Select Location';
        });
        _showMessage('Unable to fetch live GPS location.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  // Placemark fields are empty strings (not null) when unknown, so pick the
  // first non-empty value rather than relying on `??`.
  String _formatPlacemark(Placemark place) {
    String firstNonEmpty(List<String?> values) => values
        .firstWhere((v) => v != null && v.trim().isNotEmpty, orElse: () => '')!
        .trim();

    final subArea = firstNonEmpty([
      place.subLocality,
      place.thoroughfare,
      place.name,
    ]);
    final locality = firstNonEmpty([
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
    ]);

    if (subArea.isNotEmpty && locality.isNotEmpty && subArea != locality) {
      return '$subArea, $locality';
    }
    if (subArea.isNotEmpty) return subArea;
    if (locality.isNotEmpty) return locality;
    return 'Current Location';
  }

  String _formatCoordinates(Position position) =>
      '${position.latitude.toStringAsFixed(4)}, '
      '${position.longitude.toStringAsFixed(4)}';

  IconData _getCategoryIcon(dynamic categoryName, dynamic iconCode) {
    switch (categoryName) {
      case 'Indian':
        return Icons.ramen_dining;
      case 'Chinese':
        return Icons.rice_bowl;
      case 'Italian':
        return Icons.local_pizza;
      case 'Fast Food':
        return Icons.fastfood;
      case 'Desserts':
        return Icons.cake;
      default:
        return Icons.restaurant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeScreen(),
            _buildBookingsScreen(),
            _buildSimpleScreen(
              Icons.favorite_border,
              'Favourites',
              'Your favourite restaurants will appear here.',
            ),
            _buildOrdersScreen(),
            _buildProfileScreen(),
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
          sliver: SliverToBoxAdapter(child: _buildBannerStream()),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader('Explore Cuisines', 'See All', () {}),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.only(top: 15),
          sliver: SliverToBoxAdapter(child: _buildCategoriesStream()),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader('Popular Near You', 'See All', () {}),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.only(top: 15),
          sliver: SliverToBoxAdapter(child: _buildRestaurantListStream()),
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
              GestureDetector(
                onTap: _showLocationPickerBottomSheet,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 17,
                      color: AppColors.primaryOrange,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _currentLocation,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    if (_isFetchingLocation)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppColors.darkText,
                      ),
                  ],
                ),
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
  // LOCATION PICKER BOTTOM SHEET
  // ----------------------------------------------------------

  void _showLocationPickerBottomSheet() {
    final TextEditingController locationSearchController =
        TextEditingController();

    final List<String> popularLocations = [
      'Indiranagar, Bengaluru',
      'Koramangala, Bengaluru',
      'HSR Layout, Bengaluru',
      'MG Road, Bengaluru',
      'Connaught Place, New Delhi',
      'Bandra West, Mumbai',
      'Jubilee Hills, Hyderabad',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Location',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(bottomSheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search bar for location
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: locationSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search city or area...',
                        hintStyle: const TextStyle(
                          color: AppColors.greyText,
                          fontSize: 14,
                        ),
                        prefixIcon:
                            const Icon(Icons.search, color: AppColors.greyText),
                        suffixIcon: locationSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  locationSearchController.clear();
                                  setModalState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (val) {
                        setModalState(() {});
                      },
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          setState(() {
                            _currentLocation = val.trim();
                          });
                          Navigator.pop(bottomSheetContext);
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Detect Current Location Button
                  InkWell(
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _fetchCurrentLocation();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.my_location_rounded,
                            color: AppColors.primaryOrange,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Use Current Location',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.primaryOrange,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isFetchingLocation
                                      ? 'Detecting GPS...'
                                      : 'Using GPS / Device location',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.greyText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isFetchingLocation)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryOrange,
                              ),
                            )
                          else
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: AppColors.greyText,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 24),

                  const Text(
                    'Popular Locations',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greyText,
                    ),
                  ),

                  const SizedBox(height: 10),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: popularLocations.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final loc = popularLocations[index];
                        final isSelected = _currentLocation == loc;

                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          leading: Icon(
                            Icons.location_on_outlined,
                            color: isSelected
                                ? AppColors.primaryOrange
                                : AppColors.greyText,
                          ),
                          title: Text(
                            loc,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primaryOrange
                                  : AppColors.darkText,
                              fontSize: 14,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primaryOrange,
                                  size: 20,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _currentLocation = loc;
                            });
                            Navigator.pop(bottomSheetContext);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
  // PROMOTIONAL BANNER (FIRESTORE STREAM)
  // ----------------------------------------------------------

  Widget _buildBannerStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getBannersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildBannerCard(
            title: 'Taste the Best\nin Your City',
            subtitle: 'Discover amazing restaurants\nnear you',
            imageUrl:
                'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=1000&q=80',
            actionText: 'Explore Now',
          );
        }

        final banner = snapshot.data!.first;
        return _buildBannerCard(
          title: banner['title'] ?? 'Taste the Best\nin Your City',
          subtitle: banner['subtitle'] ?? 'Discover amazing restaurants',
          imageUrl: banner['image'] ??
              'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=1000&q=80',
          actionText: banner['actionText'] ?? 'Explore Now',
        );
      },
    );
  }

  Widget _buildBannerCard({
    required String title,
    required String subtitle,
    required String imageUrl,
    required String actionText,
  }) {
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
              imageUrl,
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
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  subtitle,
                  style: const TextStyle(
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Icon(Icons.arrow_forward, size: 16),
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
  // CATEGORIES (FIRESTORE STREAM)
  // ----------------------------------------------------------

  Widget _buildCategoriesStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getCategoriesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 110,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 18),
            itemBuilder: (context, index) {
              final category = categories[index];
              final catName = category['name'] as String? ?? '';
              final bool isSelected = _selectedCategory == catName;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = catName;
                  });
                },
                child: SizedBox(
                  width: 62,
                  child: Column(
                    children: [
                      Container(
                        height: 62,
                        width: 62,
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.lightCream : Colors.white,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.primaryOrange,
                                  width: 1.3,
                                )
                              : null,
                        ),
                        child: Icon(
                          _getCategoryIcon(catName, category['iconCode']),
                          color: isSelected
                              ? AppColors.darkOrange
                              : AppColors.darkText,
                          size: 27,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        catName,
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
      },
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
  // RESTAURANT LIST (FIRESTORE STREAM)
  // ----------------------------------------------------------

  Widget _buildRestaurantListStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getRestaurantsStream(
        category: _selectedCategory,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 286,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final restaurants = snapshot.data ?? [];
        if (restaurants.isEmpty) {
          return const SizedBox(
            height: 150,
            child: Center(
              child: Text(
                'No restaurants found in this category',
                style: TextStyle(color: AppColors.greyText),
              ),
            ),
          );
        }

        return SizedBox(
          height: 286,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: restaurants.length,
            separatorBuilder: (context, index) => const SizedBox(width: 15),
            itemBuilder: (context, index) {
              return _buildRestaurantCard(restaurants[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsScreen(
              restaurantData: restaurant,
            ),
          ),
        );
      },
      child: Container(
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
                    restaurant['image'] as String? ?? '',
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
                          restaurant['rating']?.toString() ?? '4.0',
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
                  restaurant['name'] as String? ?? 'Restaurant',
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
                  restaurant['cuisine'] as String? ?? '',
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
                      restaurant['distance'] as String? ?? '',
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
                  child: Text(
                    (restaurant['isOpen'] as bool? ?? true)
                        ? 'Open Now'
                        : 'Closed',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: (restaurant['isOpen'] as bool? ?? true)
                          ? const Color(0xFF247524)
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
  // TEMPORARY OTHER SCREENS & PROFILE
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

  Widget _buildBookingsScreen() {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'anonymous';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Bookings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.lightCream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkOrange,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('userId', isEqualTo: userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: AppColors.lightCream,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_month_outlined,
                            size: 40,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No Bookings Found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You have not booked any tables yet. Explore restaurants and reserve a table!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.greyText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: docs.length,
                separatorBuilder: (context, _) => const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final docId = docs[index].id;
                  final restaurantName =
                      data['restaurantName'] ?? 'Restaurant';
                  final restaurantImage = data['restaurantImage'] ?? '';
                  final guestCount = data['guestCount'] ?? 2;
                  final time = data['time'] ?? '08:00 PM';
                  final seating = data['seating'] ?? 'Indoor Seating';
                  final name = data['name'] ?? 'Guest';
                  final phone = data['phone'] ?? '';
                  final status = data['status'] ?? 'Confirmed';

                  Timestamp? timestamp = data['date'] as Timestamp?;
                  DateTime date = timestamp?.toDate() ?? DateTime.now();
                  final dateStr =
                      '${date.day} ${_getMonthName(date.month)} ${date.year}';

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                restaurantImage,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 50,
                                  height: 50,
                                  color: AppColors.lightCream,
                                  child: const Icon(
                                    Icons.restaurant,
                                    color: AppColors.primaryOrange,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    restaurantName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$guestCount Guests • $seating',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.greyText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: AppColors.primaryOrange,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkText,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: AppColors.primaryOrange,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  time,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Booked for: $name ($phone)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.greyText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('bookings')
                                    .doc(docId)
                                    .delete();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Booking cancelled successfully',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 24),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Cancel Booking',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildOrdersScreen() {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'anonymous';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Orders',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.lightCream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'History',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkOrange,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search Bar for Orders
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _orderSearchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search orders by restaurant or item...',
                hintStyle:
                    const TextStyle(color: AppColors.greyText, fontSize: 13),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.greyText, size: 22),
                suffixIcon: _orderSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _orderSearchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // Filter Chips Row
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: ['All', 'Active', 'Delivered', 'Cancelled'].map((status) {
              final isSelected = _orderFilterStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(status),
                  selected: isSelected,
                  selectedColor: AppColors.primaryOrange,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.darkText,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryOrange
                          : Colors.grey.shade300,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _orderFilterStatus = status;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        // StreamBuilder with Pagination
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('userId', isEqualTo: userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              docs.sort((a, b) {
                Timestamp? tA = a.data()['createdAt'] as Timestamp?;
                Timestamp? tB = b.data()['createdAt'] as Timestamp?;
                if (tA == null || tB == null) return 0;
                return tB.compareTo(tA);
              });

              final limitedDocs = docs.take(_ordersLimit).toList();

              // Client-side filtering for search & status filter
              final filteredDocs = limitedDocs.where((doc) {
                final data = doc.data();
                final restName =
                    (data['restaurantName'] ?? '').toString().toLowerCase();
                final items = (data['items'] ?? '').toString().toLowerCase();
                final status = (data['status'] ?? 'Delivered').toString();

                bool matchesSearch = _orderSearchQuery.isEmpty ||
                    restName.contains(_orderSearchQuery) ||
                    items.contains(_orderSearchQuery);

                bool matchesStatus = _orderFilterStatus == 'All' ||
                    status.toLowerCase() == _orderFilterStatus.toLowerCase();

                return matchesSearch && matchesStatus;
              }).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: AppColors.lightCream,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            size: 40,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No Orders Found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No orders match your filter or search criteria.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: AppColors.greyText, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                itemCount:
                    filteredDocs.length + 1, // +1 for pagination load more
                separatorBuilder: (context, _) => const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  if (index == filteredDocs.length) {
                    // Pagination Load More button
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _ordersLimit += 5;
                            });
                          },
                          icon: const Icon(
                            Icons.refresh,
                            color: AppColors.primaryOrange,
                          ),
                          label: const Text(
                            'Load More Orders',
                            style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final data = filteredDocs[index].data();
                  final restaurantName =
                      data['restaurantName'] ?? 'Restaurant';
                  final restaurantImage = data['restaurantImage'] ?? '';
                  final items = data['items'] ?? 'Food Items';
                  final totalAmount = data['totalAmount'] ?? '₹0';
                  final status = data['status'] ?? 'Delivered';

                  Timestamp? timestamp = data['createdAt'] as Timestamp?;
                  DateTime date = timestamp?.toDate() ?? DateTime.now();
                  final dateStr =
                      '${date.day} ${_getMonthName(date.month)} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

                  Color statusColor = Colors.green.shade700;
                  Color statusBg = Colors.green.shade50;
                  if (status == 'Active') {
                    statusColor = AppColors.darkOrange;
                    statusBg = AppColors.lightCream;
                  } else if (status == 'Cancelled') {
                    statusColor = Colors.red.shade700;
                    statusBg = Colors.red.shade50;
                  }

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                restaurantImage,
                                width: 55,
                                height: 55,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 55,
                                  height: 55,
                                  color: AppColors.lightCream,
                                  child: const Icon(
                                    Icons.restaurant,
                                    color: AppColors.primaryOrange,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    restaurantName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.greyText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Text(
                          items,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.darkText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total: $totalAmount',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkText,
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Reordering from $restaurantName...',
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryOrange,
                                side: const BorderSide(
                                  color: AppColors.primaryOrange,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 0,
                                ),
                                minimumSize: const Size(70, 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Reorder',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileScreen() {
    final user = FirebaseAuth.instance.currentUser;
    final phone = user?.phoneNumber ?? widget.userName;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                color: AppColors.lightCream,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryOrange, width: 2),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 50,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Logged In User',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              phone,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.greyText,
              ),
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
