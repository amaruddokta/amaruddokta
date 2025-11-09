// ignore_for_file: unnecessary_cast, unused_field
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amar_uddokta/uddoktaa/widgets/background_container.dart';
import 'package:amar_uddokta/uddoktaa/screens/sub_item_screen.dart';
import 'package:amar_uddokta/uddoktaa/screens/cart_screen.dart';
import 'package:amar_uddokta/uddoktaa/widgets/banner_slider.dart';
import 'package:amar_uddokta/uddoktaa/widgets/logo_widget.dart'; // Corrected import path
import 'package:amar_uddokta/uddoktaa/widgets/custom_drawer.dart';
import 'package:amar_uddokta/uddoktaa/widgets/video_list_section.dart';
import 'package:amar_uddokta/uddoktaa/widgets/bottom_icon.dart';
import 'package:amar_uddokta/uddoktaa/utils/call_helper.dart';
import 'package:amar_uddokta/madmin/services/firestore_service.dart'; // Import FirestoreService
import 'package:amar_uddokta/madmin/models/category_model.dart'; // Import ProductCategory

import 'package:amar_uddokta/uddoktaa/controllers/package_controller.dart';

import 'package:amar_uddokta/uddoktaa/screens/favorite_screen.dart';
import 'package:amar_uddokta/uddoktaa/widgets/all_items_list.dart';
import 'package:amar_uddokta/uddoktaa/screens/chat_screen.dart';
// Import LogoController
import 'package:marquee/marquee.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:amar_uddokta/uddoktaa/screens/my_orders_screen.dart';
import 'package:amar_uddokta/uddoktaa/screens/notification_screen.dart';
import 'package:amar_uddokta/uddoktaa/widgets/offer_widget.dart'; // Corrected import
import 'package:amar_uddokta/uddoktaa/screens/real_time_offer_screen.dart'; // Added import for RealTimeOfferScreen
import 'package:amar_uddokta/uddoktaa/screens/search_results_screen.dart'; // Import SearchResultsScreen
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isSearching = false;
  bool _showContactOptions = false;
  String searchQuery = '';
  final PackageController packageController = Get.put(PackageController());
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  // Cache for categories and offers
  final FirestoreService _firestoreService =
      FirestoreService(); // Initialize FirestoreService
  final List<ProductCategory> _cachedCategories =
      []; // Change type to ProductCategory
  List<Map<String, dynamic>> _cachedOffers = [];
  bool _isLoadingOffers = true;
  Stream<List<ProductCategory>>? _categoriesStream; // Change stream type
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _setupCategoriesStream();
    _loadOffers();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  void _setupCategoriesStream() {
    _categoriesStream =
        _firestoreService.getCategories(); // Use the service to get categories
  }

  Future<void> _onRefresh() async {
    // Re-fetch offers and packages, categories will update via stream
    await _loadOffers();
    packageController.fetchPackages();

    // Add a small animation when refreshing
    _animationController.reset();
    _animationController.forward();
  }

  void _handleScroll() {
    final shouldShow = _scrollController.offset > 300;
    if (shouldShow != _showBackToTopButton) {
      setState(() {
        _showBackToTopButton = shouldShow;
      });
    }
  }

  Future<void> _loadOffers() async {
    try {
      final response = await Supabase.instance.client
          .from('offers')
          .select()
          .eq('is_active', true)
          .limit(10);
      setState(() {
        _cachedOffers = (response as List).cast<Map<String, dynamic>>();
        _isLoadingOffers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingOffers = false;
      });
      debugPrint('Error loading offers: $e');
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _makeDynamicPhoneCall() async {
    try {
      final response = await Supabase.instance.client
          .from('adminNumbers')
          .select('cnumbers')
          .order('timestamp', ascending: false)
          .limit(1)
          .single();
      if (response != null) {
        final phoneNumber = response['cnumbers'] as String?;
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          makePhoneCall(context, phoneNumber);
        } else {
          Get.snackbar('Error', 'Phone number not available.');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch call number: $e');
    }
  }

  Widget _buildContactOptions() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomIcon(
            icon: Icons.phone,
            label: 'কল',
            color: Colors.green,
            onPressed: _makeDynamicPhoneCall,
          ),
          const SizedBox(height: 8),
          BottomIcon(
            icon: Icons.message,
            label: 'Chat',
            color: Colors.green,
            onPressed: () => Get.to(() => const ChatScreen()),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if there are any offers to show
    bool hasOffers = _cachedOffers.isNotEmpty;

    // Get screen size for responsive calculations
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // Calculate responsive sizes
    final double appBarHeight = screenHeight * 0.08;
    final double categoryItemSize = screenWidth * 0.15;
    final double bannerHeight = screenHeight * 0.22;
    final double offerItemWidth = screenWidth * 0.8;
    final double offerItemHeight = screenHeight * 0.2;
    final double bottomNavBarHeight = screenHeight * 0.08;

    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 246, 243, 243),
        drawer: const CustomDrawer(),
        floatingActionButton: _showBackToTopButton
            ? FloatingActionButton(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                mini: true,
                backgroundColor: const Color.fromARGB(255, 160, 67, 140),
                onPressed: _scrollToTop,
                child: const Icon(Icons.keyboard_double_arrow_up_rounded,
                    size: 35, color: Colors.white),
              )
            : null,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: _isSearching
              ? Container(
                  width: screenWidth * 0.5,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (query) {
                      setState(() => searchQuery = query);
                      if (query.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SearchResultsScreen(searchQuery: query),
                          ),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 15),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    ),
                    style: const TextStyle(color: Color.fromARGB(221, 8, 1, 1)),
                  ),
                )
              : const Text(
                  'আমার উদ্যোক্তা',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 26, 1, 1),
                  ),
                ),
          actions: [
            IconButton(
              color: const Color.fromARGB(255, 15, 2, 2),
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    searchQuery = '';
                  }
                });
              },
            ),
            Stack(
              children: [
                IconButton(
                  color: const Color.fromARGB(255, 253, 4, 4),
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    Get.to(() => const NotificationScreen());
                  },
                ),
              ],
            ),
          ],
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 7, 253, 212),
                  const Color.fromARGB(255, 7, 253, 212),
                  const Color.fromARGB(255, 7, 253, 212)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              color: const Color.fromARGB(255, 16, 218, 191),
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Notice Marquee with enhanced design
                      Container(
                        height: screenHeight * 0.06,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 241, 7, 7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.notifications_active,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StreamBuilder<List<Map<String, dynamic>>>(
                                stream: Supabase.instance.client
                                    .from('admin_notice')
                                    .stream(primaryKey: ['id']).eq(
                                        'is_active', true),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const Center(
                                        child: Text("No notices"));
                                  }
                                  final notice = snapshot.data!.first;
                                  final text = notice['admin_text'] ?? '';

                                  if (text.isEmpty) {
                                    return const Center(
                                        child: Text("No notices"));
                                  }

                                  return Marquee(
                                    text: text,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          const Color.fromARGB(255, 225, 5, 5),
                                    ),
                                    blankSpace: 50.0,
                                    velocity: 50.0,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Categories - Using StreamBuilder for real-time updates with enhanced design
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: StreamBuilder<List<ProductCategory>>(
                          stream: _categoriesStream, // Use the updated stream
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return SizedBox(
                                height: categoryItemSize * 2,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.green,
                                  ),
                                ),
                              );
                            }
                            final categories = snapshot.data!;
                            if (categories.isEmpty) {
                              return const Center(
                                  child: Text('No categories found.'));
                            }
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 12),
                              child: Row(
                                children: categories.map((category) {
                                  return AnimationConfiguration.staggeredList(
                                    position: categories.indexOf(category),
                                    duration: const Duration(milliseconds: 375),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Column(
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          SubItemScreen(
                                                        categoryName: category
                                                            .categoriesName, // Use model property
                                                      ),
                                                    ),
                                                  );
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                child: Container(
                                                  width: categoryItemSize,
                                                  height: categoryItemSize,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        const Color.fromARGB(
                                                            255, 249, 251, 251),
                                                        const Color.fromARGB(
                                                            255, 245, 247, 247)
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      category
                                                          .categoriesIcon, // Use model property
                                                      style: TextStyle(
                                                          fontSize:
                                                              categoryItemSize *
                                                                  0.4),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                width: categoryItemSize,
                                                child: Text(
                                                  category
                                                      .categoriesName, // Use model property
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.03,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Banner Slider with enhanced design
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0),
                        height: bannerHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Obx(() {
                          if (packageController.packages.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(5.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.green,
                                ),
                              ),
                            );
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: BannerSlider(
                                packages: packageController.packages),
                          );
                        }),
                      ),
                      const SizedBox(height: 0),
                      // Logo Widget with enhanced design
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: LogoWidget(),
                      ),
                      const SizedBox(height: 0),
                      // Offer Widgets with enhanced design
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        // child: OfferWidgets(),
                      ),

                      const SizedBox(height: 0),
                      // Offers List - Enhanced design
                      // Only show if there are offers
                      if (hasOffers)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isLoadingOffers
                              ? SizedBox(
                                  height: offerItemHeight,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.green),
                                  ),
                                )
                              : SizedBox(
                                  height: offerItemHeight,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _cachedOffers.length,
                                    itemBuilder: (context, index) {
                                      final offer = _cachedOffers[index];
                                      final endTimeString =
                                          offer['endTime'] as String?;
                                      int remainingMinutes = 0;
                                      if (endTimeString != null) {
                                        final now = DateTime.now();
                                        final endDateTime =
                                            DateTime.parse(endTimeString);
                                        final difference =
                                            endDateTime.difference(now);
                                        remainingMinutes = difference.inMinutes;
                                      }
                                      return AnimationConfiguration
                                          .staggeredList(
                                        position: index,
                                        duration:
                                            const Duration(milliseconds: 375),
                                        child: SlideAnimation(
                                          horizontalOffset: 50.0,
                                          child: FadeInAnimation(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                              child: SizedBox(
                                                width: offerItemWidth,
                                                height: offerItemHeight,
                                                child: OfferWidget(
                                                  offer: offer,
                                                  remainingMinutes:
                                                      remainingMinutes,
                                                  onTap: () {
                                                    Get.to(() =>
                                                        RealTimeOfferScreen(
                                                            offer: offer));
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      const SizedBox(height: 8),
                      // Video List Section (from user_panel) with enhanced design
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const VideoListSection(),
                      ),
                      const SizedBox(height: 16),
                      // All Items List with enhanced design
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 2;
                            if (constraints.maxWidth > 1200) {
                              crossAxisCount = 5;
                            } else if (constraints.maxWidth > 800) {
                              crossAxisCount = 4;
                            } else if (constraints.maxWidth > 600) {
                              crossAxisCount = 3;
                            }
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: AllItemsList(
                                categoryName: '',
                                searchQuery: searchQuery,
                                crossAxisCount: crossAxisCount,
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: bottomNavBarHeight * 1.5),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: bottomNavBarHeight * 1.2,
              left: 16,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showContactOptions ? _buildContactOptions() : null,
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          height: bottomNavBarHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: CurvedNavigationBar(
            height: bottomNavBarHeight * 0.9,
            backgroundColor: Colors.transparent,
            color: const Color.fromARGB(255, 7, 253, 212),
            items: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.contact_phone_sharp,
                      size: screenWidth * 0.06,
                      color: const Color.fromARGB(255, 26, 6, 6)),
                  Text('যোগাযোগ',
                      style: TextStyle(
                          color: const Color.fromARGB(255, 11, 2, 2),
                          fontSize: screenWidth * 0.03)),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart,
                      size: screenWidth * 0.06,
                      color: const Color.fromARGB(255, 15, 1, 1)),
                  Text('অর্ডার',
                      style: TextStyle(
                          color: const Color.fromARGB(255, 12, 2, 2),
                          fontSize: screenWidth * 0.03)),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: screenWidth * 0.06,
                      color: const Color.fromARGB(255, 15, 1, 1)),
                  Text('অর্ডার সমূহ',
                      style: TextStyle(
                          color: const Color.fromARGB(255, 12, 2, 2),
                          fontSize: screenWidth * 0.03)),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite,
                      size: screenWidth * 0.06,
                      color: const Color.fromARGB(255, 20, 5, 5)),
                  Text('পছন্দ',
                      style: TextStyle(
                          color: const Color.fromARGB(255, 14, 1, 1),
                          fontSize: screenWidth * 0.03)),
                ],
              ),
            ],
            onTap: (index) {
              if (index == 0) {
                setState(() {
                  _showContactOptions = !_showContactOptions;
                });
              } else if (index == 1) {
                Get.to(() => CartScreen());
              } else if (index == 2) {
                Get.to(() => MyOrdersScreen());
              } else if (index == 3) {
                Get.to(() => FavoriteScreen());
              }
            },
          ),
        ),
      ),
    );
  }
}
