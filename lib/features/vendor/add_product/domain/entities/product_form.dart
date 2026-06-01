import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class BasicInfo {
  const BasicInfo({
    required this.productName,
    required this.description,
    required this.categories,
    this.brand,
    required this.tags,
  });

  final String productName;
  final String description;
  final List<String> categories;
  final String? brand;
  final List<String> tags;

  BasicInfo copyWith({
    String? productName,
    String? description,
    List<String>? categories,
    String? brand,
    List<String>? tags,
  }) {
    return BasicInfo(
      productName: productName ?? this.productName,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      brand: brand ?? this.brand,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BasicInfo &&
      other.productName == productName &&
      other.description == description &&
      _listEquals(other.categories, categories) &&
      other.brand == brand &&
      _listEquals(other.tags, tags);

  @override
  int get hashCode => Object.hash(
        productName,
        description,
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
  });

  final Money basePrice;
  final Money? compareAtPrice;
  final Money? costPerItem;
  final double taxRate;
  final bool discountEnabled;
  final double? discountPercent;

  PricingInfo copyWith({
    Money? basePrice,
    Money? compareAtPrice,
    Money? costPerItem,
    double? taxRate,
    bool? discountEnabled,
    double? discountPercent,
  }) {
    return PricingInfo(
      basePrice: basePrice ?? this.basePrice,
      compareAtPrice: compareAtPrice ?? this.compareAtPrice,
      costPerItem: costPerItem ?? this.costPerItem,
      taxRate: taxRate ?? this.taxRate,
      discountEnabled: discountEnabled ?? this.discountEnabled,
      discountPercent: discountPercent ?? this.discountPercent,
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
      other.discountPercent == discountPercent;

  @override
  int get hashCode => Object.hash(
        basePrice,
        compareAtPrice,
        costPerItem,
        taxRate,
        discountEnabled,
        discountPercent,
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
