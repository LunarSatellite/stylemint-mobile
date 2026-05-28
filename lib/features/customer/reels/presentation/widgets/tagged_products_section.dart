import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Tagged products section showing products from the reel
/// Displays product image, name, price, and add to cart button
class TaggedProductsSection extends StatelessWidget {
  final List<TaggedProduct> products;

  const TaggedProductsSection({
    Key? key,
    required this.products,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          return _ProductCard(product: product);
        },
      ),
    );
  }
}

/// Individual product card in the tagged products section
class _ProductCard extends StatelessWidget {
  final TaggedProduct product;

  const _ProductCard({required this.product});

  void _addToCart() {
    // TODO: Call domain use case to add to cart
  }

  void _viewProduct() {
    // TODO: Navigate to product detail screen
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _viewProduct,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  color: Colors.grey[300],
                ),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[600],
                        ),
                      ),
              ),
            ),

            // Product info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product name
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Price
                  Text(
                    'Rs ${product.price.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Add to cart button
                  GestureDetector(
                    onTap: _addToCart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Add to Cart',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
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
}

/// Tagged product model - represents a product shown in reel
class TaggedProduct {
  final String id;
  final String name;
  final String imageUrl;
  final Money price;

  const TaggedProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
  });
}
