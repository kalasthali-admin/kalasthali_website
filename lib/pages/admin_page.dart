import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models/product.dart';
import '../core/services/admin_service.dart';
import '../core/services/image_upload_converter.dart';
import '../widgets/app_scaffold.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _service = AdminService.instance;
  bool _loading = false;
  String? _error;
  List<Product> _products = const [];
  List<AdminGallery> _gallery = const [];

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getProducts(),
        _service.getGallery(),
      ]);
      if (!mounted) return;
      setState(() {
        _products = results[0] as List<Product>;
        _gallery = results[1] as List<AdminGallery>;
      });
    } on AdminException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logIn() async {
    final password = AdminService.isTestMode
        ? ''
        : await showDialog<String>(
            context: context,
            builder: (_) => const _AdminLoginDialog(),
          );
    if (password == null || (!AdminService.isTestMode && password.isEmpty)) {
      return;
    }

    setState(() => _loading = true);
    try {
      await _service.login(password);
      await _loadDashboard();
    } on AdminException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
      }
    }
  }

  Future<void> _editProduct([Product? product]) async {
    final values = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFEF5E6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ProductEditor(
        product: product,
        existingCodes: _products.map((item) => item.code).toSet(),
      ),
    );
    if (values == null) return;

    setState(() => _loading = true);
    try {
      if (product == null) {
        await _service.create(values);
      } else {
        await _service.update(product.code, values);
      }
      await _loadDashboard();
    } on AdminException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          'Delete "${product.name}" from the products database? Its storage images will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    setState(() => _loading = true);
    try {
      await _service.delete(product.code);
      await _loadDashboard();
      if (mounted) _showMessage('Product deleted.');
    } on AdminException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _replaceGallery(AdminGallery updated) {
    setState(() {
      _gallery = _gallery
          .map((entry) => entry.code == updated.code ? updated : entry)
          .toList();
    });
  }

  Future<AdminGallery?> _uploadImage(String code) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    final bytes = file?.bytes;
    if (bytes == null) return null;
    if (!mounted) return null;
    final extension = file?.extension?.toLowerCase();
    final inputMime = extension == 'png' ? 'image/png' : 'image/jpeg';
    final status = ValueNotifier<_ImageUploadStatus>(
      const _ImageUploadStatus.processing(),
    );
    final dialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ImageUploadDialog(status: status),
    );
    try {
      final webpBytes = await convertImageToWebp(bytes, inputMime);
      if (webpBytes.length > 3 * 1024 * 1024) {
        throw StateError('The converted WebP must be smaller than 3 MB.');
      }
      final gallery = await _service.uploadImage(code, webpBytes);
      _replaceGallery(gallery);
      status.value = const _ImageUploadStatus.success();
      await dialog;
      return gallery;
    } catch (error) {
      status.value = _ImageUploadStatus.failure(error.toString());
      await dialog;
      return null;
    } finally {
      status.dispose();
    }
  }

  Future<AdminGallery?> _setThumbnail(String code, String name) async {
    try {
      final gallery = await _service.setThumbnail(code, name);
      _replaceGallery(gallery);
      if (mounted) _showMessage('Thumbnail updated.');
      return gallery;
    } on AdminException catch (error) {
      if (mounted) _showMessage(error.message);
      return null;
    }
  }

  Future<AdminGallery?> _deleteImage(String code, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove image?'),
        content: const Text(
          'This permanently removes the image from the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return null;

    try {
      final gallery = await _service.deleteImage(code, name);
      _replaceGallery(gallery);
      if (mounted) _showMessage('Image removed.');
      return gallery;
    } on AdminException catch (error) {
      if (mounted) _showMessage(error.message);
      return null;
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Admin',
      currentRoute: '/admin',
      centerBody: false,
      body: !_service.isAuthenticated
          ? _AdminGate(loading: _loading, error: _error, onLogin: _logIn)
          : _AdminDashboard(
              loading: _loading,
              error: _error,
              products: _products,
              gallery: _gallery,
              onRefresh: _loadDashboard,
              onCreate: () => _editProduct(),
              onEdit: _editProduct,
              onDelete: _deleteProduct,
              onUploadImage: _uploadImage,
              onSetThumbnail: _setThumbnail,
              onDeleteImage: _deleteImage,
              onSignOut: () => setState(_service.signOut),
            ),
    );
  }
}

enum _ImageUploadPhase { processing, success, failure }

class _ImageUploadStatus {
  const _ImageUploadStatus.processing()
    : phase = _ImageUploadPhase.processing,
      message = '';
  const _ImageUploadStatus.success()
    : phase = _ImageUploadPhase.success,
      message = '';
  const _ImageUploadStatus.failure(this.message)
    : phase = _ImageUploadPhase.failure;

  final _ImageUploadPhase phase;
  final String message;
}

class _ImageUploadDialog extends StatelessWidget {
  const _ImageUploadDialog({required this.status});

  final ValueNotifier<_ImageUploadStatus> status;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: ValueListenableBuilder<_ImageUploadStatus>(
      valueListenable: status,
      builder: (context, current, _) {
        final processing = current.phase == _ImageUploadPhase.processing;
        final success = current.phase == _ImageUploadPhase.success;
        return AlertDialog(
          title: Text(
            processing
                ? 'Preparing image'
                : success
                ? 'Image uploaded'
                : 'Upload failed',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 28,
              color: const Color(0xFF5B351A),
            ),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (processing)
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              else
                Icon(
                  success ? Icons.check_circle_outline : Icons.error_outline,
                  color: success
                      ? const Color(0xFF477A45)
                      : Colors.red.shade700,
                  size: 26,
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  processing
                      ? 'Converting your image to WebP and uploading it securely.'
                      : success
                      ? 'Your image was uploaded successfully.'
                      : current.message,
                  style: GoogleFonts.blinker(fontSize: 17),
                ),
              ),
            ],
          ),
          actions: [
            if (!processing)
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(success ? 'Done' : 'Close'),
              ),
          ],
        );
      },
    ),
  );
}

class _AdminGate extends StatelessWidget {
  const _AdminGate({
    required this.loading,
    required this.error,
    required this.onLogin,
  });

  final bool loading;
  final String? error;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFFECE7DD),
            border: Border.all(color: const Color(0xFFD0A36F)),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332D1E12),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 46,
                color: const Color(0xFF5B351A),
              ),
              const SizedBox(height: 16),
              Text(
                'Admin Dashboard',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 34,
                  color: const Color(0xFF5B351A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'For managing listed products and their images',
                textAlign: TextAlign.center,
                style: GoogleFonts.blinker(fontSize: 17),
              ),
              if (error != null) ...[
                const SizedBox(height: 14),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: loading ? null : onLogin,
                  icon: loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open_outlined),
                  label: const Text('Unlock dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AdminLoginDialog extends StatefulWidget {
  const _AdminLoginDialog();

  @override
  State<_AdminLoginDialog> createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends State<_AdminLoginDialog> {
  final password = TextEditingController();
  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      'Admin sign in',
      style: GoogleFonts.dmSerifDisplay(fontSize: 28),
    ),
    content: TextField(
      controller: password,
      autofocus: true,
      obscureText: true,
      onSubmitted: (_) => Navigator.pop(context, password.text),
      decoration: const InputDecoration(labelText: 'Password'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, password.text),
        child: const Text('Continue'),
      ),
    ],
  );
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard({
    required this.loading,
    required this.error,
    required this.products,
    required this.gallery,
    required this.onRefresh,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.onUploadImage,
    required this.onSetThumbnail,
    required this.onDeleteImage,
    required this.onSignOut,
  });

  final bool loading;
  final String? error;
  final List<Product> products;
  final List<AdminGallery> gallery;
  final Future<void> Function() onRefresh;
  final VoidCallback onCreate;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onDelete;
  final Future<AdminGallery?> Function(String) onUploadImage;
  final Future<AdminGallery?> Function(String code, String name) onSetThumbnail;
  final Future<AdminGallery?> Function(String code, String name) onDeleteImage;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 700;
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          mobile ? 18 : 42,
          mobile ? 34 : 56,
          mobile ? 18 : 42,
          80,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Product Admin',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: mobile ? 38 : 52,
                          color: const Color(0xFF5B351A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: loading ? null : onRefresh,
                      tooltip: 'Refresh',
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton(
                      onPressed: onSignOut,
                      tooltip: 'Sign out',
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Add, delete, or edit your listed products on the website. To view or edit product images, scroll further.',
                  style: GoogleFonts.blinker(fontSize: mobile ? 16 : 18),
                ),
                if (error != null) ...[
                  const SizedBox(height: 14),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: loading ? null : onCreate,
                    icon: const Icon(Icons.add),
                    label: const Text('Add product'),
                  ),
                ),
                const SizedBox(height: 22),
                if (loading && products.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (products.isEmpty)
                  Text(
                    'No products found.',
                    style: GoogleFonts.blinker(fontSize: 18),
                  )
                else
                  ...products.map(
                    (product) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ProductAdminCard(
                        product: product,
                        onEdit: () => onEdit(product),
                        onDelete: () => onDelete(product),
                      ),
                    ),
                  ),
                const SizedBox(height: 52),
                Text(
                  'Product Gallery',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: mobile ? 34 : 44,
                    color: const Color(0xFF5B351A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload PNG or JPEG images, choose a thumbnail, or remove images from each product folder.',
                  style: GoogleFonts.blinker(fontSize: mobile ? 15 : 17),
                ),
                const SizedBox(height: 22),
                if (loading && gallery.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  ...gallery.map((entry) {
                    final product = products
                        .where((product) => product.code == entry.code)
                        .firstOrNull;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GalleryListTile(
                        entry: entry,
                        productName: product?.name ?? 'Product',
                        onOpen: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: const Color(0xFFFEF5E6),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                          ),
                          builder: (sheetContext) => _GallerySheet(
                            entry: entry,
                            productName: product?.name ?? 'Product',
                            loading: loading,
                            onUpload: () => onUploadImage(entry.code),
                            onSetThumbnail: (name) =>
                                onSetThumbnail(entry.code, name),
                            onDelete: (name) => onDeleteImage(entry.code, name),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ProductAdminCard extends StatelessWidget {
  const _ProductAdminCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFECE7DD),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFD5B48A)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 27,
                color: const Color(0xFF5B351A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Code: ${product.code}  •  ${product.type}',
              style: GoogleFonts.blinker(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.blinker(fontSize: 16),
            ),
          ],
        );
        final actions = Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
            OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        );
        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [details, const SizedBox(height: 14), actions],
              )
            : Row(
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 20),
                  actions,
                ],
              );
      },
    ),
  );
}

class _GalleryListTile extends StatelessWidget {
  const _GalleryListTile({
    required this.entry,
    required this.productName,
    required this.onOpen,
  });

  final AdminGallery entry;
  final String productName;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFECE7DD),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD5B48A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.photo_library_outlined, color: Color(0xFF5B351A)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '${entry.code}-$productName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.blinker(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text('${entry.images.length} images', style: GoogleFonts.blinker()),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

class _GallerySheet extends StatefulWidget {
  const _GallerySheet({
    required this.entry,
    required this.productName,
    required this.loading,
    required this.onUpload,
    required this.onSetThumbnail,
    required this.onDelete,
  });

  final AdminGallery entry;
  final String productName;
  final bool loading;
  final Future<AdminGallery?> Function() onUpload;
  final Future<AdminGallery?> Function(String) onSetThumbnail;
  final Future<AdminGallery?> Function(String) onDelete;

  @override
  State<_GallerySheet> createState() => _GallerySheetState();
}

class _GallerySheetState extends State<_GallerySheet> {
  late AdminGallery _entry;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  Future<void> _apply(Future<AdminGallery?> operation) async {
    setState(() => _busy = true);
    final updated = await operation;
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (updated != null) _entry = updated;
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FractionallySizedBox(
      heightFactor: .86,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6C0AA),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_entry.code}-${widget.productName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 30,
                      color: const Color(0xFF5B351A),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _busy || widget.loading
                      ? null
                      : () => _apply(widget.onUpload()),
                  tooltip: 'Upload PNG or JPEG image',
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Star an image to use it as the storefront thumbnail.',
              style: GoogleFonts.blinker(fontSize: 16),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _entry.images.isEmpty
                  ? Center(
                      child: Text(
                        'No images found. Upload a PNG or JPEG image to begin.',
                        style: GoogleFonts.blinker(fontSize: 17),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: .72,
                          ),
                      itemCount: _entry.images.length,
                      itemBuilder: (_, index) => _GalleryImageTile(
                        image: _entry.images[index],
                        loading: _busy || widget.loading,
                        onSetThumbnail: (name) =>
                            _apply(widget.onSetThumbnail(name)),
                        onDelete: (name) => _apply(widget.onDelete(name)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GalleryImageTile extends StatelessWidget {
  const _GalleryImageTile({
    required this.image,
    required this.loading,
    required this.onSetThumbnail,
    required this.onDelete,
  });

  final AdminGalleryImage image;
  final bool loading;
  final ValueChanged<String> onSetThumbnail;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            image.url,
            fit: BoxFit.cover,
            cacheWidth: 288,
            filterQuality: FilterQuality.low,
            // Use the browser's decoder on the web. It is substantially more
            // reliable than CanvasKit for large WebP images on low-end devices.
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            errorBuilder: (_, _, _) => Image.network(
              image.sourceUrl,
              fit: BoxFit.cover,
              cacheWidth: 288,
              filterQuality: FilterQuality.low,
              webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xFFD8D0C3),
                child: Icon(Icons.broken_image),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        top: 8,
        left: 8,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xE95B351A),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              image.isThumbnail ? 'Thumbnail' : image.name,
              style: GoogleFonts.blinker(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      Positioned(
        right: 6,
        bottom: 6,
        child: Material(
          color: const Color(0xE9FEF5E6),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!image.isThumbnail)
                IconButton(
                  onPressed: loading ? null : () => onSetThumbnail(image.name),
                  tooltip: 'Use as thumbnail',
                  icon: const Icon(Icons.star_outline),
                ),
              IconButton(
                onPressed: loading ? null : () => onDelete(image.name),
                tooltip: 'Remove image',
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ProductEditor extends StatefulWidget {
  const _ProductEditor({this.product, required this.existingCodes});
  final Product? product;
  final Set<String> existingCodes;

  @override
  State<_ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<_ProductEditor> {
  final formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> fields;
  late bool isPopular;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    fields = {
      'code': TextEditingController(text: product?.code ?? ''),
      'name': TextEditingController(text: product?.name ?? ''),
      'type': TextEditingController(text: product?.type ?? ''),
      'price': TextEditingController(text: product?.price ?? ''),
      'sizes': TextEditingController(text: product?.sizes ?? ''),
      'description': TextEditingController(text: product?.description ?? ''),
      'specifications': TextEditingController(
        text: product?.specifications ?? '',
      ),
    };
    isPopular = product?.isPopular ?? false;
  }

  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      for (final entry in fields.entries)
        entry.key: entry.value.text.trim().isEmpty
            ? null
            : entry.value.text.trim(),
      'is_popular': isPopular,
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6C0AA),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                widget.product == null ? 'Add Product' : 'Edit Product',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 36,
                  color: const Color(0xFF5B351A),
                ),
              ),
              const SizedBox(height: 18),
              _EditorField(
                controller: fields['code']!,
                label: 'Code',
                enabled: widget.product == null,
                validator: (value) {
                  final code = value?.trim() ?? '';
                  if (code.isEmpty) return 'Code is required.';
                  if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(code)) {
                    return 'Use letters, numbers, hyphens and underscores only.';
                  }
                  if (widget.existingCodes.any(
                    (existing) => existing.toLowerCase() == code.toLowerCase(),
                  )) {
                    return 'This product code already exists.';
                  }
                  return null;
                },
                helperText: widget.product == null
                    ? 'Letters, numbers, hyphens and underscores only.'
                    : 'Product codes cannot be changed after creation.',
              ),
              _EditorField(
                controller: fields['name']!,
                label: 'Product name',
                required: true,
              ),
              _EditorField(
                controller: fields['type']!,
                label: 'Type',
                required: true,
              ),
              _EditorField(controller: fields['price']!, label: 'Price'),
              _EditorField(
                controller: fields['sizes']!,
                label: 'Sizes',
                helperText: 'Comma-separated, for example M, L, XL.',
              ),
              _EditorField(
                controller: fields['description']!,
                label: 'Description',
                required: true,
                lines: 4,
              ),
              _EditorField(
                controller: fields['specifications']!,
                label: 'Specifications',
                lines: 3,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show as a popular product'),
                value: isPopular,
                activeThumbColor: const Color(0xFFA35710),
                onChanged: (value) => setState(() => isPopular = value),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(
                    widget.product == null ? 'Create product' : 'Save changes',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _EditorField extends StatelessWidget {
  const _EditorField({
    required this.controller,
    required this.label,
    this.enabled = true,
    this.required = false,
    this.lines = 1,
    this.helperText,
    this.validator,
  });
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final bool required;
  final int lines;
  final String? helperText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      enabled: enabled,
      minLines: lines,
      maxLines: lines,
      validator:
          validator ??
          (required
              ? (value) => value == null || value.trim().isEmpty
                    ? '$label is required.'
                    : null
              : null),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}
