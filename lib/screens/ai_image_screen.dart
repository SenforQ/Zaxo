import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_ui.dart';
import '../models/work_item.dart';
import '../services/ai_image_api_service.dart';
import '../services/coin_service.dart';
import '../services/prefs_service.dart';
import '../widgets/confirm_consume_coins_dialog.dart';
import '../widgets/gradient_bubbles_background.dart';
import 'my_works_screen.dart';

const List<String> _styles = [
  'Vinyl',
  'Neon',
  'Vintage',
  'Abstract',
  'Minimal',
  'Retro',
];

const List<String> _randomPrompts = [
  'Music album cover with neon lights and city skyline at night, glossy finish, bold typography',
  'Vintage vinyl record style cover, warm tones, retro 70s aesthetic, grain texture',
  'Abstract music cover with flowing gradients and geometric shapes, modern and sleek',
  'Minimalist album art, single bold color and simple silhouette, clean design',
  'Music cover with neon signs and rain-soaked streets, cyberpunk mood, cinematic',
  'Retro cassette tape style cover, pastel colors, 80s synthwave vibe',
  'Music cover with aurora lights and mountains, ethereal and dreamy atmosphere',
  'Bold graphic design album cover, high contrast, geometric patterns, striking visuals',
  'Classic vinyl LP sleeve, jazz club mood, warm amber lighting, film grain',
  'Vintage 60s psychedelic album art, kaleidoscope patterns, bold colors',
  'Lo-fi music cover, soft gradients, bedroom producer aesthetic, cozy vibe',
  'Disco era album cover, mirror ball, glitter, gold and purple tones',
  'Indie folk album art, forest and mist, muted greens and browns',
  'Hip-hop mixtape cover, urban street style, graffiti elements, raw energy',
  'Electronic music cover, circuit boards and neon, futuristic, digital',
  'Soul and R&B vinyl style, warm browns, golden hour, nostalgic',
  'Punk rock album cover, high contrast black and white, gritty texture',
  'Ambient music cover, soft clouds and horizon, calm blue and white',
  'Reggae album art, tropical plants, sunset, laid-back island vibe',
  'Classical music cover, elegant typography, marble and gold accents',
  'Rock band album art, desert landscape, vintage cars, Americana',
  'Chillwave album cover, palm trees, pink and blue gradient, sunset',
  'Jazz record sleeve, smoke and spotlight, moody noir atmosphere',
  'Pop album cover, bright candy colors, playful, glossy and fun',
];

const List<String> _ratioOptions = [
  '1:1',
  '16:9',
  '9:16',
  '4:3',
  '3:4',
  '3:2',
  '2:3',
  '5:4',
  '4:5',
  '21:9',
  'auto',
];

enum ChatItemType { userPrompt, aiGenerating, aiImage }

class ChatItem {
  final ChatItemType type;
  final String? prompt;
  final GeneratedImage? generatedImage;
  final String? generatingId;

  const ChatItem.userPrompt(this.prompt) : type = ChatItemType.userPrompt, generatedImage = null, generatingId = null;
  const ChatItem.aiGenerating(this.prompt, this.generatingId) : type = ChatItemType.aiGenerating, generatedImage = null;
  ChatItem.aiImage(GeneratedImage g) : type = ChatItemType.aiImage, prompt = g.prompt, generatedImage = g, generatingId = null;
}

class AiImageScreen extends StatefulWidget {
  const AiImageScreen({super.key});

  @override
  State<AiImageScreen> createState() => _AiImageScreenState();
}

class _AiImageScreenState extends State<AiImageScreen> with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatItem> _chatMessages = [];
  List<GeneratedImage> _generatedImages = [];
  int _selectedStyleIndex = 0;
  int _selectedRatioIndex = 0;
  bool _isGenerating = false;
  String? _currentGeneratingId;
  XFile? _selectedImage;
  Timer? _pollTimer;
  late AnimationController _cdRotationController;
  late AnimationController _bubbleController;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _cdRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cdRotationController.dispose();
    _bubbleController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final images = await PrefsService.shared.getAllGeneratedImages();
    final list = <ChatItem>[];
    for (final g in images.reversed) {
      list.add(ChatItem.userPrompt(g.prompt));
      if (g.taskId != null && g.imagePath == null) {
        list.add(ChatItem.aiGenerating(g.prompt, g.id));
      } else {
        list.add(ChatItem.aiImage(g));
      }
    }
    if (mounted) {
      setState(() {
        _generatedImages = images;
        _chatMessages = list;
      });
      final pending = images.where((g) => g.taskId != null && g.imagePath == null);
      if (pending.isNotEmpty && !_isGenerating) {
        final first = pending.first;
        _currentGeneratingId = first.id;
        setState(() => _isGenerating = true);
        _startPolling(first.id, first.taskId!);
      }
    }
  }

  void _randomPrompt() {
    _inputController.text = _randomPrompts[Random().nextInt(_randomPrompts.length)];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final xfile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (xfile != null && mounted) {
        setState(() => _selectedImage = xfile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _send() async {
    final prompt = _inputController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an image description')),
      );
      return;
    }

    const int coinsRequired = 10;
    final currentCoins = await CoinService.getCurrentCoins();
    if (currentCoins < coinsRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient coins. This action requires $coinsRequired coins. Please purchase in Wallet.',
          ),
        ),
      );
      return;
    }

    final agreed = await showConfirmConsumeCoinsDialog(
      context: context,
      coins: coinsRequired,
      featureName: 'image generation',
    );
    if (!agreed || !mounted) return;

    final deducted = await CoinService.deductCoins(coinsRequired);
    if (!deducted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to deduct coins. Please try again.')),
        );
      }
      return;
    }

    final effectivePrompt = '$prompt, ${_styles[_selectedStyleIndex].toLowerCase()} style';
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final gen = GeneratedImage(
      id: id,
      prompt: effectivePrompt,
      imagePath: null,
      createdAt: DateTime.now(),
    );
    setState(() {
      _chatMessages.add(ChatItem.userPrompt(prompt));
      _chatMessages.add(ChatItem.aiGenerating(effectivePrompt, id));
      _currentGeneratingId = id;
      _isGenerating = true;
      _inputController.clear();
    });
    _scrollToBottom();

    List<String>? imageInput;
    if (_selectedImage != null) {
      try {
        final bytes = await _selectedImage!.readAsBytes();
        final url = await AiImageApiService.shared.uploadImage(bytes);
        if (!mounted) return;
        imageInput = [url];
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isGenerating = false;
          _currentGeneratingId = null;
          final idx = _chatMessages.indexWhere((m) => m.type == ChatItemType.aiGenerating && m.generatingId == id);
          if (idx >= 0) _chatMessages.removeAt(idx);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
        return;
      }
    }

    String? taskId;
    try {
      taskId = await AiImageApiService.shared.createTask(
        prompt: effectivePrompt,
        style: _styles[_selectedStyleIndex],
        size: _ratioOptions[_selectedRatioIndex],
        outputFormat: 'png',
        imageInput: imageInput,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _currentGeneratingId = null;
        final idx = _chatMessages.indexWhere((m) => m.type == ChatItemType.aiGenerating && m.generatingId == id);
        if (idx >= 0) _chatMessages.removeAt(idx);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create task: $e')),
      );
      return;
    }

    final savedGen = GeneratedImage(
      id: gen.id,
      taskId: taskId,
      prompt: gen.prompt,
      imagePath: null,
      createdAt: gen.createdAt,
    );
    await PrefsService.shared.saveGeneratedImage(savedGen);
    if (!mounted) return;
    setState(() {
      _generatedImages = [..._generatedImages, savedGen];
      _selectedImage = null;
    });
    _generatedImages = await PrefsService.shared.getAllGeneratedImages();
    _startPolling(id, taskId);
  }

  void _startPolling(String generatedId, String taskId) {
    _pollTimer?.cancel();
    void poll() async {
      if (!mounted) return;
      try {
        final status = await AiImageApiService.shared.queryTaskStatus(taskId);
        if (!mounted) return;
        if (status.state == 'success' && status.imageUrl != null && status.imageUrl!.isNotEmpty) {
          _pollTimer?.cancel();
          final path = await _downloadImage(status.imageUrl!, generatedId);
          if (!mounted) return;
          await _onTaskSuccess(generatedId, path);
          return;
        }
        if (status.state == 'failed' || status.state == 'error') {
          _pollTimer?.cancel();
          _onTaskFailed(generatedId);
          return;
        }
      } catch (_) {}
    }
    poll();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => poll());
  }

  Future<String?> _downloadImage(String imageUrl, String generatedId) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;
      final dir = await getApplicationDocumentsDirectory();
      final ext = imageUrl.contains('.jpg') || imageUrl.contains('.jpeg') ? '.jpg' : '.png';
      final file = File('${dir.path}/ai_image_$generatedId$ext');
      await file.writeAsBytes(response.bodyBytes);
      return 'ai_image_$generatedId$ext';
    } catch (_) {
      return null;
    }
  }

  Future<void> _onTaskSuccess(String generatedId, String? imagePath) async {
    final list = await PrefsService.shared.getAllGeneratedImages();
    final found = list.where((e) => e.id == generatedId);
    if (found.isEmpty) return;
    final gen = found.first;
    final updated = GeneratedImage(
      id: gen.id,
      taskId: gen.taskId,
      prompt: gen.prompt,
      imagePath: imagePath,
      createdAt: gen.createdAt,
    );
    await PrefsService.shared.updateGeneratedImage(updated);
    if (!mounted) return;
    setState(() {
      final idx = _chatMessages.indexWhere((m) => m.type == ChatItemType.aiGenerating && m.generatingId == generatedId);
      if (idx >= 0) _chatMessages[idx] = ChatItem.aiImage(updated);
      _generatedImages = [..._generatedImages.where((g) => g.id != generatedId), updated];
      _isGenerating = false;
      _currentGeneratingId = null;
    });
    _scrollToBottom();
    PrefsService.notifyWorksUpdated();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image generated, saved to My Works')),
    );
  }

  void _onTaskFailed(String generatedId) {
    if (!mounted) return;
    setState(() {
      final idx = _chatMessages.indexWhere((m) => m.type == ChatItemType.aiGenerating && m.generatingId == generatedId);
      if (idx >= 0) _chatMessages.removeAt(idx);
      _generatedImages.removeWhere((g) => g.id == generatedId);
      _isGenerating = false;
      _currentGeneratingId = null;
    });
    PrefsService.shared.deleteGeneratedImage(generatedId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image generation failed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = floatingTabBarBottomInset(context);
    final hasMessages = _chatMessages.isNotEmpty;

    return GradientBubblesBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Text('Music Cover', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.access_time),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyWorksScreen()),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _buildHeaderBanner(),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F8),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasMessages
                          ? ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              itemCount: _chatMessages.length,
                              itemBuilder: (context, i) {
                                final item = _chatMessages[i];
                                if (item.type == ChatItemType.userPrompt) {
                                  return _UserBubble(prompt: item.prompt ?? '');
                                }
                                if (item.type == ChatItemType.aiGenerating) {
                                  return _GeneratingBubble(prompt: item.prompt ?? '');
                                }
                                return _ImageBubble(generated: item.generatedImage!);
                              },
                            )
                          : _buildEmptyState(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInputBar(bottomInset),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const double _cdSize = 150;
  static const double _cdLeft = 230;

  Widget _buildHeaderBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6B4EFF),
              Color(0xFF9D7BFF),
              Color(0xFFB8A4FF),
              Color(0xFF7C5CBF),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            _buildBubbles(),
            Positioned(
              left: _cdLeft,
              top: (72 - _cdSize) / 2,
              width: _cdSize,
              height: _cdSize,
              child: RotationTransition(
                turns: _cdRotationController,
                child: Image.asset(
                  'assets/CDCover.png',
                  width: _cdSize,
                  height: _cdSize,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Create',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Music Cover',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ratio ${_ratioOptions[_selectedRatioIndex]}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: _showRatioPicker,
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.aspect_ratio, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubbles() {
    return AnimatedBuilder(
      animation: _bubbleController,
      builder: (context, child) {
        final t = _bubbleController.value * 2 * pi;
        return CustomPaint(
          size: const Size(double.infinity, 72),
          painter: _BubblePainter(t),
        );
      },
    );
  }

  void _showRatioPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Image Ratio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_ratioOptions.length, (i) {
                      final selected = _selectedRatioIndex == i;
                      return ListTile(
                        title: Text(_ratioOptions[i]),
                        trailing: selected ? const Icon(Icons.check, color: Color(0xFFFEE838)) : null,
                        onTap: () {
                          setState(() => _selectedRatioIndex = i);
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Create Your Music Cover',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Generate a custom music cover image. Describe the style, mood, or scene you want (e.g. neon city, vintage vinyl, abstract) in the input below, or tap the shuffle button for a random idea.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(double bottomInset) {
    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, bottom: bottomInset + 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _randomPrompt,
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Text('AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 36,
                height: 36,
                child: _selectedImage != null
                    ? Image.file(
                        File(_selectedImage!.path),
                        fit: BoxFit.cover,
                        width: 36,
                        height: 36,
                      )
                    : const Center(
                        child: Icon(Icons.add_photo_alternate_outlined, size: 20),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: 'Eg: Music cover with neon lights and city skyline at night.',
                hintStyle: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.grey.shade200?.withValues(alpha: 0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              style: const TextStyle(fontSize: 16),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: _isGenerating ? null : () => _send(),
              borderRadius: BorderRadius.circular(20),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_circle_up, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.prompt});

  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 8, right: 16, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFA8E6CF).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          prompt,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
      ),
    );
  }
}

class _GeneratingBubble extends StatelessWidget {
  const _GeneratingBubble({required this.prompt});

  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8, left: 16, right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            const Text('AI is drawing...', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  const _ImageBubble({required this.generated});

  final GeneratedImage generated;

  static Future<File> _imageFile(String relativePath) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$relativePath');
  }

  @override
  Widget build(BuildContext context) {
    final hasPath = generated.imagePath != null && generated.imagePath!.isNotEmpty;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8, left: 16, right: 48),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasPath
                  ? FutureBuilder<File>(
                      future: _imageFile(generated.imagePath!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.existsSync()) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => _AiImageFullScreen(
                                          generated: generated,
                                          imageFile: snapshot.data!,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Image.file(
                                    snapshot.data!,
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Material(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    onTap: () => _saveToGallery(
                                      context,
                                      generated.imagePath!,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.download,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Download',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        return const Center(
                          child: Icon(Icons.image, size: 64, color: Colors.grey),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 64, color: Colors.grey),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              generated.prompt,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _saveToGallery(
    BuildContext context,
    String relativePath,
  ) async {
    try {
      final file = await _imageFile(relativePath);
      if (!await file.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image not found')),
          );
        }
        return;
      }
      final bytes = await file.readAsBytes();
      await Gal.requestAccess();
      await Gal.putImageBytes(Uint8List.fromList(bytes));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to Photos')),
        );
      }
    } on GalException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.type.message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }
}

class _AiImageFullScreen extends StatefulWidget {
  const _AiImageFullScreen({
    required this.generated,
    required this.imageFile,
  });

  final GeneratedImage generated;
  final File imageFile;

  @override
  State<_AiImageFullScreen> createState() => _AiImageFullScreenState();
}

class _AiImageFullScreenState extends State<_AiImageFullScreen> {
  bool _saving = false;

  Future<void> _saveToGallery() async {
    setState(() => _saving = true);
    try {
      final bytes = await widget.imageFile.readAsBytes();
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

  @override
  Widget build(BuildContext context) {
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
            widget.generated.prompt,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
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
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Image.file(
              widget.imageFile,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final bubbles = [
      (x: 40.0, y: 20.0, r: 8.0),
      (x: 120.0, y: 50.0, r: 6.0),
      (x: 200.0, y: 25.0, r: 10.0),
      (x: 280.0, y: 45.0, r: 7.0),
      (x: 350.0, y: 30.0, r: 5.0),
      (x: 80.0, y: 55.0, r: 6.0),
      (x: 250.0, y: 18.0, r: 5.0),
    ];
    for (var i = 0; i < bubbles.length; i++) {
      final b = bubbles[i];
      final offsetY = sin(t + i * 0.8) * 4;
      final opacity = 0.15 + 0.12 * sin(t * 1.2 + i);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(b.x, b.y + offsetY),
        b.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => oldDelegate.t != t;
}
