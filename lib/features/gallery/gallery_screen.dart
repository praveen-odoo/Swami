import 'package:flutter/material.dart';

import '../../core/data/sample_data.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isHindi = context.isHindi;
    final images = SampleData.gallery;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('gallery'))),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.92,
        ),
        itemCount: images.length,
        itemBuilder: (context, i) {
          final img = images[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => _GalleryViewer(initialIndex: i))),
            child: Hero(
              tag: img.url,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppColors.gold.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.maroon.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(url: img.url),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.maroonDark
                            ],
                          ),
                        ),
                        child: Text(
                          isHindi ? img.captionHi : img.captionEn,
                          style: const TextStyle(
                              color: AppColors.onDark,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GalleryViewer extends StatefulWidget {
  const _GalleryViewer({required this.initialIndex});

  final int initialIndex;

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = context.isHindi;
    final images = SampleData.gallery;
    final caption =
        isHindi ? images[_index].captionHi : images[_index].captionEn;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(caption),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: images.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
          maxScale: 4,
          child: Hero(
            tag: images[i].url,
            child: Center(
              child: AppNetworkImage(
                  url: images[i].url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
