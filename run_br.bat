@echo off
cd /d "D:\.StyleMint\stylemint-mobile"
dart run build_runner build --delete-conflicting-outputs --build-filter lib/features/vendor/partnerships/data/models/vendor_partnership_dto.dart 2>&1
echo EXITCODE=%ERRORLEVEL%
