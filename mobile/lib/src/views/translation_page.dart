import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/speech_service.dart';
import '../services/translation_history_store.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class TranslationPage extends StatefulWidget {
  const TranslationPage({super.key, this.speechClient});

  final SpeechClient? speechClient;

  @override
  State<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  final input = TextEditingController(text: '我想要一杯咖啡');
  final translator = const TranslationService();
  final translationGateway = const TranslationGateway();
  final historyStore = const TranslationHistoryStore();
  late final SpeechClient speechClient;
  TranslationResult? result;
  List<TranslationHistoryItem> history = const [];
  String? message;
  bool isTranslating = false;

  @override
  void initState() {
    super.initState();
    speechClient = widget.speechClient ?? SpeechService();
    result = translator.translate(input.text);
    saveCurrentResult();
    loadHistory();
  }

  @override
  void dispose() {
    input.dispose();
    speechClient.stop();
    super.dispose();
  }

  Future<void> loadHistory() async {
    final loaded = await historyStore.load();
    if (!mounted) return;

    setState(() => history = loaded);
  }

  Future<void> saveCurrentResult() async {
    final current = result;
    if (current == null || current.source.isEmpty) return;

    await historyStore.save(current);
  }

  Future<void> translate() async {
    setState(() {
      isTranslating = true;
      message = '正在生成翻译...';
    });

    final response = await translationGateway.translate(input.text);
    final translated = response.result;
    if (!mounted) return;

    setState(() {
      result = translated;
      message = response.source.label;
      isTranslating = false;
    });
    await historyStore.save(translated);
    await loadHistory();
  }

  void useHistory(TranslationHistoryItem item) {
    input.text = item.result.source;
    setState(() {
      result = item.result;
      message = null;
    });
  }

  Future<void> speak(String text, String locale) async {
    try {
      await speechClient.speak(text, locale: locale);
      if (!mounted) return;
      setState(() => message = '正在朗读');
    } catch (error) {
      if (!mounted) return;
      setState(() => message = '当前设备暂时无法朗读：$error');
    }
  }

  Future<void> copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;

    setState(() => message = '已复制');
  }

  @override
  Widget build(BuildContext context) {
    final current = result;

    return AppScrollPage(
      title: '翻译',
      children: [
        CardPanel(
          title: '中文输入',
          icon: Icons.translate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: input,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: '输入中文，例如：我想要一杯咖啡',
                  filled: true,
                  fillColor: AppColors.page,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                icon: isTranslating ? Icons.hourglass_top : Icons.auto_awesome,
                text: isTranslating ? '生成中' : '生成翻译',
                onPressed: isTranslating ? () {} : translate,
              ),
              if (message != null) ...[
                const SizedBox(height: 10),
                Text(message!, style: AppText.muted),
              ],
            ],
          ),
        ),
        if (current != null && current.source.isNotEmpty) ...[
          TranslationResultCard(
            title: '英文',
            subtitle: '自然表达',
            text: current.english,
            buttonText: '朗读英文',
            onCopy: () => copyText(current.english),
            onSpeak: () => speak(current.english, 'en-US'),
          ),
          TranslationResultCard(
            title: '韩文敬语',
            subtitle: '陌生人、长辈、正式场景',
            text: current.koreanHonorific,
            pronunciation: current.koreanPronunciation.split(' / ').first,
            buttonText: '朗读敬语',
            onCopy: () => copyText(current.koreanHonorific),
            onSpeak: () => speak(current.koreanHonorific, 'ko-KR'),
          ),
          TranslationResultCard(
            title: '韩文平语',
            subtitle: '朋友、同龄人、亲近关系',
            text: current.koreanCasual,
            pronunciation: current.koreanPronunciation.split(' / ').last,
            buttonText: '朗读平语',
            onCopy: () => copyText(current.koreanCasual),
            onSpeak: () => speak(current.koreanCasual, 'ko-KR'),
          ),
          CardPanel(
            title: '使用提醒',
            icon: Icons.lightbulb_outline,
            child: Text(current.usageNote, style: AppText.bodyLarge),
          ),
        ],
        if (history.isNotEmpty)
          CardPanel(
            title: '最近翻译',
            icon: Icons.history,
            child: Column(
              children: [
                for (final item in history.take(5))
                  TranslationHistoryTile(
                    item: item,
                    onTap: () => useHistory(item),
                  ),
                SecondaryButton(
                  icon: Icons.delete_outline,
                  text: '清空历史',
                  onPressed: () async {
                    await historyStore.clear();
                    await loadHistory();
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class TranslationHistoryTile extends StatelessWidget {
  const TranslationHistoryTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  final TranslationHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.subtle,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.result.source, style: AppText.emphasis),
                      const SizedBox(height: 4),
                      Text(item.result.english, style: AppText.muted),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TranslationResultCard extends StatelessWidget {
  const TranslationResultCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.text,
    required this.buttonText,
    required this.onCopy,
    required this.onSpeak,
    this.pronunciation,
  });

  final String title;
  final String subtitle;
  final String text;
  final String buttonText;
  final VoidCallback onCopy;
  final VoidCallback onSpeak;
  final String? pronunciation;

  @override
  Widget build(BuildContext context) {
    return CardPanel(
      title: title,
      icon: Icons.record_voice_over_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: AppText.muted),
          const SizedBox(height: 8),
          Text(text, style: AppText.sectionBig),
          if (pronunciation != null) ...[
            const SizedBox(height: 8),
            Text('读音：$pronunciation', style: AppText.accent),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  icon: Icons.copy,
                  text: '复制',
                  onPressed: onCopy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SecondaryButton(
                  icon: Icons.volume_up_outlined,
                  text: buttonText,
                  onPressed: onSpeak,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
