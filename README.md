# Tram Doc

Dự án Flutter đã được đồng bộ từ base `tramdoc_ver1`.

## Đăng nhập Firebase (CLI)
1. Cài Firebase CLI: `npm install -g firebase-tools`.
2. Đăng nhập: `firebase login` (chấp nhận mở trình duyệt và xác thực).
3. Cấu hình dự án Flutter:
   - Đặt `google-services.json` vào `android/app/`.
   - Đặt `GoogleService-Info.plist` vào `ios/Runner/`.
   - (Nếu cần) cài `flutterfire_cli`: `dart pub global activate flutterfire_cli`, rồi chạy `flutterfire configure --project <project-id>` để sinh `firebase_options.dart`.
4. Không commit khoá bí mật/JSON lên git. Để dùng môi trường cục bộ, giữ `firebase.json` hiện có và thêm các file cấu hình vào `.gitignore` nếu cần.

## Chạy dự án
1. Cài Flutter 3.10+.
2. Chạy `flutter pub get`.
3. Chạy `flutter run` trên thiết bị/simulator mong muốn.

## Tài liệu Flutter
- [Viết app Flutter đầu tiên](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: ví dụ Flutter](https://docs.flutter.dev/cookbook)
