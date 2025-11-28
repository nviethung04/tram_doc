# Trạm Đọc - Reading Station

Ứng dụng di động trợ lý đọc sách chủ động và ghi nhớ

## 🚀 Tech Stack

### Frontend (Mobile App)
- **Flutter** - Cross-platform mobile development
- **Dart** - Programming language
- **Provider/Riverpod** - State management
- **SQLite** - Local database
- **Camera** - Barcode scanning
- **OCR** - Text recognition from images

### Backend (API Server)
- **Go** - Backend programming language
- **Gin** - Web framework
- **GORM** - ORM for database operations
- **PostgreSQL** - Main database
- **JWT** - Authentication
- **Google Books API** - Book information

## 📱 Features

### 1. Thư viện Cá nhân (My Library)
- ✅ Quét mã vạch để thêm sách
- ✅ Tìm kiếm sách qua Google Books API
- ✅ Quản lý 3 kệ sách: Want to Read, Reading, Read
- ✅ Theo dõi tiến độ đọc
- ✅ Quản lý vị trí sách giấy

### 2. Ghi chú Chủ động (Active Notes)
- ✅ Ghi chú theo trang sách
- ✅ OCR từ ảnh chụp sách
- ✅ Tóm tắt ý tưởng cốt lõi

### 3. Ôn tập Ghi nhớ (Spaced Repetition)
- ✅ Chuyển ghi chú thành flashcards
- ✅ Thuật toán ôn tập ngắt quãng
- ✅ Thông báo ôn tập hàng ngày

### 4. Vòng tròn Tin cậy (Reading Circle)
- ✅ Mạng xã hội thu nhỏ
- ✅ Feed hoạt động đọc sách
- ✅ Gợi ý sách từ bạn bè

## 🏗️ Project Structure

```
tram_doc/
├── frontend/          # Flutter mobile app
│   ├── lib/
│   │   ├── screens/   # UI screens
│   │   ├── models/    # Data models
│   │   ├── services/  # API calls & business logic
│   │   ├── widgets/   # Reusable UI components
│   │   └── utils/     # Helper functions
│   └── pubspec.yaml
├── backend/           # Go API server
│   ├── cmd/          # Application entrypoints
│   ├── internal/     # Private application code
│   │   ├── handlers/ # HTTP handlers
│   │   ├── models/   # Data models
│   │   ├── services/ # Business logic
│   │   └── database/ # Database connection
│   ├── pkg/          # Public packages
│   └── go.mod
└── docs/             # Documentation
```

## 🛠️ Setup & Development

### Prerequisites
- Flutter SDK
- Go 1.21+
- PostgreSQL
- VS Code with Flutter & Go extensions

### Backend Setup
```bash
cd backend
go mod init tram-doc-api
go run cmd/main.go
```

### Frontend Setup
```bash
cd frontend
flutter create . --org com.tramDoc
flutter run
```

## 📚 API Documentation

### Authentication
- `POST /api/auth/register` - Đăng ký tài khoản
- `POST /api/auth/login` - Đăng nhập
- `POST /api/auth/logout` - Đăng xuất

### Books Management
- `GET /api/books` - Lấy danh sách sách
- `POST /api/books` - Thêm sách mới
- `PUT /api/books/:id` - Cập nhật thông tin sách
- `DELETE /api/books/:id` - Xóa sách

### Notes Management
- `GET /api/notes` - Lấy ghi chú
- `POST /api/notes` - Tạo ghi chú mới
- `PUT /api/notes/:id` - Cập nhật ghi chú

### Social Features
- `GET /api/friends` - Lấy danh sách bạn bè
- `POST /api/friends/add` - Thêm bạn
- `GET /api/feed` - Lấy feed hoạt động

## 🎯 Development Roadmap

- [ ] Phase 1: Core Library Management
- [ ] Phase 2: Note-taking & OCR
- [ ] Phase 3: Spaced Repetition System
- [ ] Phase 4: Social Features
- [ ] Phase 5: Advanced Analytics

## 📄 License

MIT License