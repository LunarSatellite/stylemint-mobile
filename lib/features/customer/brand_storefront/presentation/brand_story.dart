import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/domain/entities/public_brand_profile.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

/// Longest pull quote before it is shortened at a word boundary.
const int brandPullQuoteMaxLength = 160;

final RegExp _sentenceEnd = RegExp(r'(?<=[.!?])\s+');
final RegExp _whitespace = RegExp(r'\s+');

/// The first sentence of [story], shortened to [brandPullQuoteMaxLength]
/// characters at a word boundary.
String brandPullQuote(String story) {
  final text = story.trim().replaceAll(_whitespace, ' ');
  final first = text.split(_sentenceEnd).first.trim();
  if (first.length <= brandPullQuoteMaxLength) return first;
  final cut = first.substring(0, brandPullQuoteMaxLength);
  final lastSpace = cut.lastIndexOf(' ');
  return '${(lastSpace > 60 ? cut.substring(0, lastSpace) : cut).trimRight()}…';
}

/// What follows the pull quote in [story], or null when the quote is the
/// whole story. A shortened quote keeps the full story as the body.
String? brandStoryBody(String story) {
  final text = story.trim();
  final quote = brandPullQuote(text);
  if (quote.endsWith('…')) return text;
  final normalized = text.replaceAll(_whitespace, ' ');
  if (!normalized.startsWith(quote)) return text;
  final rest = normalized.substring(quote.length).trim();
  if (rest.isEmpty) return null;
  // Keep the author's paragraph breaks in the rest of the story.
  final breakAt = text.indexOf(RegExp(r'(?<=[.!?])\s+'));
  return breakAt < 0 ? rest : text.substring(breakAt).trim();
}

/// Trust points for a brand, honest about what StyleMint has checked.
List<MallTrustItem> brandTrustItems(PublicBrandProfile brand) => [
  const MallTrustItem(
    icon: Icons.verified_outlined,
    title: 'Authentic products',
    body: 'Listed by the brand itself',
  ),
  MallTrustItem(
    icon: Icons.storefront_outlined,
    title: brand.isVerified ? 'Verified seller' : 'Approved seller',
    body: brand.isVerified
        ? 'Verified by StyleMint'
        : 'Reviewed and approved by StyleMint',
  ),
  const MallTrustItem(
    icon: Icons.lock_outline_rounded,
    title: 'Secure checkout',
    body: 'Card, PayPal, eSewa or cash on delivery',
  ),
  const MallTrustItem(
    icon: Icons.assignment_return_outlined,
    title: 'Easy returns',
    body: 'Simple returns on eligible orders',
  ),
];
