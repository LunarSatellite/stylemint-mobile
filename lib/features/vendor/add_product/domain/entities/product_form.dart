import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// A selectable catalog category (real backend taxonomy).
class CategoryOption {
  const CategoryOption({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is CategoryOption && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

class BasicInfo {
  const BasicInfo({
    required this.productName,
    required this.shortDescription,
    required this.description,
    required this.categoryId,
    required this.categories,
    this.brand,
    required this.tags,
  });

  final String productName;

  /// One-line summary -> backend StartDraft/Step-1 `shortDescription`.
  final String shortDescription;

  /// Full description -> backend `longDescriptionMarkdown`.
  final String description;

  /// Real catalog category Guid (from GET /v1/public/categories) -> backend
  /// `categoryId`. The backend models a single category per product.
  final String categoryId;

  /// Display labels of the picked category/categories (UI-only; backend takes
  /// the single [categoryId]). Kept for chip rendering.
  final List<String> categories;
  final String? brand;
  final List<String> tags;

  BasicInfo copyWith({
    String? productName,
    String? shortDescription,
    String? description,
    String? categoryId,
    List<String>? categories,
    String? brand,
    List<String>? tags,
  }) {
    return BasicInfo(
      productName: productName ?? this.productName,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categories: categories ?? this.categories,
      brand: brand ?? this.brand,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BasicInfo &&
      other.productName == productName &&
      other.shortDescription == shortDescription &&
      other.description == description &&
      other.categoryId == categoryId &&
      _listEquals(other.categories, categories) &&
      other.brand == brand &&
      _listEquals(other.tags, tags);

  @override
  int get hashCode => Object.hash(
        productName,
        shortDescription,
        description,
        categoryId,
        Object.hashAll(categories),
        brand,
        Object.hashAll(tags),
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class ImagesInfo {
  const ImagesInfo({
    required this.images,
    required this.primaryImageIndex,
  });

  final List<String> images;
  final int primaryImageIndex;

  ImagesInfo copyWith({
    List<String>? images,
    int? primaryImageIndex,
  }) {
    return ImagesInfo(
      images: images ?? this.images,
      primaryImageIndex: primaryImageIndex ?? this.primaryImageIndex,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ImagesInfo &&
      _listEquals(other.images, images) &&
      other.primaryImageIndex == primaryImageIndex;

  @override
  int get hashCode => Object.hash(Object.hashAll(images), primaryImageIndex);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class PricingInfo {
  const PricingInfo({
    required this.basePrice,
    this.compareAtPrice,
    this.costPerItem,
    required this.taxRate,
    required this.discountEnabled,
    this.discountPercent,
    this.sku = '',
    this.quantityOnHand = 0,
    this.trackInventory = true,
    this.allowOverselling = false,
    this.productKind = 1,
    this.billingCadence = 1,
  });

  final Money basePrice;
  final Money? compareAtPrice;
  final Money? costPerItem;
  final double taxRate;
  final bool discountEnabled;
  final double? discountPercent;

  // --- Backend Step-3 fields (catalog PatchStep3Vm) ---
  /// Stock keeping unit -> backend `sku`.
  final String sku;

  /// Available stock -> backend `quantityOnHand`.
  final int quantityOnHand;

  /// -> backend `trackInventory`.
  final bool trackInventory;

  /// -> backend `allowOverselling`.
  final bool allowOverselling;

  /// catalog ProductKind enum int (1=Physical,2=Digital,3=Service,
  /// 4=Subscription,5=Bundle) -> backend `productKind`.
  final int productKind;

  /// catalog BillingCadence enum int (1=OneTime,2=Weekly,3=Monthly,
  /// 4=Quarterly,5=Annual) -> backend `billingCadence`.
  final int billingCadence;

  PricingInfo copyWith({
    Money? basePrice,
    Money? compareAtPrice,
    Money? costPerItem,
    double? taxRate,
    bool? discountEnabled,
    double? discountPercent,
    String? sku,
    int? quantityOnHand,
    bool? trackInventory,
    bool? allowOverselling,
    int? productKind,
    int? billingCadence,
  }) {
    return PricingInfo(
      basePrice: basePrice ?? this.basePrice,
      compareAtPrice: compareAtPrice ?? this.compareAtPrice,
      costPerItem: costPerItem ?? this.costPerItem,
      taxRate: taxRate ?? this.taxRate,
      discountEnabled: discountEnabled ?? this.discountEnabled,
      discountPercent: discountPercent ?? this.discountPercent,
      sku: sku ?? this.sku,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      trackInventory: trackInventory ?? this.trackInventory,
      allowOverselling: allowOverselling ?? this.allowOverselling,
      productKind: productKind ?? this.productKind,
      billingCadence: billingCadence ?? this.billingCadence,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PricingInfo &&
      other.basePrice == basePrice &&
      other.compareAtPrice == compareAtPrice &&
      other.costPerItem == costPerItem &&
      other.taxRate == taxRate &&
      other.discountEnabled == discountEnabled &&
      other.discountPercent == discountPercent &&
      other.sku == sku &&
      other.quantityOnHand == quantityOnHand &&
      other.trackInventory == trackInventory &&
      other.allowOverselling == allowOverselling &&
      other.productKind == productKind &&
      other.billingCadence == billingCadence;

  @override
  int get hashCode => Object.hash(
        basePrice,
        compareAtPrice,
        costPerItem,
        taxRate,
        discountEnabled,
        discountPercent,
        sku,
        quantityOnHand,
        trackInventory,
        allowOverselling,
        productKind,
        billingCadence,
      );
}

class ShippingInfo {
  const ShippingInfo({
    required this.weight,
    required this.weightUnit,
    required this.dimensionsLength,
    required this.dimensionsWidth,
    required this.dimensionsHeight,
    required this.requiresShipping,
    this.shippingFee,
    this.freeShippingOver,
    required this.deliveryEstimateMin,
    required this.deliveryEstimateMax,
  });

  final double weight;
  final String weightUnit;
  final double dimensionsLength;
  final double dimensionsWidth;
  final double dimensionsHeight;
  final bool requiresShipping;
  final Money? shippingFee;
  final Money? freeShippingOver;
  final int deliveryEstimateMin;
  final int deliveryEstimateMax;

  ShippingInfo copyWith({
    double? weight,
    String? weightUnit,
    double? dimensionsLength,
    double? dimensionsWidth,
    double? dimensionsHeight,
    bool? requiresShipping,
    Money? shippingFee,
    Money? freeShippingOver,
    int? deliveryEstimateMin,
    int? deliveryEstimateMax,
  }) {
    return ShippingInfo(
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      dimensionsLength: dimensionsLength ?? this.dimensionsLength,
      dimensionsWidth: dimensionsWidth ?? this.dimensionsWidth,
      dimensionsHeight: dimensionsHeight ?? this.dimensionsHeight,
      requiresShipping: requiresShipping ?? this.requiresShipping,
      shippingFee: shippingFee ?? this.shippingFee,
      freeShippingOver: freeShippingOver ?? this.freeShippingOver,
      deliveryEstimateMin: deliveryEstimateMin ?? this.deliveryEstimateMin,
      deliveryEstimateMax: deliveryEstimateMax ?? this.deliveryEstimateMax,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ShippingInfo &&
      other.weight == weight &&
      other.weightUnit == weightUnit &&
      other.dimensionsLength == dimensionsLength &&
      other.dimensionsWidth == dimensionsWidth &&
      other.dimensionsHeight == dimensionsHeight &&
      other.requiresShipping == requiresShipping &&
      other.shippingFee == shippingFee &&
      other.freeShippingOver == freeShippingOver &&
      other.deliveryEstimateMin == deliveryEstimateMin &&
      other.deliveryEstimateMax == deliveryEstimateMax;

  @override
  int get hashCode => Object.hash(
        weight,
        weightUnit,
        dimensionsLength,
        dimensionsWidth,
        dimensionsHeight,
        requiresShipping,
        shippingFee,
        freeShippingOver,
        deliveryEstimateMin,
        deliveryEstimateMax,
      );
}

class ReviewInfo {
  const ReviewInfo({
    required this.basicInfo,
    required this.imagesInfo,
    required this.pricingInfo,
    required this.shippingInfo,
  });

  final BasicInfo basicInfo;
  final ImagesInfo imagesInfo;
  final PricingInfo pricingInfo;
  final ShippingInfo shippingInfo;

  ReviewInfo copyWith({
    BasicInfo? basicInfo,
    ImagesInfo? imagesInfo,
    PricingInfo? pricingInfo,
    ShippingInfo? shippingInfo,
  }) {
    return ReviewInfo(
      basicInfo: basicInfo ?? this.basicInfo,
      imagesInfo: imagesInfo ?? this.imagesInfo,
      pricingInfo: pricingInfo ?? this.pricingInfo,
      shippingInfo: shippingInfo ?? this.shippingInfo,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReviewInfo &&
      other.basicInfo == basicInfo &&
      other.imagesInfo == imagesInfo &&
      other.pricingInfo == pricingInfo &&
      other.shippingInfo == shippingInfo;

  @override
  int get hashCode => Object.hash(basicInfo, imagesInfo, pricingInfo, shippingInfo);
}

class ProductDraft {
  const ProductDraft({
    required this.id,
    required this.basicInfo,
    required this.imagesInfo,
    required this.pricingInfo,
    required this.shippingInfo,
    required this.status,
  });

  final String id;
  final BasicInfo basicInfo;
  final ImagesInfo imagesInfo;
  final PricingInfo pricingInfo;
  final ShippingInfo shippingInfo;
  final String status;

  ProductDraft copyWith({
    String? id,
    BasicInfo? basicInfo,
    ImagesInfo? imagesInfo,
    PricingInfo? pricingInfo,
    ShippingInfo? shippingInfo,
    String? status,
  }) {
    return ProductDraft(
      id: id ?? this.id,
      basicInfo: basicInfo ?? this.basicInfo,
      imagesInfo: imagesInfo ?? this.imagesInfo,
      pricingInfo: pricingInfo ?? this.pricingInfo,
      shippingInfo: shippingInfo ?? this.shippingInfo,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProductDraft &&
      other.id == id &&
      other.basicInfo == basicInfo &&
      other.imagesInfo == imagesInfo &&
      other.pricingInfo == pricingInfo &&
      other.shippingInfo == shippingInfo &&
      other.status == status;

  @override
  int get hashCode => Object.hash(
        id,
        basicInfo,
        imagesInfo,
        pricingInfo,
        shippingInfo,
        status,
      );
}

class ProductFormState {
  const ProductFormState({
    required this.currentStep,
    this.step1,
    this.step2,
    this.step3,
    this.step4,
    this.step5,
  });

  final int currentStep;
  final BasicInfo? step1;
  final ImagesInfo? step2;
  final PricingInfo? step3;
  final ShippingInfo? step4;
  final ReviewInfo? step5;

  ProductFormState copyWith({
    int? currentStep,
    BasicInfo? step1,
    ImagesInfo? step2,
    PricingInfo? step3,
    ShippingInfo? step4,
    ReviewInfo? step5,
  }) {
    return ProductFormState(
      currentStep: currentStep ?? this.currentStep,
      step1: step1 ?? this.step1,
      step2: step2 ?? this.step2,
      step3: step3 ?? this.step3,
      step4: step4 ?? this.step4,
      step5: step5 ?? this.step5,
    );
  }

  bool get isStep1Valid =>
      step1 != null &&
      step1!.productName.isNotEmpty &&
      step1!.description.isNotEmpty &&
      step1!.categories.isNotEmpty;

  bool get isStep2Valid => step2 != null && step2!.images.isNotEmpty;

  bool get isStep3Valid => step3 != null;

  bool get isStep4Valid => step4 != null;

  bool get isValid =>
      isStep1Valid && isStep2Valid && isStep3Valid && isStep4Valid;

  ReviewInfo? get reviewInfo {
    if (!isValid) return null;
    return ReviewInfo(
      basicInfo: step1!,
      imagesInfo: step2!,
      pricingInfo: step3!,
      shippingInfo: step4!,
    );
  }
}
