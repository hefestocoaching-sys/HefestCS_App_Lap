import 'package:flutter/material.dart';

class ClinicClientHeaderWithTabs extends StatelessWidget {
  final Widget avatar;
  final String name;
  final String subtitle;
  final List<Widget> chipsRight;
  final TabController tabController;
  final List<Tab> tabs;

  const ClinicClientHeaderWithTabs({
    super.key,
    required this.avatar,
    required this.name,
    required this.subtitle,
    required this.chipsRight,
    required this.tabController,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderRow(
                name: name,
                subtitle: subtitle,
                avatar: avatar,
                chipsRight: chipsRight,
              ),
              const SizedBox(height: 20),
              _TabBar(tabController: tabController, tabs: tabs),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final Widget avatar;
  final List<Widget> chipsRight;

  const _HeaderRow({
    required this.name,
    required this.subtitle,
    required this.avatar,
    required this.chipsRight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ProfileAvatar(avatar: avatar),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: chipsRight),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final Widget avatar;

  const _ProfileAvatar({required this.avatar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: Center(child: avatar),
    );
  }
}

class _TabBar extends StatelessWidget {
  final TabController tabController;
  final List<Tab> tabs;

  const _TabBar({required this.tabController, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final currentIndex = tabController.index;

        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              tabs.length,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _TabItem(
                  label: tabs[index].text ?? '',
                  selected: currentIndex == index,
                  onTap: () => tabController.animateTo(index),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: selected
                ? Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)
                : Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 3,
            width: selected ? 28 : 0,
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
