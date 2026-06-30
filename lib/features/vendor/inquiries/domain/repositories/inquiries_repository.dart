import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/domain/entities/product_inquiry.dart';

abstract class InquiriesRepository {
  Future<Either<NetworkExceptions, List<ProductInquiry>>> listVendor({
    int pageSize = 50,
  });

  Future<Either<NetworkExceptions, ProductInquiry>> reply(
    String inquiryId,
    String text,
  );
}
