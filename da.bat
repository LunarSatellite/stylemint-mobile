@echo off
cd /d "D:\.StyleMint\stylemint-mobile"
dart --no-analytics analyze lib/features/vendor/partnerships/data/models/vendor_partnership_dto.dart 2>&1
echo EXITCODE=%ERRORLEVEL%
