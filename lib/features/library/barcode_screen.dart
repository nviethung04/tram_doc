import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/google_books_service.dart';
import '../../data/services/book_service.dart';
import '../../models/book.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key});

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  final GoogleBooksService _service = GoogleBooksService();
  final BookService _bookService = BookService();
  final _auth = FirebaseAuth.instance;

  BookStatus? _selectedShelf;
  bool _isHandling = false;
  String? _status;
  String? _lastCode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isHandling) return;
    String? code;
    for (final b in capture.barcodes) {
      if (b.rawValue != null && b.rawValue!.isNotEmpty) {
        code = b.rawValue;
        break;
      }
    }
    if (code == null || code == _lastCode) return;
    _lookupIsbn(code);
  }

  Future<void> _lookupIsbn(String code) async {
    setState(() {
      _isHandling = true;
      _status = 'Đang tìm ISBN $code...';
      _lastCode = code;
    });
    try {
      final book = await _service.lookupIsbn(code);
      if (!mounted) return;
      if (book == null) {
        setState(() => _status = 'Không tìm thấy sách với ISBN $code');
      } else {
        setState(() => _status = 'Đã tìm thấy: ${book.title}');
        _openAddToShelf(book);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = 'Lỗi khi gọi Google Books');
    } finally {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _isHandling = false);
        });
      }
    }
  }

  void _openAddToShelf(Book book) {
    _selectedShelf ??= BookStatus.wantToRead;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(book.title, style: AppTypography.h2),
              const SizedBox(height: 4),
              Text(book.author, style: AppTypography.body.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              const Text('Chọn kệ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              for (final status in BookStatus.values)
                RadioListTile<BookStatus>(
                  title: Text(status.label),
                  value: status,
                  groupValue: _selectedShelf,
                  onChanged: (val) => setState(() => _selectedShelf = val),
                ),
              ElevatedButton(
                onPressed: () async {
                  if (_selectedShelf == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng chọn kệ trước khi thêm')),
                    );
                    return;
                  }
                  final user = _auth.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hãy đăng nhập để lưu sách vào thư viện')),
                    );
                    return;
                  }
                  final added = book.copyWith(status: _selectedShelf!);
                  try {
                    await _bookService.upsertBook(added);
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã thêm "${book.title}" vào kệ ${_selectedShelf!.label}')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi lưu sách: $e')),
                    );
                  }
                },
                child: const Text('Thêm'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _promptManual() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nhập ISBN thủ công'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Ví dụ: 9780134685991'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Tra cứu')),
        ],
      ),
    );
    if (code != null && code.isNotEmpty) {
      _lookupIsbn(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Quét mã vạch', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            fit: BoxFit.cover,
          ),
          const _ScannerOverlay(),
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_status != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_status!, style: AppTypography.body),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Đặt mã vạch vào khung để quét',
                  style: AppTypography.body.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Nếu không quét được, nhập ISBN thủ công',
                  style: AppTypography.body.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _promptManual,
                  child: const Text('Nhập ISBN', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        height: 360,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x4CFFFFFF), width: 3),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 280,
                height: 130,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
