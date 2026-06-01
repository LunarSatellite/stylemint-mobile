import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ProductImageCarousel extends StatefulWidget {
  const ProductImageCarousel({required this.images, super.key});

  final List<String> images;

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: 320,
        color: DesignTokens.bgAppBodyLight,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: DesignTokens.iconLight,
            size: DesignTokens.iconXLarge,
          ),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 360,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: widget.images.length,
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: widget.images[i],
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, _) => const ColoredBox(
                color: DesignTokens.bgAppBodyLight,
              ),
              errorWidget: (_, _, _) => const ColoredBox(
                color: DesignTokens.bgAppBodyLight,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: DesignTokens.iconLight,
                ),
              ),
            ),
          ),
        ),
        if (widget.images.length > 1)
          Positioned(
            bottom: DesignTokens.s12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s4,
                  ),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? DesignTokens.primaryGreen
                            : DesignTokens.textWhite.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
