import 'package:flutter/material.dart';

import '../models/learning_models.dart';
import '../theme/app_theme.dart';

class AppScrollPage extends StatelessWidget {
  const AppScrollPage({
    super.key,
    required this.title,
    required this.children,
    this.leading,
    this.showTitle = true,
  });

  final String title;
  final List<Widget> children;
  final Widget? leading;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (showTitle)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 12)],
                  Expanded(child: Text(title, style: AppText.pageTitle)),
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, showTitle ? 24 : 20, 20, 140),
          sliver: SliverList.separated(
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
            separatorBuilder: (_, _) => const SizedBox(height: 16),
          ),
        ),
      ],
    );
  }
}

class CardPanel extends StatelessWidget {
  const CardPanel({
    super.key,
    this.title,
    this.icon,
    this.action,
    required this.child,
  });

  final String? title;
  final IconData? icon;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: AppColors.text, size: 24),
                    const SizedBox(width: 10),
                  ],
                  Expanded(child: Text(title!, style: AppText.sectionTitle)),
                  ?action,
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class GradientPanel extends StatelessWidget {
  const GradientPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.teal, AppColors.indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        child: child,
      ),
    );
  }
}

class NumberedLine extends StatelessWidget {
  const NumberedLine({super.key, required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.indigo,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppText.bodyLarge)),
        ],
      ),
    );
  }
}

class KeywordTile extends StatelessWidget {
  const KeywordTile({super.key, required this.word, required this.onTap});

  final KeyWord word;
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
          hoverColor: AppColors.teal.withValues(alpha: 0.06),
          splashColor: AppColors.teal.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          Text(word.word, style: AppText.sectionBig),
                          Text(word.phonetic, style: AppText.muted),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SmallChip(label: word.priority),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ],
                ),
                const SizedBox(height: 6),
                Text(word.meaning, style: AppText.accent),
                const SizedBox(height: 6),
                Text(word.usage),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(word.example, style: AppText.muted)),
                    const SizedBox(width: 10),
                    Text('查看详情', style: AppText.chip),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GrammarTile extends StatelessWidget {
  const GrammarTile({super.key, required this.point});

  final GrammarPoint point;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.page,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(point.pattern, style: AppText.emphasis),
          const SizedBox(height: 8),
          Text(point.meaning, style: AppText.accent),
          const SizedBox(height: 10),
          Text(point.example, style: AppText.bodyLarge),
          const SizedBox(height: 8),
          Text(point.note, style: AppText.muted),
        ],
      ),
    );
  }
}

class ThemeTile extends StatelessWidget {
  const ThemeTile({
    super.key,
    required this.theme,
    required this.onTap,
    this.isFavorite = false,
    this.wasUsed = false,
  });

  final LearningTheme theme;
  final VoidCallback onTap;
  final bool isFavorite;
  final bool wasUsed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.teal.withValues(alpha: 0.04),
        splashColor: AppColors.teal.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(theme.title, style: AppText.sectionBig)),
                  if (isFavorite) ...[
                    const Icon(Icons.bookmark, size: 18, color: AppColors.teal),
                    const SizedBox(width: 6),
                  ],
                  Text(theme.kind.label, style: AppText.accent),
                ],
              ),
              const SizedBox(height: 6),
              Text(theme.stage.label, style: AppText.stage),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (_isReferenceTheme(theme)) const SmallChip(label: '本地参考'),
                  if (_isReferenceTheme(theme) || _isCustomTheme(theme))
                    const SmallChip(label: '原创练习'),
                  if (_isCustomTheme(theme)) const SmallChip(label: '手动素材'),
                ],
              ),
              if (_isReferenceTheme(theme) || _isCustomTheme(theme))
                const SizedBox(height: 6),
              Text(theme.sourceHint, style: AppText.muted),
              const SizedBox(height: 6),
              Text(theme.focus),
              if (wasUsed) ...[
                const SizedBox(height: 6),
                const Text('最近已用于今日练习', style: AppText.muted),
              ],
              const SizedBox(height: 6),
              Text(theme.difficulty, style: AppText.muted),
            ],
          ),
        ),
      ),
    );
  }

  bool _isReferenceTheme(LearningTheme theme) {
    return theme.sourceHint.contains('本地参考');
  }

  bool _isCustomTheme(LearningTheme theme) {
    return theme.sourceHint.contains('手动');
  }
}

class StageChip extends StatelessWidget {
  const StageChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.teal,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.text,
          fontWeight: FontWeight.w800,
        ),
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: selected ? AppColors.teal : AppColors.line,
          width: 1.2,
        ),
      ),
    );
  }
}

class ScoreBar extends StatelessWidget {
  const ScoreBar({super.key, required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(label, style: AppText.emphasis),
              const Spacer(),
              Text('$value', style: AppText.muted),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 7,
              backgroundColor: AppColors.line,
              valueColor: AlwaysStoppedAnimation<Color>(
                value >= 80 ? AppColors.teal : AppColors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WritingFeedback extends StatelessWidget {
  const WritingFeedback({
    super.key,
    required this.title,
    required this.reference,
    required this.note,
  });

  final String title;
  final String reference;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.subtle,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.emphasis),
          const SizedBox(height: 6),
          Text(reference),
          const SizedBox(height: 6),
          Text(note, style: AppText.muted),
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.muted),
          const SizedBox(height: 8),
          Text(value, style: AppText.metric),
        ],
      ),
    );
  }
}

class ChunkTile extends StatelessWidget {
  const ChunkTile({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: AppText.emphasis),
    );
  }
}

class BulletLine extends StatelessWidget {
  const BulletLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text, this.dark = false});

  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: dark ? AppColors.indigo : Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class SmallChip extends StatelessWidget {
  const SmallChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label, style: AppText.chip),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onPressed,
    this.large = false,
  });

  final IconData icon;
  final String text;
  final VoidCallback onPressed;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: large ? 22 : null),
      label: Text(
        text,
        style: TextStyle(
          fontSize: large ? 17 : null,
          fontWeight: large ? FontWeight.w900 : null,
        ),
      ),
      style: FilledButton.styleFrom(
        minimumSize: Size(0, large ? 58 : 48),
        padding: EdgeInsets.symmetric(
          horizontal: large ? 22 : 16,
          vertical: large ? 16 : 12,
        ),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        elevation: large ? 1 : 0,
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({super.key, required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
      ),
    );
  }
}
