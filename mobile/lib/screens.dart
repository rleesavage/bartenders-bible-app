import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'theme.dart';
import 'widgets.dart';

typedef OpenDrink = void Function(int id, String name);

class JsonFuture extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final Widget Function(Map<String, dynamic>) builder;

  const JsonFuture({
    super.key,
    required this.future,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorPanel(error: snapshot.error!);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return builder(snapshot.data!);
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Api api;
  final OpenDrink openDrink;

  const HomeScreen({
    super.key,
    required this.api,
    required this.openDrink,
  });

  @override
  Widget build(BuildContext context) {
    return JsonFuture(
      future: api.get('home.php'),
      builder: (data) {
        final featured = data['featured'] as Map<String, dynamic>?;

        return ListView(
          padding: const EdgeInsets.all(18),
          children: <Widget>[
            if (featured != null) ...<Widget>[
              Text(
                featured['name'].toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 2),
              const Text(
                "Today's Highlighted Drink",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: BbColors.brown2,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 14),
              if (featured['hero_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.network(
                    featured['hero_url'].toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 12),
              if ((featured['short_description'] ?? '')
                  .toString()
                  .trim()
                  .isNotEmpty)
                Text(
                  featured['short_description'].toString(),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => openDrink(
                  featured['id'] as int,
                  featured['name'].toString(),
                ),
                child: const Text('See Full Drink Detail'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class DrinksScreen extends StatefulWidget {
  final Api api;
  final OpenDrink openDrink;

  const DrinksScreen({
    super.key,
    required this.api,
    required this.openDrink,
  });

  @override
  State<DrinksScreen> createState() => _DrinksScreenState();
}

class _DrinksScreenState extends State<DrinksScreen> {
  late Future<Map<String, dynamic>> future;
  final filter = TextEditingController();
  String query = '';

  @override
  void initState() {
    super.initState();
    future = widget.api.get('drinks.php');
  }

  @override
  void dispose() {
    filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return JsonFuture(
      future: future,
      builder: (data) {
        final all =
            (data['drinks'] as List).cast<Map<String, dynamic>>();
        final q = query.toLowerCase().trim();
        final rows = q.isEmpty
            ? all
            : all
                .where(
                  (d) => d['name'].toString().toLowerCase().contains(q),
                )
                .toList();

        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: TextField(
                controller: filter,
                onChanged: (value) => setState(() => query = value),
                decoration: InputDecoration(
                  labelText: 'Search for Drinks',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            filter.clear();
                            setState(() => query = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${rows.length} drink${rows.length == 1 ? '' : 's'}'),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final drink = rows[index];

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    leading: _DrinkThumb(
                      url: (drink['thumb_url'] ?? drink['hero_url'])?.toString(),
                    ),
                    title: Text(
                      drink['name'].toString(),
                      style: const TextStyle(
                        color: BbColors.brown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: (drink['short_description'] ?? '')
                            .toString()
                            .trim()
                            .isEmpty
                        ? null
                        : Text(
                            drink['short_description'].toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => widget.openDrink(
                      drink['id'] as int,
                      drink['name'].toString(),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DrinkThumb extends StatelessWidget {
  final String? url;

  const _DrinkThumb({this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 64,
      decoration: BoxDecoration(
        color: BbColors.parchmentLight,
        border: Border.all(color: BbColors.gold),
      ),
      child: url == null || url!.isEmpty
          ? const Icon(Icons.local_bar, color: BbColors.brown2)
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.local_bar, color: BbColors.brown2),
            ),
    );
  }
}

class DrinkDetailScreen extends StatefulWidget {
  final Api api;
  final int id;
  final String name;

  const DrinkDetailScreen({
    super.key,
    required this.api,
    required this.id,
    required this.name,
  });

  @override
  State<DrinkDetailScreen> createState() => _DrinkDetailScreenState();
}

class _DrinkDetailScreenState extends State<DrinkDetailScreen> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return widget.api.get('drink.php', <String, String>{
      'id': widget.id.toString(),
    });
  }

  void reload() {
    setState(() => future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return JsonFuture(
      future: future,
      builder: (data) {
        final drink = data['drink'] as Map<String, dynamic>;
        final recipes = (data['recipes'] as List).cast<Map<String, dynamic>>();
        final talk = (data['bar_talk'] as List).cast<Map<String, dynamic>>();
        final science =
            ((data['science_notes'] ?? <dynamic>[]) as List)
                .cast<Map<String, dynamic>>();
        final food =
            (data['food_pairings'] as List).cast<Map<String, dynamic>>();
        final notes =
            (data['bar_notes'] as List).cast<Map<String, dynamic>>();
        final myNotes =
            (data['my_notebook'] as List).cast<Map<String, dynamic>>();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              drink['name'].toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if ((drink['pronunciation'] ?? '').toString().trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  drink['pronunciation'].toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: BbColors.muted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            if (drink['hero_url'] != null) ...<Widget>[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: SizedBox(
                    width: double.infinity,
                    child: Image.network(
                      drink['hero_url'].toString(),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ],
            if ((drink['short_description'] ?? '')
                .toString()
                .trim()
                .isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(drink['short_description'].toString()),
            ],
            for (final recipe in recipes)
              _RecipeBlock(recipe: recipe, drinkName: drink['name'].toString()),
            if (science.isNotEmpty)
              _ExpandableListSection(
                title: 'The Science',
                rows: science,
                titleOf: (row) => (row['title'] ?? 'The Science').toString(),
                bodyOf: (row) {
                  final parts = <String>[
                    if ((row['lead'] ?? '').toString().trim().isNotEmpty)
                      row['lead'].toString(),
                    if ((row['definition'] ?? '').toString().trim().isNotEmpty)
                      row['definition'].toString(),
                    if ((row['evidence'] ?? '').toString().trim().isNotEmpty)
                      'Drawn from: ${row['evidence']}',
                  ];
                  return parts.join('\n\n');
                },
              ),
            if (food.isNotEmpty)
              _ExpandableListSection(
                title: 'Food Pairings',
                rows: food,
                titleOf: (row) => row['pairing_name'].toString(),
                bodyOf: (row) {
                  final parts = <String>[
                    if ((row['description'] ?? '').toString().trim().isNotEmpty)
                      row['description'].toString(),
                    if ((row['wine_recommendation'] ?? '')
                        .toString()
                        .trim()
                        .isNotEmpty)
                      'Wine: ${row['wine_recommendation']}',
                  ];
                  return parts.join('\n\n');
                },
              ),
            if (talk.isNotEmpty)
              _ExpandableListSection(
                title: 'Bar Talk',
                rows: talk,
                titleOf: (row) => (row['heading'] ?? 'Bar Talk').toString(),
                bodyOf: (row) => (row['body'] ?? '').toString(),
              ),
            if (notes.isNotEmpty)
              _ExpandableListSection(
                title: 'Bar Notes',
                rows: notes,
                titleOf: (row) => row['title'].toString(),
                bodyOf: (row) {
                  final parts = <String>[
                    if ((row['body'] ?? '').toString().trim().isNotEmpty)
                      row['body'].toString(),
                    if ((row['flourish'] ?? '').toString().trim().isNotEmpty)
                      'Flourish: ${row['flourish']}',
                  ];
                  return parts.join('\n\n');
                },
              ),
            const SizedBox(height: 8),
            const Divider(height: 30),
            const SectionTitle(
              'My Notebook',
              subtitle:
                  'The same private notebook reached from the app navigation.',
            ),
            if (myNotes.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'No personal notes are attached to this drink yet.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final note in myNotes)
                Card(
                  child: ExpansionTile(
                    title: Text(note['title'].toString()),
                    subtitle: Text(
                      (note['entry_type'] ?? 'note').toString(),
                    ),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Text(note['body'].toString()),
                      ),
                    ],
                  ),
                ),
            ElevatedButton.icon(
              onPressed: () => _addNotebookEntry(context),
              icon: const Icon(Icons.edit_note),
              label: const Text('Add Note for This Drink'),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Future<void> _addNotebookEntry(BuildContext context) async {
    final title = TextEditingController();
    final body = TextEditingController();
    String type = 'note';

    final save = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('My Notebook — ${widget.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Entry Type'),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: 'note', child: Text('Note')),
                      DropdownMenuItem(value: 'recipe', child: Text('Recipe')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => type = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: body,
                    minLines: 5,
                    maxLines: 9,
                    decoration: const InputDecoration(
                      labelText: 'Note or recipe',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (save == true && title.text.trim().isNotEmpty && body.text.trim().isNotEmpty) {
      await widget.api.post('notebook.php', <String, dynamic>{
        'title': title.text,
        'body': body.text,
        'entry_type': type,
        'drink_id': widget.id,
      });
      if (mounted) reload();
    }

    title.dispose();
    body.dispose();
  }
}

class _RecipeBlock extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final String drinkName;

  const _RecipeBlock({
    required this.recipe,
    required this.drinkName,
  });

  String displayTitle() {
    final raw = recipe['name'].toString().trim();
    final lower = raw.toLowerCase();

    // Normalize every house-recipe title that still contains a Bartender's
    // Bible/Bartenders Bible branding variant.
    final isBibleHouse =
        lower.contains('bartender') && lower.contains('bible');

    if (!isBibleHouse) return raw;

    final qualifiers = <String>[];
    if (lower.contains('primary')) qualifiers.add('Primary');
    if (lower.contains('standard')) qualifiers.add('Standard');
    if (lower.contains('service')) qualifiers.add('Service');

    final suffix =
        qualifiers.isEmpty ? '' : ' — ${qualifiers.join(' / ')}';

    return '$drinkName — House Recipe$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final ingredients =
        (recipe['ingredients'] as List).cast<Map<String, dynamic>>();

    String amount(Map<String, dynamic> row) {
      final text = (row['amount_text'] ?? '').toString().trim();
      if (text.isNotEmpty) return text;

      final number = (row['amount'] ?? '').toString().trim();
      final unit = (row['unit'] ?? '').toString().trim();
      return '$number $unit'.trim();
    }

    final specs = <String>[
      if ((recipe['glassware_name'] ?? '').toString().trim().isNotEmpty)
        'Glassware: ${recipe['glassware_name']}',
      if ((recipe['garnish_name'] ?? '').toString().trim().isNotEmpty)
        'Garnish: ${recipe['garnish_name']}',
      if ((recipe['technique_name'] ?? '').toString().trim().isNotEmpty)
        'Technique: ${recipe['technique_name']}',
      if ((recipe['serve_ice'] ?? '').toString().trim().isNotEmpty)
        'Ice: ${recipe['serve_ice']}',
    ];

    final detailNotes = <MapEntry<String, dynamic>>[
      MapEntry('Service', recipe['service_notes']),
      MapEntry('Ice Notes', recipe['ice_notes']),
      MapEntry('Garnish Notes', recipe['garnish_notes']),
      MapEntry('Glassware Notes', recipe['glassware_notes']),
      MapEntry('Flourish', recipe['flourish']),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Divider(height: 32),
        Text(
          displayTitle(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        for (final ingredient in ingredients)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '• ${amount(ingredient)} ${ingredient['name']}'
              '${(ingredient['preparation'] ?? '').toString().trim().isEmpty ? '' : ' — ${ingredient['preparation']}'}',
            ),
          ),
        if ((recipe['instructions'] ?? '').toString().trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Text(recipe['instructions'].toString()),
        ],
        if (specs.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(specs.join('\n')),
            ),
          ),
        ],
        for (final item in detailNotes)
          if ((item.value ?? '').toString().trim().isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(item.key),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                  child: Text(item.value.toString()),
                ),
              ],
            ),
      ],
    );
  }
}

class _ExpandableListSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> rows;
  final String Function(Map<String, dynamic>) titleOf;
  final String Function(Map<String, dynamic>) bodyOf;

  const _ExpandableListSection({
    required this.title,
    required this.rows,
    required this.titleOf,
    required this.bodyOf,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Divider(height: 34),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        for (final row in rows)
          Card(
            child: ExpansionTile(
              title: Text(titleOf(row)),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Text(bodyOf(row)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class EncyclopediaScreen extends StatefulWidget {
  final Api api;

  const EncyclopediaScreen({super.key, required this.api});

  @override
  State<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends State<EncyclopediaScreen> {
  final query = TextEditingController();
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.get('encyclopedia.php');
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  void search() {
    setState(() {
      future = widget.api.get(
        'encyclopedia.php',
        query.text.trim().isEmpty
            ? null
            : <String, String>{'q': query.text.trim()},
      );
    });
  }

  Future<void> openEntry(Map<String, dynamic> item) async {
    try {
      final data = await widget.api.get(
        'encyclopedia.php',
        <String, String>{'id': item['id'].toString()},
      );
      if (!mounted) return;
      final entry = data['entry'] as Map<String, dynamic>;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(entry['term'].toString()),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if ((entry['short_definition'] ?? '')
                    .toString()
                    .trim()
                    .isNotEmpty)
                  Text(
                    entry['short_definition'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                if ((entry['body'] ?? '').toString().trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(entry['body'].toString()),
                ],
                if ((entry['common_mistakes'] ?? '')
                    .toString()
                    .trim()
                    .isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    'Common Mistakes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(entry['common_mistakes'].toString()),
                ],
                if ((entry['see_also'] ?? '').toString().trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text('See Also: ${entry['see_also']}'),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: query,
                  onSubmitted: (_) => search(),
                  decoration: const InputDecoration(
                    labelText: 'Search Encyclopedia',
                    prefixIcon: Icon(Icons.menu_book),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: search,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        Expanded(
          child: JsonFuture(
            future: future,
            builder: (data) {
              final rows =
                  (data['entries'] as List).cast<Map<String, dynamic>>();

              return ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = rows[index];
                  return ListTile(
                    title: Text(
                      entry['term'].toString(),
                      style: const TextStyle(
                        color: BbColors.brown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      (entry['short_definition'] ?? '').toString(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openEntry(entry),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class NotebookScreen extends StatefulWidget {
  final Api api;

  const NotebookScreen({super.key, required this.api});

  @override
  State<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends State<NotebookScreen> {
  final query = TextEditingController();
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() {
    final q = query.text.trim();
    return widget.api.get(
      'notebook.php',
      q.isEmpty ? null : <String, String>{'q': q},
    );
  }

  void reload() {
    setState(() => future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: query,
                  onSubmitted: (_) => reload(),
                  decoration: const InputDecoration(
                    labelText: 'Search My Notebook',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: reload,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _editEntry(context),
              icon: const Icon(Icons.note_add),
              label: const Text('Add to My Notebook'),
            ),
          ),
        ),
        Expanded(
          child: JsonFuture(
            future: future,
            builder: (data) {
              final rows =
                  (data['entries'] as List).cast<Map<String, dynamic>>();

              if (rows.isEmpty) {
                return const Center(child: Text('No notebook entries found.'));
              }

              return ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final entry = rows[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    child: ExpansionTile(
                      title: Text(entry['title'].toString()),
                      subtitle: Text(
                        <String>[
                          (entry['entry_type'] ?? 'note').toString(),
                          if ((entry['drink_name'] ?? '')
                              .toString()
                              .trim()
                              .isNotEmpty)
                            entry['drink_name'].toString(),
                        ].join(' · '),
                      ),
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(entry['body'].toString()),
                          ),
                        ),
                        ButtonBar(
                          children: <Widget>[
                            TextButton.icon(
                              onPressed: () => _deleteEntry(
                                entry['id'] as int,
                                entry['title'].toString(),
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _editEntry(BuildContext context) async {
    final title = TextEditingController();
    final body = TextEditingController();
    String type = 'note';

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add to My Notebook'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Entry Type'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'note', child: Text('Note')),
                    DropdownMenuItem(value: 'recipe', child: Text('Recipe')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => type = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: body,
                  minLines: 5,
                  maxLines: 9,
                  decoration: const InputDecoration(
                    labelText: 'Note or recipe',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (save == true && title.text.trim().isNotEmpty && body.text.trim().isNotEmpty) {
      await widget.api.post('notebook.php', <String, dynamic>{
        'title': title.text,
        'body': body.text,
        'entry_type': type,
      });
      if (mounted) reload();
    }

    title.dispose();
    body.dispose();
  }

  Future<void> _deleteEntry(int id, String title) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notebook Entry?'),
        content: Text(title),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (yes == true) {
      await widget.api.delete('notebook.php', <String, dynamic>{'id': id});
      if (mounted) reload();
    }
  }
}

class SearchScreen extends StatefulWidget {
  final Api api;
  final OpenDrink openDrink;

  const SearchScreen({
    super.key,
    required this.api,
    required this.openDrink,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final query = TextEditingController();
  final speech = SpeechToText();

  bool listening = false;
  bool busy = false;
  String? error;

  List<Map<String, dynamic>> results = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> detected = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> alcohols = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> mixers = <Map<String, dynamic>>[];
  List<String> occasions = <String>[];

  final List<int?> chosenAlcohols = <int?>[null, null, null, null];
  final List<int?> chosenMixers = <int?>[null, null, null];
  String? chosenOccasion;
  List<Map<String, dynamic>> suggestions = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  @override
  void dispose() {
    query.dispose();
    speech.stop();
    super.dispose();
  }

  Future<void> _loadVocabulary() async {
    try {
      final data = await widget.api.post(
        'search.php',
        <String, dynamic>{'mode': 'search', 'name': ''},
      );
      if (!mounted) return;
      setState(() {
        alcohols =
            (data['alcohols'] as List).cast<Map<String, dynamic>>();
        mixers = (data['mixers'] as List).cast<Map<String, dynamic>>();
        occasions =
            (data['occasions'] as List).map((e) => e.toString()).toList();
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> search({String? voice}) async {
    setState(() {
      busy = true;
      error = null;
    });

    try {
      final data = await widget.api.post('search.php', <String, dynamic>{
        'mode': 'search',
        'name': voice == null ? query.text : '',
        'voice': voice ?? '',
      });

      if (!mounted) return;
      setState(() {
        results =
            (data['results'] as List).cast<Map<String, dynamic>>();
        detected = (data['detected_ingredients'] as List)
            .cast<Map<String, dynamic>>();
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> microphone({bool forSuggestions = false}) async {
    if (listening) {
      await speech.stop();
      if (mounted) setState(() => listening = false);
      return;
    }

    final available = await speech.initialize(
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => listening = false);
        }
      },
      onError: (problem) {
        if (mounted) {
          setState(() {
            listening = false;
            error = problem.errorMsg;
          });
        }
      },
    );

    if (!available) {
      setState(() => error = 'Speech recognition is not available on this device.');
      return;
    }

    setState(() {
      listening = true;
      error = null;
    });

    await speech.listen(
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.search,
        partialResults: true,
      ),
      onResult: (result) {
        query.text = result.recognizedWords;
        query.selection = TextSelection.collapsed(offset: query.text.length);
        if (result.finalResult) {
          if (forSuggestions) {
            createSuggestion(voice: result.recognizedWords);
          } else {
            search(voice: result.recognizedWords);
          }
        }
      },
    );
  }

  Future<void> createSuggestion({String? voice}) async {
    setState(() {
      busy = true;
      error = null;
    });

    try {
      final data = await widget.api.post('search.php', <String, dynamic>{
        'mode': 'create',
        'voice': voice ?? '',
        'alcohol_ids':
            chosenAlcohols.whereType<int>().toList(),
        'mixer_ids':
            chosenMixers.whereType<int>().toList(),
        'occasion': chosenOccasion ?? '',
      });

      if (!mounted) return;
      setState(() {
        suggestions = (data['suggestions'] as List)
            .cast<Map<String, dynamic>>();
        detected = (data['detected_ingredients'] as List)
            .cast<Map<String, dynamic>>();

        if (voice != null && voice.trim().isNotEmpty) {
          final selected =
              (data['selected'] as Map).cast<String, dynamic>();
          final a = (selected['alcohol_ids'] as List)
              .map((e) => e as int)
              .toList();
          final m = (selected['mixer_ids'] as List)
              .map((e) => e as int)
              .toList();

          for (var i = 0; i < chosenAlcohols.length; i++) {
            chosenAlcohols[i] = i < a.length ? a[i] : null;
          }
          for (var i = 0; i < chosenMixers.length; i++) {
            chosenMixers[i] = i < m.length ? m[i] : null;
          }

          final spokenOccasion = (selected['occasion'] ?? '').toString();
          chosenOccasion =
              spokenOccasion.isEmpty ? null : spokenOccasion;
        }
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  bool _duplicate(List<int?> list, int index, int? value) {
    if (value == null) return false;
    for (var i = 0; i < list.length; i++) {
      if (i != index && list[i] == value) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: <Widget>[
        const SectionTitle(
          'Search the Full Bar',
          subtitle:
              'Type a drink name, or tap the microphone and ask for what you want.',
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: query,
                onSubmitted: (_) => search(),
                decoration: const InputDecoration(
                  hintText: 'Manhattan, bourbon, lime…',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => microphone(),
              icon: Icon(listening ? Icons.mic : Icons.mic_none),
              tooltip: listening ? 'Stop Listening' : 'Voice Search',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: busy ? null : () => search(),
          child: Text(busy ? 'Searching…' : 'Search Drinks'),
        ),
        if (listening)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Listening… speak naturally.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: BbColors.brown,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (detected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Recognized ingredients: '
              '${detected.map((x) => x['name']).join(', ')}',
              textAlign: TextAlign.center,
            ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        if (results.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            '${results.length} Search Result${results.length == 1 ? '' : 's'}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final drink in results)
            Card(
              child: ListTile(
                leading: _DrinkThumb(
                      url: (drink['thumb_url'] ?? drink['hero_url'])?.toString(),
                    ),
                title: Text(drink['name'].toString()),
                subtitle: (drink['short_description'] ?? '')
                        .toString()
                        .trim()
                        .isEmpty
                    ? null
                    : Text(
                        drink['short_description'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => widget.openDrink(
                  drink['id'] as int,
                  drink['name'].toString(),
                ),
              ),
            ),
        ],
        const Divider(height: 38),
        const SectionTitle(
          'Create a Drink Suggestion',
          subtitle:
              'Choose what you have, or use voice search to describe the ingredients.',
        ),
        for (var i = 0; i < chosenAlcohols.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              value: chosenAlcohols[i],
              decoration: InputDecoration(
                labelText: i == 0
                    ? 'Primary Alcohol'
                    : 'Optional Alcohol ${i + 1}',
              ),
              items: <DropdownMenuItem<int>>[
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('None'),
                ),
                ...alcohols.map(
                  (item) => DropdownMenuItem<int>(
                    value: item['id'] as int,
                    child: Text(
                      item['name'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                if (_duplicate(chosenAlcohols, i, value)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('That alcohol is already selected.'),
                    ),
                  );
                  return;
                }
                setState(() => chosenAlcohols[i] = value);
              },
            ),
          ),
        for (var i = 0; i < chosenMixers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              value: chosenMixers[i],
              decoration: InputDecoration(labelText: 'Mixer ${i + 1}'),
              items: <DropdownMenuItem<int>>[
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('None'),
                ),
                ...mixers.map(
                  (item) => DropdownMenuItem<int>(
                    value: item['id'] as int,
                    child: Text(
                      item['name'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                if (_duplicate(chosenMixers, i, value)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('That mixer is already selected.'),
                    ),
                  );
                  return;
                }
                setState(() => chosenMixers[i] = value);
              },
            ),
          ),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: chosenOccasion,
          decoration: const InputDecoration(labelText: 'Occasion'),
          items: <DropdownMenuItem<String>>[
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Any'),
            ),
            ...occasions.map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (value) => setState(() => chosenOccasion = value),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: busy ? null : () => createSuggestion(),
          child: const Text('Suggest Drinks'),
        ),
        TextButton.icon(
          onPressed: busy
              ? null
              : () => microphone(forSuggestions: true),
          icon: Icon(listening ? Icons.mic : Icons.mic_none),
          label: const Text('Speak Ingredients for Suggestions'),
        ),
        if (suggestions.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          for (final suggestion in suggestions)
            _SuggestionCard(
              suggestion: suggestion,
              openDrink: widget.openDrink,
            ),
        ],
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final Map<String, dynamic> suggestion;
  final OpenDrink openDrink;

  const _SuggestionCard({
    required this.suggestion,
    required this.openDrink,
  });

  @override
  Widget build(BuildContext context) {
    final ingredients =
        (suggestion['ingredients'] as List).cast<Map<String, dynamic>>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              suggestion['drink_name'].toString(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if ((suggestion['short_description'] ?? '')
                .toString()
                .trim()
                .isNotEmpty) ...<Widget>[
              const SizedBox(height: 5),
              Text(suggestion['short_description'].toString()),
            ],
            const SizedBox(height: 8),
            for (final ingredient in ingredients)
              Text(
                '• ${(ingredient['amount_text'] ?? '').toString()} '
                '${ingredient['name']}',
              ),
            if ((suggestion['instructions'] ?? '')
                .toString()
                .trim()
                .isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(suggestion['instructions'].toString()),
            ],
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => openDrink(
                suggestion['drink_id'] as int,
                suggestion['drink_name'].toString(),
              ),
              child: const Text('See Full Drink'),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutScreen extends StatefulWidget {
  final Api api;

  const AboutScreen({super.key, required this.api});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool deleting = false;

  Future<void> _openWebAbout() async {
    final uri = Uri.parse('https://www.webolium.com/bartenders/about.html');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the web page.')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete My Account?'),
        content: const Text(
          'This permanently deletes your Bartender’s Bible account, '
          'your private My Notebook entries, and your active app login tokens. '
          'This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => deleting = true);
    try {
      await widget.api.delete('delete-account.php', <String, dynamic>{
        'confirm': 'DELETE',
      });

      if (!mounted) return;

      // The user row and every API token are gone at this point. Returning to
      // the app's authentication flow happens naturally when the next
      // authenticated request fails or the user logs out of the shell.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account and private notebook have been deleted.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return JsonFuture(
      future: widget.api.get('about.php'),
      builder: (data) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(
              data['title'].toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(height: 28),
            for (final paragraph in data['paragraphs'] as List)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(paragraph.toString()),
              ),

            const Divider(height: 30),
            const SectionTitle('Privacy & Account Data'),
            const Text(
              'Your account stores your name, verified email address, password '
              'hash, login/security information, and the private entries you '
              'create in My Notebook. Passwords are not stored in readable form.',
            ),
            const SizedBox(height: 10),
            const Text(
              'My Notebook belongs to the logged-in user. Your private notebook '
              'entries are not shared with other Bartender’s Bible users.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openWebAbout,
              icon: const Icon(Icons.privacy_tip_outlined),
              label: const Text('Privacy / Account Information'),
            ),

            const Divider(height: 30),
            const SectionTitle('Delete My Account'),
            const Text(
              'You can permanently delete your Bartender’s Bible account here. '
              'Deleting the account also deletes your private My Notebook '
              'entries and invalidates your app login tokens.',
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: deleting ? null : _deleteAccount,
              icon: const Icon(Icons.delete_forever),
              label: Text(deleting ? 'Deleting…' : 'Delete My Account'),
            ),

            const Divider(height: 30),
            const SectionTitle('About This App'),
            const Text(
              'Webolium',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Bartenders Bible v1.0',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const Text(
              '© RL Savage 2026',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }
}
