import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/app_ui.dart';
import '../models/work_item.dart';
import '../services/coin_service.dart';
import '../services/prefs_service.dart';
import '../widgets/confirm_consume_coins_dialog.dart';
import '../widgets/gradient_bubbles_background.dart';
import 'create_wait_music_screen.dart';
import 'music_history_screen.dart';

const String _apiToken = '4be3334cd55d4d81edc41c865e9ff192';
const String _generateUrl = 'https://api.kie.ai/api/v1/generate';
const String _placeholderCallbackUrl = 'https://example.com/callback';

const String _defaultModel = 'V5';
const Color _themeGradientStart = Color(0xFF260FA9);
const Color _themeGradientEnd = Color(0xFF4a2fc9);
const List<String> _styleOptions = ['Ballad', 'R&B', 'Hip-Hop', 'Rap', 'Pop', 'Jazz', 'Classical', 'Electronic'];
const List<String> _vocalOptions = ['Random', 'Male', 'Female'];

int _promptMaxLength(String model) {
  switch (model) {
    case 'V4':
      return 3000;
    case 'V4_5':
    case 'V4_5PLUS':
    case 'V4_5ALL':
    case 'V5':
      return 5000;
    default:
      return 5000;
  }
}

int _styleMaxLength(String model) {
  switch (model) {
    case 'V4':
      return 200;
    case 'V4_5':
    case 'V4_5PLUS':
    case 'V4_5ALL':
    case 'V5':
      return 1000;
    default:
      return 1000;
  }
}

const int _titleMaxLength = 80;
const int _nonCustomPromptMaxLength = 500;

const List<String> _randomTitles = [
  'Peaceful Piano Meditation',
  'Midnight Jazz Lounge',
  'Summer Breeze Acoustic',
  'Urban Hip-Hop Vibes',
  'Romantic Strings Serenade',
  'Electric Dance Anthem',
  'Chill R&B Evening',
  'Classical Sunrise',
  'Lo-Fi Beats Study',
  'Epic Cinematic Trailer',
  'Tropical House Sunset',
  'Indie Folk Road Trip',
];

const List<String> _randomPrompts = [
  'A calm piano melody with soft strings, perfect for relaxation and meditation.',
  'Smooth jazz with saxophone and double bass, late night lounge atmosphere.',
  'Acoustic guitar and gentle vocals, warm summer afternoon feeling.',
  'Hip-hop beat with catchy hooks and urban rhythm, street vibes.',
  'Romantic orchestral strings and piano, emotional and cinematic.',
  'Upbeat electronic dance with synth leads and driving bass.',
  'Soulful R&B with smooth vocals and groovy bass line.',
  'Elegant classical piano piece, morning light and quiet moments.',
  'Lo-fi hip-hop with vinyl crackle and mellow chords for studying.',
  'Epic orchestral build-up with drums and brass, trailer style.',
  'Tropical house with steel drums and breezy synths, beach sunset.',
  'Indie folk with acoustic guitar and harmonica, road trip energy.',
];

class TextToMusicScreen extends StatefulWidget {
  const TextToMusicScreen({super.key});

  @override
  State<TextToMusicScreen> createState() => _TextToMusicScreenState();
}

class _TextToMusicScreenState extends State<TextToMusicScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _styleController = TextEditingController();

  bool _customMode = true;
  bool _instrumental = false;
  final Set<int> _selectedStyleIndices = {};
  int _vocalIndex = 0;
  bool _isSubmitting = false;

  void _toggleStyleIndex(int i) {
    setState(() {
      if (_selectedStyleIndices.contains(i)) {
        _selectedStyleIndices.remove(i);
      } else {
        _selectedStyleIndices.add(i);
      }
      final sorted = _selectedStyleIndices.toList()..sort();
      _styleController.text = sorted.map((idx) => _styleOptions[idx]).join(', ');
    });
  }

  void _clearForm() {
    _promptController.clear();
    _titleController.clear();
    _styleController.clear();
    setState(() => _selectedStyleIndices.clear());
  }

  final Random _random = Random();

  void _fillRandomTitle() {
    setState(() {
      _titleController.text = _randomTitles[_random.nextInt(_randomTitles.length)];
    });
  }

  void _fillRandomPrompt() {
    setState(() {
      _promptController.text = _randomPrompts[_random.nextInt(_randomPrompts.length)];
    });
  }

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _styleController.addListener(() => setState(() {}));
    _promptController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _promptController.dispose();
    _titleController.dispose();
    _styleController.dispose();
    super.dispose();
  }

  Future<void> _createMusic() async {
    final prompt = _promptController.text.trim();
    final title = _titleController.text.trim();
    final styleTrim = _styleController.text.trim();
    final style = styleTrim.isNotEmpty
        ? styleTrim
        : (_selectedStyleIndices.isEmpty
            ? ''
            : (_selectedStyleIndices.toList()..sort()).map((i) => _styleOptions[i]).join(', '));

    if (_customMode) {
      if (title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title is required (max 80 characters)')),
        );
        return;
      }
      if (title.length > _titleMaxLength) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Title must be at most $_titleMaxLength characters')),
        );
        return;
      }
      if (style.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Style is required')),
        );
        return;
      }
      if (style.length > _styleMaxLength(_defaultModel)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Style must be at most ${_styleMaxLength(_defaultModel)} characters')),
        );
        return;
      }
      if (!_instrumental) {
        if (prompt.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prompt (lyrics) is required when not instrumental')),
          );
          return;
        }
        if (prompt.length > _promptMaxLength(_defaultModel)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Prompt must be at most ${_promptMaxLength(_defaultModel)} characters')),
          );
          return;
        }
      }
    } else {
      if (prompt.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prompt is required (max 500 characters)')),
        );
        return;
      }
      if (prompt.length > _nonCustomPromptMaxLength) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prompt must be at most 500 characters in Non-custom mode')),
        );
        return;
      }
    }

    const int coinsRequired = 20;
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
      featureName: 'music generation',
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

    setState(() => _isSubmitting = true);

    final requestBody = <String, dynamic>{
      'customMode': _customMode,
      'instrumental': _instrumental,
      'model': _defaultModel,
      'callBackUrl': _placeholderCallbackUrl,
      'prompt': _customMode && _instrumental ? '' : prompt,
    };

    if (_customMode) {
      requestBody['title'] = title;
      requestBody['style'] = style;
      if (!_instrumental) {
        requestBody['prompt'] = prompt;
      }
      final vocal = _vocalOptions[_vocalIndex];
      if (vocal == 'Male') {
        requestBody['vocalGender'] = 'm';
      } else if (vocal == 'Female') {
        requestBody['vocalGender'] = 'f';
      }
    }

    try {
      final response = await http.post(
        Uri.parse(_generateUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiToken',
        },
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final responseJson = jsonDecode(response.body);
      if (responseJson is! Map<String, dynamic>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid response: ${response.body}')),
        );
        return;
      }

      final code = responseJson['code'] as int?;
      if (code != 200) {
        final msg = responseJson['msg'] as String? ?? 'Request failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        return;
      }

      final data = responseJson['data'] as Map<String, dynamic>?;
      final taskId = data?['taskId'] as String?;
      if (taskId == null || taskId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No taskId in response')),
        );
        return;
      }

      final workTitle = _customMode ? title : (prompt.isEmpty ? 'New Music' : prompt.length > 30 ? '${prompt.substring(0, 30)}...' : prompt);
      final work = WorkItem(
        id: taskId,
        title: workTitle,
        type: 'music',
        imageUrl: null,
        createdAt: DateTime.now(),
        description: prompt,
        taskId: taskId,
        musicUrl: null,
        status: 'PENDING',
      );
      await PrefsService.shared.saveWork(work);
      if (!context.mounted) return;
      _clearForm();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateWaitMusicScreen(taskId: taskId),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = _customMode;
    final promptMax = isCustom ? _promptMaxLength(_defaultModel) : _nonCustomPromptMaxLength;
    final styleMax = isCustom ? _styleMaxLength(_defaultModel) : 0;

    return GradientBubblesBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Text('Generate Music', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.library_music),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MusicHistoryScreen()),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: floatingTabBarBottomInset(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Custom Mode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: true, label: Text('Custom')),
                              ButtonSegment(value: false, label: Text('Simple')),
                            ],
                            selected: {_customMode},
                            onSelectionChanged: (s) => setState(() => _customMode = s.first),
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return _themeGradientStart;
                                }
                                return Colors.grey.shade200;
                              }),
                              foregroundColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return Colors.white;
                                }
                                return Colors.black87;
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (isCustom) ...[
                      Row(
                        children: [
                          Text(
                            'Instrumental (no lyrics)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Switch(
                            value: _instrumental,
                            onChanged: (v) => setState(() => _instrumental = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Title (required, max $_titleMaxLength chars)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          TextButton(
                            onPressed: _fillRandomTitle,
                            style: TextButton.styleFrom(
                              foregroundColor: _themeGradientStart,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Random'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        maxLength: _titleMaxLength,
                        maxLines: 1,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'e.g. Peaceful Piano Meditation',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          counterText: '',
                          suffixText: '${_titleController.text.length}/$_titleMaxLength',
                          suffixStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Style (required, max $styleMax chars)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _styleController,
                        maxLength: styleMax > 0 ? styleMax : null,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'e.g. Classical, Pop, Jazz',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          counterText: '',
                          suffixText: styleMax > 0 ? '${_styleController.text.length}/$styleMax' : null,
                          suffixStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_styleOptions.length, (i) {
                          final selected = _selectedStyleIndices.contains(i);
                          return GestureDetector(
                            onTap: () => _toggleStyleIndex(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: selected
                                    ? const LinearGradient(
                                        colors: [_themeGradientStart, _themeGradientEnd],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: selected ? null : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: selected ? null : Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                _styleOptions[i],
                                style: TextStyle(
                                  color: selected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Prompt / Lyrics${_instrumental ? " (optional)" : " (required, max $promptMax chars)"}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _fillRandomPrompt,
                            style: TextButton.styleFrom(
                              foregroundColor: _themeGradientStart,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Random'),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Prompt (required, max $promptMax chars). Other params are ignored.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _fillRandomPrompt,
                            style: TextButton.styleFrom(
                              foregroundColor: _themeGradientStart,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Random'),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),
                    TextField(
                      controller: _promptController,
                      maxLength: promptMax,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: isCustom
                            ? (_instrumental ? 'Optional style description' : 'Enter lyrics or prompt (required)')
                            : 'e.g. A short relaxing piano tune (max 500 chars)',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        counterText: '',
                        suffixText: '${_promptController.text.length}/$promptMax',
                        suffixStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),

                    if (isCustom) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Vocal (only in Custom Mode)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_vocalOptions.length, (i) {
                          final selected = _vocalIndex == i;
                          return FilterChip(
                            label: Text(_vocalOptions[i], style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                            selected: selected,
                            onSelected: (_) => setState(() => _vocalIndex = i),
                            backgroundColor: Colors.grey.shade100,
                            selectedColor: _themeGradientStart.withValues(alpha: 0.2),
                            checkmarkColor: Colors.black87,
                          );
                        }),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _createMusic,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(_isSubmitting ? 'Creating...' : 'Create Music'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
