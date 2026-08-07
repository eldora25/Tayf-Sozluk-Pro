import 'package:flutter/material.dart';

class SlideGradientTransform extends GradientTransform {
  final double percent;
  const SlideGradientTransform({required this.percent});
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (percent * 2 - 1), 0, 0);
  }
}

class PremiumShimmerLoading extends StatefulWidget {
  final String loadingText;
  const PremiumShimmerLoading({super.key, required this.loadingText});

  @override
  State<PremiumShimmerLoading> createState() => _PremiumShimmerLoadingState();
}

class _PremiumShimmerLoadingState extends State<PremiumShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color baseColor = isDark ? Colors.white24 : Colors.black12;
    Color highlightColor = isDark ? Colors.white54 : Colors.black26;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: [baseColor, highlightColor, baseColor],
                        stops: const [0.1, 0.5, 0.9],
                        begin: const Alignment(-1.0, -0.3),
                        end: const Alignment(1.0, 0.3),
                        transform: SlideGradientTransform(percent: _shimmerController.value),
                      ).createShader(bounds);
                    },
                    child: child,
                  );
                },
                child: _buildSkeletonLayout(context, baseColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Column(
                children: [
                  CircularProgressIndicator(color: Theme.of(context).primaryColor, strokeWidth: 3),
                  const SizedBox(height: 16),
                  Text(
                    widget.loadingText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      height: 1.5,
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

  Widget _buildSkeletonLayout(BuildContext context, Color baseColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 150, height: 24, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(12)))),
              const SizedBox(height: 8),
              Container(width: 100, height: 16, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(8)))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) => Container(width: 80, height: 40, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(20))))),
        ),
        const Spacer(),
        Center(
          child: Container(
            width: 290,
            // YENİ: Sabit yükseklik yerine dinamik ekran oranı kullanılarak Overflow hatası engellendi
            height: MediaQuery.of(context).size.height * 0.45, 
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(height: 40, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
                const Spacer(),
                Container(width: 180, height: 40, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(20)))),
                const SizedBox(height: 20),
                Container(width: 220, height: 20, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(10)))),
                const SizedBox(height: 10),
                Container(width: 160, height: 20, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(10)))),
                const Spacer(),
              ],
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: Container(height: 50, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(25))))),
              const SizedBox(width: 12),
              Container(width: 55, height: 55, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 50, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(25))))),
            ],
          ),
        )
      ],
    );
  }
}
