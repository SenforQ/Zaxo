import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/work_item.dart';
import '../widgets/gradient_bubbles_background.dart';

class ImageDetailScreen extends StatefulWidget {
  const ImageDetailScreen({super.key, required this.work});

  final WorkItem work;

  @override
  State<ImageDetailScreen> createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  bool _saving = false;

  Future<void> _saveToGallery() async {
    final imageUrl = widget.work.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image to save')),
        );
      }
      return;
    }

    setState(() => _saving = true);
    try {
      final List<int> bytes;
      final isNetwork = imageUrl.startsWith('http://') ||
          imageUrl.startsWith('https://');
      if (isNetwork) {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode != 200) throw Exception('Download failed');
        bytes = response.bodyBytes;
      } else {
        final file = await _localFile(imageUrl);
        if (!await file.exists()) throw Exception('File not found');
        bytes = await file.readAsBytes();
      }

      await Gal.requestAccess();
      await Gal.putImageBytes(Uint8List.fromList(bytes));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to Photos')),
        );
      }
    } on GalException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.type.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static Future<File> _localFile(String relativePath) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$relativePath');
  }

  @override
  Widget build(BuildContext context) {
    final work = widget.work;
    final imageUrl = work.imageUrl;
    final hasUrl = imageUrl != null && imageUrl.isNotEmpty;
    final isNetwork =
        hasUrl &&
        (imageUrl!.startsWith('http://') || imageUrl.startsWith('https://'));

    return GradientBubblesBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            work.title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (hasUrl)
              IconButton(
                icon: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download),
                onPressed: _saving ? null : _saveToGallery,
              ),
          ],
        ),
        body: Center(
          child: hasUrl
              ? isNetwork
                  ? InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4,
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _placeholder(context),
                      ),
                    )
                  : FutureBuilder<File>(
                      future: _localFile(imageUrl!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData &&
                            snapshot.data!.existsSync()) {
                          return InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4,
                            child: Image.file(
                              snapshot.data!,
                              fit: BoxFit.contain,
                            ),
                          );
                        }
                        return _placeholder(context);
                      },
                    )
              : _placeholder(context),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Icon(
      Icons.image_not_supported,
      size: 64,
      color: Colors.white.withValues(alpha: 0.6),
    );
  }
}
