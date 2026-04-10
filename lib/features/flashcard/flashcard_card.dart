import 'dart:math';

import 'package:flutter/material.dart';
import '../../app.dart';
import '../../core/db/database.dart';
import '../../core/tts/tts_service.dart';

class FlashcardCard extends StatefulWidget {
  final Word word;
  final bool isFlipped;
  final VoidCallback onFlip;
  final String? aiExplanation;
  final bool aiLoading;
  final TtsService ttsService;
  final String ttsLang;

  const FlashcardCard({
    super.key,
    required this.word,
    required this.isFlipped,
    required this.onFlip,
    this.aiExplanation,
    this.aiLoading = false,
    required this.ttsService,
    required this.ttsLang,
  });

  @override
  State<FlashcardCard> createState() => _FlashcardCardState();
}

class _FlashcardCardState extends State<FlashcardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(FlashcardCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
    if (widget.word.word != oldWidget.word.word) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onFlip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (_, child) {
          final angle = _animation.value * pi;
          final isFront = angle < pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isFront ? _buildFront() : _buildBack(),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.word.word,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
            if (widget.word.phonetic != null &&
                widget.word.phonetic!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.word.phonetic!,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
            if (widget.word.romanization != null &&
                widget.word.romanization!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '[${widget.word.romanization}]',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
            if (widget.word.partOfSpeech != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: enColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.word.partOfSpeech!,
                  style: const TextStyle(
                      fontSize: 13, color: enColor, fontWeight: FontWeight.w500),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.word.audioUs != null &&
                    widget.word.audioUs!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: enColor),
                    onPressed: () => widget.ttsService.speak(
                      widget.word.word,
                      audioUrl: widget.word.audioUs,
                      ttsLang: widget.ttsLang,
                    ),
                    tooltip: 'US',
                  ),
                if (widget.word.audioUk != null &&
                    widget.word.audioUk!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: krColor),
                    onPressed: () => widget.ttsService.speak(
                      widget.word.word,
                      audioUrl: widget.word.audioUk,
                      ttsLang: widget.ttsLang,
                    ),
                    tooltip: 'UK',
                  ),
                if ((widget.word.audioUs == null ||
                        widget.word.audioUs!.isEmpty) &&
                    (widget.word.audioUk == null ||
                        widget.word.audioUk!.isEmpty))
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: enColor),
                    onPressed: () => widget.ttsService.speak(
                      widget.word.word,
                      ttsLang: widget.ttsLang,
                    ),
                  ),
              ],
            ),
            if (widget.word.definition != null &&
                widget.word.definition!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  widget.word.definition!,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Nhan de xem vi du',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(pi),
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.word.word,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.word.definition != null)
                  Text(
                    widget.word.definition!,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                if (widget.word.example != null &&
                    widget.word.example!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('📝 ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            widget.word.example!,
                            style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700]),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up, size: 20),
                          onPressed: () => widget.ttsService.speakSentence(
                            widget.word.example!,
                            ttsLang: widget.ttsLang,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.aiLoading) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(strokeWidth: 2),
                  const SizedBox(height: 8),
                  Text('AI dang suy nghi...',
                      style: TextStyle(color: Colors.grey[500])),
                ],
                if (widget.aiExplanation != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: secondaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: secondaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 16, color: secondaryColor),
                            SizedBox(width: 4),
                            Text('AI giai thich',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: secondaryColor)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(widget.aiExplanation!,
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
