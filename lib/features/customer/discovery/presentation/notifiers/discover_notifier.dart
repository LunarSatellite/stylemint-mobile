import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'discover_notifier.freezed.dart';

@freezed
abstract class DiscoverState with _$DiscoverState {
  const DiscoverState._();

  const factory DiscoverState.initial() = _Initial;
  const factory DiscoverState.loadInProgress() = _LoadInProgress;
  const factory DiscoverState.loadSuccess(DiscoverData data) = _LoadSuccess;
  const factory DiscoverState.loadFailure(NetworkExceptions failure) = _LoadFailure;
}

class DiscoverNotifier extends StateNotifier<DiscoverState> {
  DiscoverNotifier(this._repository) : super(const DiscoverState.initial()) {
    unawaited(fetchDiscover());
  }

  final DiscoveryRepository _repository;

  Future<void> fetchDiscover() async {
    state = const DiscoverState.loadInProgress();
    final either = await _repository.getDiscoverData();
    state = either.fold(
      (_) => DiscoverState.loadSuccess(_mockData()),
      (_) => DiscoverState.loadSuccess(_mockData()),
    );
  }

  static DiscoverData _mockData() => DiscoverData(
        popularSearches: const [
          '#SneakersAirJordan',
          '#BeautyHaul',
          '#WinterFashion',
          '#Fitness',
        ],
        categories: const [
          DiscoverCategory(id: 'fashion', label: 'Fashion', emoji: '👗'),
          DiscoverCategory(id: 'footwear', label: 'Footwear', emoji: '👟'),
          DiscoverCategory(id: 'tech', label: 'Tech', emoji: '💻'),
          DiscoverCategory(id: 'home', label: 'Home', emoji: '🏠'),
          DiscoverCategory(id: 'accessories', label: 'Accessories', emoji: '💍'),
          DiscoverCategory(id: 'fitness', label: 'Fitness', emoji: '💪'),
          DiscoverCategory(id: 'gaming', label: 'Gaming', emoji: '🎮'),
          DiscoverCategory(id: 'food', label: 'Food', emoji: '🍕'),
          DiscoverCategory(id: 'outdoors', label: 'Outdoors', emoji: '🏔️'),
          DiscoverCategory(id: 'pets', label: 'Pets', emoji: '🐾'),
          DiscoverCategory(id: 'books', label: 'Books', emoji: '📚'),
          DiscoverCategory(id: 'travel', label: 'Travel', emoji: '✈️'),
          DiscoverCategory(id: 'wellness', label: 'Wellness', emoji: '🧘'),
          DiscoverCategory(id: 'sports', label: 'Sports', emoji: '⚽'),
          DiscoverCategory(id: 'beauty', label: 'Beauty', emoji: '💄'),
          DiscoverCategory(id: 'electronics', label: 'Electronics', emoji: '🔌'),
          DiscoverCategory(id: 'music', label: 'Music', emoji: '🎵'),
          DiscoverCategory(id: 'art', label: 'Art', emoji: '🎨'),
          DiscoverCategory(id: 'kids', label: 'Kids', emoji: '👶'),
          DiscoverCategory(id: 'movies', label: 'Movies', emoji: '🎬'),
          DiscoverCategory(id: 'automotive', label: 'Automotive', emoji: '🚗'),
          DiscoverCategory(id: 'jewellery', label: 'Jewellery', emoji: '💎'),
        ],
        trending: [
          TrendingProduct(
            id: 'mock-t1',
            name: 'MetaQuest 3 Pro 2026 VR Headset',
            imageUrl: '',
            price: const Money(amount: 135000, currency: 'NPR'),
            rating: 4.4,
            soldToday: 156,
          ),
          TrendingProduct(
            id: 'mock-t2',
            name: 'Cera Ve Alpine Apple Berry Foaming Face Wash',
            imageUrl: '',
            price: const Money(amount: 5000, currency: 'NPR'),
            rating: 5.0,
            soldToday: 1500,
          ),
        ],
        topCreators: [
          DiscoverCreator(
            id: 'mock-cr1',
            name: 'Shree Teen',
            handle: '@alieen.ace43',
            avatarUrl: '',
            category: 'Travel & Skincare',
            description:
                'Get Personalized recommendations from creators in Fashion, Beauty, and Fitness',
            rating: 4.9,
            followers: 52300,
            isFollowing: false,
          ),
          DiscoverCreator(
            id: 'mock-cr2',
            name: 'Immovable Royale',
            handle: '@immovableroyale',
            avatarUrl: '',
            category: 'Beauty, Skincare, Fashion & Wellness',
            description:
                'Get Personalized recommendations from creators in Fashion, Beauty, and Fitness',
            rating: 4.0,
            followers: 101000,
            isFollowing: true,
          ),
        ],
      );
}
