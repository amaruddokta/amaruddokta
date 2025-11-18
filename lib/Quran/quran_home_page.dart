import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qcf_quran/qcf_quran.dart';
import 'package:google_fonts/google_fonts.dart';

class QuranHomePage extends StatefulWidget {
  const QuranHomePage({super.key});

  @override
  State<QuranHomePage> createState() => _QuranHomePageState();
}

class _QuranHomePageState extends State<QuranHomePage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  bool _isPanelVisible = false;

  @override
  void initState() {
    super.initState();
    // অ্যানিমেশন কন্ট্রোলার ইনিশিয়ালাইজ করা হচ্ছে
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // অ্যানিমেশনের সময়কাল
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // প্রথম পৃষ্ঠা লোড হওয়ার সময় অ্যানিমেশন শুরু করা
    _fadeAnimationController.forward();

    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        // পৃষ্ঠা পরিবর্তনের সময় অ্যানিমেশন রিসেট এবং আবার শুরু করা
        _fadeAnimationController.reset();
        _fadeAnimationController.forward();
        setState(() => _currentPage = page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeAnimationController.dispose(); // কন্ট্রোলার ডিসপোজ করা
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          "القرآن الكريم",
          style: GoogleFonts.amiri(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E5F3F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white),
            onPressed: () => _showBookmarks(context),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _showPageJumpDialog,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "prev",
            onPressed: () {
              if (_currentPage > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            backgroundColor: const Color(0xFF1E5F3F),
            child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
          ),
          SizedBox(height: 10.h),
          FloatingActionButton(
            heroTag: "next",
            onPressed: () {
              if (_currentPage < totalPagesCount - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            backgroundColor: const Color(0xFF1E5F3F),
            child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          // পুরো কুরআনের পৃষ্ঠা দেখানো হবে, এখানে অ্যানিমেশন যোগ করা হয়েছে
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.r),
              child: FadeTransition(
                opacity: _fadeAnimation, // এখানে অ্যানিমেশন প্রয়োগ করা হচ্ছে
                child: PageviewQuran(
                  controller: _pageController,
                  sp: 1.2.sp,
                  h: 1.1.h,
                ),
              ),
            ),
          ),

          // উপরে পৃষ্ঠা সংখ্যা
          Positioned(
            top: 20.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E5F3F).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Text(
                  "صفحة ${_currentPage + 1} من $totalPagesCount",
                  style: GoogleFonts.amiri(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // নিচে পৃষ্ঠা ও সূরা তথ্য
          Positioned(
            bottom: 20.h,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isPanelVisible = !_isPanelVisible;
                });
              },
              child: Center(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E5F3F).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getSurahInfoForPage(_currentPage + 1),
                        style: GoogleFonts.amiri(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        _isPanelVisible
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 20.w,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // বিস্তারিত প্যানেল
          if (_isPanelVisible)
            Positioned(
              bottom: 80.h,
              left: 20.w,
              right: 20.w,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "معلومات الصفحة",
                      style: GoogleFonts.amiri(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E5F3F),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    _buildInfoRow(
                        "الجزء", _getJuzInfoForPage(_currentPage + 1)),
                    _buildInfoRow(
                        "الصفحة", "${_currentPage + 1} من $totalPagesCount"),
                    _buildInfoRow(
                        "السورة", _getSurahInfoForPage(_currentPage + 1)),
                    _buildInfoRow(
                        "نوع السورة", _getSurahTypeForPage(_currentPage + 1)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.amiri(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.amiri(
              fontSize: 16.sp,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFFF5F5F5),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1E5F3F),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'القرآن الكريم',
                    style: GoogleFonts.amiri(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'تطبيق قراءة القرآن',
                    style: GoogleFonts.amiri(
                      color: Colors.white70,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF1E5F3F)),
              title: Text(
                'الصفحة الرئيسية',
                style: GoogleFonts.amiri(fontSize: 16.sp),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark, color: Color(0xFF1E5F3F)),
              title: Text(
                'المرجعيات',
                style: GoogleFonts.amiri(fontSize: 16.sp),
              ),
              onTap: () {
                Navigator.pop(context);
                _showBookmarks(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list, color: Color(0xFF1E5F3F)),
              title: Text(
                'قائمة السور',
                style: GoogleFonts.amiri(fontSize: 16.sp),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSurahList(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFF1E5F3F)),
              title: Text(
                'الإعدادات',
                style: GoogleFonts.amiri(fontSize: 16.sp),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSettings(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Color(0xFF1E5F3F)),
              title: Text(
                'حول التطبيق',
                style: GoogleFonts.amiri(fontSize: 16.sp),
              ),
              onTap: () {
                Navigator.pop(context);
                _showAbout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Helper function → পৃষ্ঠা অনুযায়ী সূরা নাম দেখায়
  String _getSurahInfoForPage(int pageNumber) {
    try {
      final dynamic pageDataRaw = getPageData(pageNumber);

      if (pageDataRaw == null) {
        return "صفحة $pageNumber";
      }

      final Map<String, dynamic> pageData;
      if (pageDataRaw is Map<String, dynamic>) {
        pageData = pageDataRaw;
      } else if (pageDataRaw is Map) {
        pageData = Map<String, dynamic>.from(pageDataRaw);
      } else {
        return "صفحة $pageNumber";
      }

      final dynamic surahRawCandidate = pageData.containsKey('surah')
          ? pageData['surah']
          : pageData.containsKey('sura')
              ? pageData['sura']
              : pageData.containsKey('surahNumber')
                  ? pageData['surahNumber']
                  : pageData.containsKey('suraNumber')
                      ? pageData['suraNumber']
                      : null;

      int surahNumber = 0;
      if (surahRawCandidate != null) {
        final dynamic surahRaw = surahRawCandidate;
        if (surahRaw is int) {
          surahNumber = surahRaw;
        } else if (surahRaw is double) {
          surahNumber = surahRaw.toInt();
        } else if (surahRaw is String) {
          surahNumber = int.tryParse(surahRaw) ?? 0;
        } else {
          surahNumber = 0;
        }
      }

      if (surahNumber <= 0) {
        return "صفحة $pageNumber";
      }

      final String nameArabic = getSurahNameArabic(surahNumber);
      return nameArabic;
    } catch (e) {
      return "صفحة $pageNumber";
    }
  }

  /// Helper function → পৃষ্ঠা অনুযায়ী জুজ নম্বর দেখায়
  String _getJuzInfoForPage(int pageNumber) {
    try {
      final dynamic pageDataRaw = getPageData(pageNumber);

      if (pageDataRaw == null) {
        return "غير معروف";
      }

      final Map<String, dynamic> pageData;
      if (pageDataRaw is Map<String, dynamic>) {
        pageData = pageDataRaw;
      } else if (pageDataRaw is Map) {
        pageData = Map<String, dynamic>.from(pageDataRaw);
      } else {
        return "غير معروف";
      }

      final int surahNumber = _getSurahNumberFromPageData(pageData);
      final int verseNumber = _getVerseNumberFromPageData(pageData);

      if (surahNumber <= 0 || verseNumber <= 0) {
        return "غير معروف";
      }

      final int juzNumber = getJuzNumber(surahNumber, verseNumber);
      return "الجزء $juzNumber";
    } catch (e) {
      return "غير معروف";
    }
  }

  /// Helper function → পৃষ্ঠা অনুযায়ী সূরা ধরন (মাক্কি/মাদানি) দেখায়
  String _getSurahTypeForPage(int pageNumber) {
    try {
      final dynamic pageDataRaw = getPageData(pageNumber);

      if (pageDataRaw == null) {
        return "غير معروف";
      }

      final Map<String, dynamic> pageData;
      if (pageDataRaw is Map<String, dynamic>) {
        pageData = pageDataRaw;
      } else if (pageDataRaw is Map) {
        pageData = Map<String, dynamic>.from(pageDataRaw);
      } else {
        return "غير معروف";
      }

      final dynamic surahRawCandidate = pageData.containsKey('surah')
          ? pageData['surah']
          : pageData.containsKey('sura')
              ? pageData['sura']
              : pageData.containsKey('surahNumber')
                  ? pageData['surahNumber']
                  : pageData.containsKey('suraNumber')
                      ? pageData['suraNumber']
                      : null;

      int surahNumber = 0;
      if (surahRawCandidate != null) {
        final dynamic surahRaw = surahRawCandidate;
        if (surahRaw is int) {
          surahNumber = surahRaw;
        } else if (surahRaw is double) {
          surahNumber = surahRaw.toInt();
        } else if (surahRaw is String) {
          surahNumber = int.tryParse(surahRaw) ?? 0;
        } else {
          surahNumber = 0;
        }
      }

      if (surahNumber <= 0) {
        return "غير معروف";
      }

      // সহজীকৃত পদ্ধতি - আপনাকে হয়তো আপনার লাইব্রেরি অনুযায়ী এটি সামঞ্জস্য করতে হতে পারে
      if (surahNumber <= 5 || (surahNumber >= 9 && surahNumber <= 113)) {
        return "مدنية";
      } else {
        return "مكية";
      }
    } catch (e) {
      return "غير معروف";
    }
  }

  /// Helper function to extract surah number from page data
  int _getSurahNumberFromPageData(Map<String, dynamic> pageData) {
    final dynamic surahRawCandidate = pageData.containsKey('surah')
        ? pageData['surah']
        : pageData.containsKey('sura')
            ? pageData['sura']
            : pageData.containsKey('surahNumber')
                ? pageData['surahNumber']
                : pageData.containsKey('suraNumber')
                    ? pageData['suraNumber']
                    : null;

    int surahNumber = 0;
    if (surahRawCandidate != null) {
      if (surahRawCandidate is int) {
        surahNumber = surahRawCandidate;
      } else if (surahRawCandidate is double) {
        surahNumber = surahRawCandidate.toInt();
      } else if (surahRawCandidate is String) {
        surahNumber = int.tryParse(surahRawCandidate) ?? 0;
      }
    }
    return surahNumber;
  }

  /// Helper function to extract verse number from page data
  int _getVerseNumberFromPageData(Map<String, dynamic> pageData) {
    final dynamic verseRawCandidate = pageData.containsKey('verse')
        ? pageData['verse']
        : pageData.containsKey('verseNumber')
            ? pageData['verseNumber']
            : null;

    int verseNumber = 0;
    if (verseRawCandidate != null) {
      if (verseRawCandidate is int) {
        verseNumber = verseRawCandidate;
      } else if (verseRawCandidate is double) {
        verseNumber = verseRawCandidate.toInt();
      } else if (verseRawCandidate is String) {
        verseNumber = int.tryParse(verseRawCandidate) ?? 0;
      }
    }
    return verseNumber;
  }

  /// Page Jump dialog
  void _showPageJumpDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "الانتقال إلى الصفحة",
          style: GoogleFonts.amiri(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "أدخل رقم الصفحة (1–$totalPagesCount)",
            hintStyle: GoogleFonts.amiri(fontSize: 14.sp),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "إلغاء",
              style: GoogleFonts.amiri(fontSize: 16.sp),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E5F3F),
            ),
            onPressed: () {
              final page = int.tryParse(controller.text.trim());
              if (page != null && page > 0 && page <= totalPagesCount) {
                _pageController.jumpToPage(page - 1);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "رقم الصفحة غير صالح!",
                      style: GoogleFonts.amiri(fontSize: 14.sp),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              "اذهب",
              style: GoogleFonts.amiri(
                fontSize: 16.sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookmarks(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "المرجعيات",
          style: GoogleFonts.amiri(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          height: 200.h,
          child: Center(
            child: Text(
              "لا توجد مرجعيات محفوظة حالياً",
              style: GoogleFonts.amiri(fontSize: 16.sp),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "إغلاق",
              style: GoogleFonts.amiri(fontSize: 16.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _showSurahList(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "قائمة السور",
          style: GoogleFonts.amiri(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          height: 400.h,
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: totalSurahCount,
            itemBuilder: (context, index) {
              final surahNumber = index + 1;
              final surahName = getSurahNameArabic(surahNumber);
              return ListTile(
                title: Text(
                  "$surahName ($surahNumber)",
                  style: GoogleFonts.amiri(fontSize: 16.sp),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "إغلاق",
              style: GoogleFonts.amiri(fontSize: 16.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "الإعدادات",
          style: GoogleFonts.amiri(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                "حجم الخط",
                style: GoogleFonts.amiri(fontSize: 16.sp),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(
                "وضع القراءة",
                style: GoogleFonts.amiri(fontSize: 16.sp),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "إغلاق",
              style: GoogleFonts.amiri(fontSize: 16.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "حول التطبيق",
          style: GoogleFonts.amiri(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "تطبيق قراءة القرآن الكريم",
              style: GoogleFonts.amiri(fontSize: 16.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              "الإصدار: 1.0.0",
              style: GoogleFonts.amiri(fontSize: 14.sp),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "إغلاق",
              style: GoogleFonts.amiri(fontSize: 16.sp),
            ),
          ),
        ],
      ),
    );
  }
}
