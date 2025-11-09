import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qcf_quran/qcf_quran.dart';

class QuranHomePage extends StatefulWidget {
  const QuranHomePage({super.key});

  @override
  State<QuranHomePage> createState() => _QuranHomePageState();
}

class _QuranHomePageState extends State<QuranHomePage> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() => _currentPage = page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Quran - Page ${_currentPage + 1}",
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showPageJumpDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // পুরো কুরআনের পৃষ্ঠা দেখানো হবে
          PageviewQuran(
            controller: _pageController,
            sp: 1.2.sp,
            h: 1.1.h,
          ),

          // নিচে পৃষ্ঠা ও সূরা তথ্য
          Positioned(
            bottom: 10.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  _getSurahInfoForPage(_currentPage + 1),
                  style: TextStyle(color: Colors.white, fontSize: 13.sp),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper function → পৃষ্ঠা অনুযায়ী সূরা নাম দেখায়
  /// Safe handling added for different possible shapes of pageData and surah value.
  String _getSurahInfoForPage(int pageNumber) {
    try {
      // getPageData might return Map or dynamic — handle safely
      final dynamic pageDataRaw = getPageData(pageNumber);

      if (pageDataRaw == null) {
        return "Page $pageNumber";
      }

      // ensure we have a Map-like object
      final Map<String, dynamic> pageData;
      if (pageDataRaw is Map<String, dynamic>) {
        pageData = pageDataRaw;
      } else if (pageDataRaw is Map) {
        // convert to Map<String, dynamic> if possible
        pageData = Map<String, dynamic>.from(pageDataRaw);
      } else {
        // unexpected type
        return "Page $pageNumber";
      }

      // try multiple likely keys for surah number (some libs use different keys)
      final dynamic surahRawCandidate = pageData.containsKey('surah')
          ? pageData['surah']
          : pageData.containsKey('sura')
              ? pageData['sura']
              : pageData.containsKey('surahNumber')
                  ? pageData['surahNumber']
                  : pageData.containsKey('suraNumber')
                      ? pageData['suraNumber']
                      : null;

      // If still null, fallback to getSurahByPage if available
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
          // unknown type -> leave 0
          surahNumber = 0;
        }
      }

      if (surahNumber <= 0) {
        return "Page $pageNumber";
      }

      // getSurahNameArabic / getSurahNameEnglish expect int arg
      final String nameArabic = getSurahNameArabic(surahNumber);
      final String nameEnglish = getSurahNameEnglish(surahNumber);

      return "Page $pageNumber • Surah $nameArabic ($nameEnglish)";
    } catch (e) {
      // any unexpected error -> fail-safe
      return "Page $pageNumber";
    }
  }

  /// Page Jump dialog
  void _showPageJumpDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Go to Page"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: "Enter page number (1–604)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text.trim());
              if (page != null && page > 0 && page <= totalPagesCount) {
                _pageController.jumpToPage(page - 1);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Invalid page number!"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Go"),
          ),
        ],
      ),
    );
  }
}
