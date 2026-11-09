import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tts/tts_service.dart';
import '../../core/widgets/ltr.dart';

class WordLookupBottomSheet extends StatefulWidget {
  final String word;
  final WordLookupResult? cachedResult;
  final bool isSavedInitially;
  final ValueChanged<WordLookupResult> onCacheResult;
  final ValueChanged<String?> onWordSaved;
  final TtsService tts;

  const WordLookupBottomSheet({
    Key? key,
    required this.word,
    this.cachedResult,
    required this.isSavedInitially,
    required this.onCacheResult,
    required this.onWordSaved,
    required this.tts,
  }) : super(key: key);

  @override
  State<WordLookupBottomSheet> createState() => _WordLookupBottomSheetState();
}

class _WordLookupBottomSheetState extends State<WordLookupBottomSheet> {
  WordLookupResult? _result;
  bool _isLoading = true;
  bool _isSaving = false;
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.isSavedInitially;

    if (widget.cachedResult != null) {
      _result = widget.cachedResult;
      _isLoading = false;
    } else {
      _fetchLookup();
    }
  }

  Future<void> _fetchLookup() async {
    try {
      final res = await ApiClient.instance.lookupWord(widget.word);
      if (!mounted) return;
      setState(() {
        _result = res;
        _isLoading = false;
      });
      widget.onCacheResult(res);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveWord() async {
    if (_isSaved || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final wordId = _result?.wordId;
    if (wordId != null) {
      try {
        final success = await ApiClient.instance.saveWord(wordId);
        if (!mounted) return;
        setState(() {
          _isSaved = success;
          _isSaving = false;
        });
        widget.onWordSaved(wordId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أُضيفت الكلمة إلى قائمة «مفرداتي» بنجاح! ✅'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
        });
      }
    } else {
      setState(() {
        _isSaved = true;
        _isSaving = false;
      });
      widget.onWordSaved(null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أُضيفت الكلمة إلى قائمة «مفرداتي» ✅'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Ltr(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.word,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.blueAccent),
                  tooltip: 'نطق الكلمة',
                  onPressed: () => widget.tts.speak(widget.word),
                ),
                IconButton(
                  icon: const Icon(Icons.speed, color: Colors.white70, size: 20),
                  tooltip: 'نطق بطيء',
                  onPressed: () => widget.tts.speak(widget.word, slow: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_result != null && _result!.found) ...[
            if (_result!.baseWord != null && _result!.baseWord != widget.word.toLowerCase()) ...[
              Ltr(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'الأصل: ${_result!.baseWord}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              _result!.arabic,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ] else ...[
            const Text(
              'لا يتوفر معنى محدد في القاموس لهذه الكلمة بعد.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.tts.speak(widget.word),
                  icon: const Icon(Icons.volume_up, size: 18),
                  label: const Text('استمع'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaved ? null : _saveWord,
                  icon: Icon(_isSaved ? Icons.check : Icons.bookmark_add, size: 18),
                  label: Text(_isSaved ? 'محفوظة ✓' : 'أضف لمفرداتي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSaved ? AppTheme.success : Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
