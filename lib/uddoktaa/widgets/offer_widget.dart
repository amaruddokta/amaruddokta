import 'dart:async';
import 'package:flutter/material.dart';

class OfferWidget extends StatefulWidget {
  final Map<String, dynamic> offer;
  final int remainingMinutes;
  final VoidCallback onTap;
  const OfferWidget({
    super.key,
    required this.offer,
    required this.remainingMinutes,
    required this.onTap,
  });

  @override
  _OfferWidgetState createState() => _OfferWidgetState();
}

class _OfferWidgetState extends State<OfferWidget> {
  late int totalSeconds;
  late Timer timer;
  bool _isActive = true; // ট্র্যাক করবে অফারটি এখনও সক্রিয় আছে কিনা

  @override
  void initState() {
    super.initState();
    // মিনিট থেকে মোট সেকেন্ডে রূপান্তর
    totalSeconds = widget.remainingMinutes * 60;

    // যদি ইতিমধ্যেই সময় শেষ হয়ে যায়
    if (totalSeconds <= 0) {
      _isActive = false;
      return;
    }

    // প্রতি সেকেন্ডে টাইমার আপডেট
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (totalSeconds > 0) {
        setState(() {
          totalSeconds--;
        });
      } else {
        // সময় শেষ হলে
        setState(() {
          _isActive = false;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  // সেকেন্ড থেকে ঘন্টা, মিনিট, সেকেন্ড বের করার মেথড
  Map<String, int> _formatTime() {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;

    return {
      'hours': hours,
      'minutes': minutes,
      'seconds': seconds,
    };
  }

  // ডিসকাউন্টের পর মূল্য হিসাব করার মেথড
  double _calculateDiscountedPrice() {
    // অরিজিনাল প্রাইস নেওয়া
    double originalPrice =
        (widget.offer['originalPrice'] ?? widget.offer['price'] ?? 0)
            .toDouble();
    // ডিসকাউন্ট মান নেওয়া
    double discountPercentage =
        (widget.offer['discountPercentage'] ?? widget.offer['discount'] ?? 0)
            .toDouble();
    // ডিসকাউন্ট মান ভ্যালিডেশন
    if (discountPercentage <= 0) {
      return originalPrice;
    }
    if (discountPercentage > 100) {
      discountPercentage = 100;
    }
    // ডিসকাউন্টের পর মূল্য হিসাব
    return originalPrice * (100 - discountPercentage) / 100;
  }

  @override
  Widget build(BuildContext context) {
    // যদি অফারটি আর সক্রিয় না থাকে, তাহলে কিছুই দেখাবে না
    if (!_isActive) {
      return const SizedBox.shrink(); // খালি উইজেট রিটার্ন করবে
    }

    // ডিসকাউন্টের পর মূল্য হিসাব করা
    double discountedPrice = _calculateDiscountedPrice();
    // অরিজিনাল প্রাইস এবং ডিসকাউন্ট মান নেওয়া
    double originalPrice =
        (widget.offer['originalPrice'] ?? widget.offer['price'] ?? 0)
            .toDouble();
    // ডিসকাউন্ট মান নেওয়া
    double discountPercentage =
        (widget.offer['discountPercentage'] ?? widget.offer['discount'] ?? 0)
            .toDouble();
    // ডিসকাউন্ট আছে কিনা চেক করা
    bool hasDiscount = discountPercentage > 0;

    // ঘন্টা, মিনিট, সেকেন্ড বের করা
    final time = _formatTime();
    final hours = time['hours']!;
    final minutes = time['minutes']!;
    final seconds = time['seconds']!;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 5.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5.0),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  bottomLeft: Radius.circular(8.0),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      widget.offer['imageUrl'] ?? '',
                      height: 150,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          width: 120,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image,
                              size: 30, color: Colors.grey),
                        );
                      },
                    ),
                    // ডিসকাউন্ট ব্যাজ
                    if (hasDiscount)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${discountPercentage.toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Content section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Offer name
                      Text(
                        widget.offer['name'] ?? 'Special Offer',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Price section
                      Row(
                        children: [
                          // Current price (discounted price)
                          Text(
                            '৳${discountedPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Original price with strikethrough if discount available
                          if (hasDiscount)
                            Expanded(
                              child: Text(
                                '৳${originalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Offer details
                      Text(
                        widget.offer['details'] ?? 'Limited time offer!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // লাইভ টাইমার সেকশন
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // পালসিং টাইমার আইকন
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.8, end: 1.0),
                              duration: const Duration(milliseconds: 1000),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: const Icon(
                                Icons.timer,
                                size: 14,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // কমপ্যাক্ট টেক্সট লেআউট
                            Flexible(
                              child: Row(
                                children: [
                                  // ঘন্টা ডিসপ্লে
                                  if (hours > 0)
                                    Row(
                                      children: [
                                        AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 500),
                                          transitionBuilder:
                                              (child, animation) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                          child: Text(
                                            '$hours',
                                            key: ValueKey<int>(hours),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Text(
                                          'h ',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  // মিনিট ডিসপ্লে
                                  Row(
                                    children: [
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 500),
                                        transitionBuilder: (child, animation) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },
                                        child: Text(
                                          '$minutes',
                                          key: ValueKey<int>(minutes),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        'm ',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // সেকেন্ড ডিসপ্লে
                                  Row(
                                    children: [
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 500),
                                        transitionBuilder: (child, animation) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },
                                        child: Text(
                                          '$seconds',
                                          key: ValueKey<int>(seconds),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        's',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
