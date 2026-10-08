import 'package:flutter/material.dart';

import '../../core/network/api_service.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';

/// A row of round category shortcuts. The first tile opens the full list.
class CategoryRail extends StatelessWidget {
  const CategoryRail({
    super.key,
    required this.categories,
    required this.onSelect,
    this.onSale,
  });

  final List<Category> categories;
  final ValueChanged<Category> onSelect;
  final VoidCallback? onSale;

  void _openAll(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                IanovaSpacing.xl,
                0,
                IanovaSpacing.xl,
                IanovaSpacing.xl,
              ),
              children: [
                Text(
                  'All categories',
                  style: Theme.of(sheetContext).textTheme.headlineSmall,
                ),
                const SizedBox(height: IanovaSpacing.sm),
                for (final category in categories)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      category.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onSelect(category);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty && onSale == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: IanovaSpacing.lg),
        children: [
          if (categories.isNotEmpty)
            _RailTile(
            label: 'All',
            filled: true,
            onTap: () => _openAll(context),
            child: const Icon(
              Icons.grid_view_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          if (onSale != null)
            _RailTile(
              label: 'Sale',
              filled: false,
              background: IanovaColors.danger,
              onTap: onSale!,
              child: const Icon(
                Icons.local_offer_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          for (final category in categories)
            _RailTile(
              label: category.name,
              filled: false,
              onTap: () => onSelect(category),
              child: Text(
                category.emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
        ],
      ),
    );
  }
}

class _RailTile extends StatelessWidget {
  const _RailTile({
    required this.label,
    required this.filled,
    required this.onTap,
    required this.child,
    this.background,
  });

  final Color? background;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(IanovaSpacing.radiusMedium),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background ??
                    (filled ? IanovaColors.primary : IanovaColors.soft),
                shape: BoxShape.circle,
              ),
              child: child,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
