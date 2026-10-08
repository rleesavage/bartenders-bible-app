import 'package:flutter/material.dart';

import 'api.dart';
import 'auth_screens.dart';
import 'screens.dart';
import 'theme.dart';
import 'widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final api = Api();
  await api.loadToken();

  runApp(BartendersBibleApp(api: api));
}

class BartendersBibleApp extends StatefulWidget {
  final Api api;

  const BartendersBibleApp({super.key, required this.api});

  @override
  State<BartendersBibleApp> createState() => _BartendersBibleAppState();
}

class _BartendersBibleAppState extends State<BartendersBibleApp> {
  bool? loggedIn;
  bool register = false;
  BbPage page = BbPage.home;

  int? detailId;
  String? detailName;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    if (widget.api.token == null) {
      setState(() => loggedIn = false);
      return;
    }

    try {
      await widget.api.get('me.php');
      if (mounted) setState(() => loggedIn = true);
    } catch (_) {
      await widget.api.clearToken();
      if (mounted) setState(() => loggedIn = false);
    }
  }

  Future<void> logout() async {
    await widget.api.logout();
    if (!mounted) return;

    setState(() {
      loggedIn = false;
      register = false;
      page = BbPage.home;
      detailId = null;
      detailName = null;
    });
  }

  void openDrink(int id, String name) {
    setState(() {
      detailId = id;
      detailName = name;
    });
  }

  void go(BbPage next) {
    setState(() {
      detailId = null;
      detailName = null;
      page = next;
    });
  }

  Widget pageBody() {
    if (detailId != null) {
      return DrinkDetailScreen(
        api: widget.api,
        id: detailId!,
        name: detailName ?? 'Drink Detail',
      );
    }

    switch (page) {
      case BbPage.home:
        return HomeScreen(api: widget.api, openDrink: openDrink);
      case BbPage.drinks:
        return DrinksScreen(api: widget.api, openDrink: openDrink);
      case BbPage.encyclopedia:
        return EncyclopediaScreen(api: widget.api);
      case BbPage.notebook:
        return NotebookScreen(api: widget.api);
      case BbPage.search:
        return SearchScreen(api: widget.api, openDrink: openDrink);
      case BbPage.about:
        return AboutScreen(api: widget.api);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Bartender's Bible",
      theme: bbTheme(),
      home: loggedIn == null
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : loggedIn == false
              ? register
                  ? RegisterScreen(
                      api: widget.api,
                      back: () => setState(() => register = false),
                    )
                  : LoginScreen(
                      api: widget.api,
                      onLogin: () => setState(() => loggedIn = true),
                      create: () => setState(() => register = true),
                    )
              : PopScope(
                  canPop: detailId == null,
                  onPopInvokedWithResult: (didPop, _) {
                    if (!didPop && detailId != null) {
                      setState(() {
                        detailId = null;
                        detailName = null;
                      });
                    }
                  },
                  child: PageFrame(
                    page: detailId == null ? page : null,
                    go: go,
                    logout: logout,
                    child: pageBody(),
                  ),
                ),
    );
  }
}
