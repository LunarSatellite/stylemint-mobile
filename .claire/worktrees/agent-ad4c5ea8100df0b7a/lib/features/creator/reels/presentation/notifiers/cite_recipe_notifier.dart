import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/repositories/creator_reels_repository.dart';

/// State for cite-recipe action on a single reel.
sealed class CiteRecipeState {
  const CiteRecipeState();
}

class CiteRecipeIdle extends CiteRecipeState {
  const CiteRecipeIdle({this.isCited = false});
  final bool isCited;
}

class CiteRecipeLoading extends CiteRecipeState {
  const CiteRecipeLoading();
}

class CiteRecipeSuccess extends CiteRecipeState {
  const CiteRecipeSuccess({required this.isCited});
  final bool isCited;
}

class CiteRecipeFailure extends CiteRecipeState {
  const CiteRecipeFailure(this.failure);
  final NetworkExceptions failure;
}

class CiteRecipeNotifier extends StateNotifier<CiteRecipeState> {
  CiteRecipeNotifier(this._repository, {bool initialCited = false})
    : super(CiteRecipeIdle(isCited: initialCited));

  final CreatorReelsRepository _repository;

  Future<void> cite(String reelId, String recipeId) async {
    state = const CiteRecipeLoading();
    final result = await _repository.citeRecipe(
      reelId: reelId,
      recipeId: recipeId,
    );
    state = result.fold(
      (failure) => CiteRecipeFailure(failure),
      (_) => const CiteRecipeSuccess(isCited: true),
    );
  }

  Future<void> removeCite(String reelId) async {
    state = const CiteRecipeLoading();
    final result = await _repository.removeCiteRecipe(reelId: reelId);
    state = result.fold(
      (failure) => CiteRecipeFailure(failure),
      (_) => const CiteRecipeSuccess(isCited: false),
    );
  }
}
