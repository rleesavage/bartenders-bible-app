import 'package:flutter/material.dart';

import 'theme.dart';

enum BbPage { home, drinks, encyclopedia, notebook, search, about }

class BbHeader extends StatelessWidget {
  const BbHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
      decoration: const BoxDecoration(
        color: BbColors.brown,
        border: Border(bottom: BorderSide(color: BbColors.gold, width: 2)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 46,
                height: 46,
                child: Image.asset(
                  'assets/header_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  "Bartender's Bible",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: BbColors.goldLight,
                        fontFamily: 'cursive',
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .4,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'DRINKS · HISTORY · TECHNIQUE · STORIES · BAR NOTES',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: BbColors.parchmentDeep,
              fontSize: 9,
              letterSpacing: .7,
            ),
          ),
        ],
      ),
    );
  }
}

class BbFooter extends StatelessWidget {
  final BbPage? current;
  final void Function(BbPage) go;
  final VoidCallback logout;

  const BbFooter({
    super.key,
    required this.current,
    required this.go,
    required this.logout,
  });

  @override
  Widget build(BuildContext context) {
    final items = <BbPage, String>{
      BbPage.home: 'Home',
      BbPage.drinks: 'Drinks',
      BbPage.encyclopedia: 'Encyclopedia',
      BbPage.notebook: 'My Notebook',
      BbPage.search: 'Search Drinks',
      BbPage.about: 'About',
    };

    final links = items.entries
        .where((entry) => current == null || entry.key != current)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      decoration: const BoxDecoration(
        color: BbColors.brown,
        border: Border(top: BorderSide(color: BbColors.gold, width: 2)),
      ),
      child: Column(
        children: <Widget>[
          LayoutBuilder(
            builder: (context, constraints) {
              final count = links.length + 1;
              final gap = 5.0;
              final width =
                  (constraints.maxWidth - gap * (count - 1)) / count;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  for (final entry in links)
                    SizedBox(
                      width: width,
                      child: _FooterButton(
                        label: entry.value,
                        onTap: () => go(entry.key),
                      ),
                    ),
                  SizedBox(
                    width: width,
                    child: _FooterButton(
                      label: 'Log Out',
                      onTap: logout,
                      dark: true,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 5),
          const Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Webolium',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    color: BbColors.parchment,
                    fontWeight: FontWeight.bold,
                    fontSize: 8.5,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Bartenders Bible v1.0',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    color: BbColors.parchment,
                    fontStyle: FontStyle.italic,
                    fontSize: 8,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '© RL Savage 2026',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    color: BbColors.parchment,
                    fontSize: 8,
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

class _FooterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool dark;

  const _FooterButton({
    required this.label,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        backgroundColor: dark ? const Color(0xff2c1d12) : BbColors.brown2,
        foregroundColor: BbColors.goldLight,
        side: const BorderSide(color: BbColors.gold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        textStyle: const TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, maxLines: 1),
      ),
    );
  }
}

class PageFrame extends StatelessWidget {
  final BbPage? page;
  final Widget child;
  final void Function(BbPage) go;
  final VoidCallback logout;

  const PageFrame({
    super.key,
    required this.page,
    required this.child,
    required this.go,
    required this.logout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const BbHeader(),
            Expanded(child: child),
            BbFooter(current: page, go: go, logout: logout),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionTitle(this.title, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }
}

class ErrorPanel extends StatelessWidget {
  final Object error;
  final VoidCallback? retry;

  const ErrorPanel({super.key, required this.error, this.retry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(error.toString(), textAlign: TextAlign.center),
                if (retry != null) ...<Widget>[
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: retry, child: const Text('Try Again')),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
