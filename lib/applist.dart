import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:flutter/services.dart';
import 'helpers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:math_expressions/math_expressions.dart' hide Stack;
import 'smartSearch.dart';
import 'dart:async';

String? tryCalculate(String input) {
  if (!input.contains(RegExp(r'[\+\-\*\/\^]'))) return null;

  try {
    Parser p = Parser();
    Expression exp = p.parse(input);
    double result = exp.evaluate(EvaluationType.REAL, ContextModel());

    return result % 1 == 0
        ? result.toInt().toString()
        : result.toStringAsFixed(2);
  } catch (e) {
    return null;
  }
}

void searchTheWeb(String query) async {
  final Uri url = Uri.parse(
    'https://www.google.com/search?q=${Uri.encodeComponent(query)}',
  );
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

class AppList extends StatefulWidget {
  final List<AppInfo> apps;
  final List<AppInfo> pinnedApps;
  final ValueChanged<AppInfo> onTogglePin;

  const AppList({
    super.key,
    required this.apps,
    required this.pinnedApps,
    required this.onTogglePin,
  });

  @override
  State<AppList> createState() => _AppListState();
}

class _AppListState extends State<AppList> {
  final TextEditingController _searchController = TextEditingController();
  static const Color holoCyan = Color(0xFF33B5E5);
  static const Color holoSurface = Color(0xCC181B20);

  String _searchQuery = '';
  Timer? _debounce;
  WikiDefinition? _currentDefinition;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final definition = await fetchDefinition(query);
      setState(() {
        _currentDefinition = definition;
      });
    });
  }

  Widget _buildAppIcon(AppInfo app) {
    if (app.icon == null) {
      return const Icon(
        Icons.android_rounded,
        size: 50,
        color: holoCyan,
        shadows: [
          Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3.5)),
        ],
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(0, 3.5),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
            child: Image.memory(
              app.icon!,
              width: 50,
              height: 50,
              color: Colors.black.withValues(alpha: 0.45),
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ),
        Image.memory(app.icon!, width: 50, height: 50),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final def = _currentDefinition;
    final qApps =
        widget.apps.where((app) {
          return app.name.toLowerCase().contains(_searchQuery);
        }).toList()..sort((a, b) {
          bool aStarts = a.name.toLowerCase().startsWith(_searchQuery);
          bool bStarts = b.name.toLowerCase().startsWith(_searchQuery);
          if (aStarts && !bStarts) return -1;
          if (!aStarts && bStarts) return 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: holoSurface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: holoCyan.withValues(alpha: 0.22),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: holoCyan.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  Container(
                    height: 2,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          holoCyan,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: SearchBar(
                      hintText: "Search everything...",
                      controller: _searchController,
                      hintStyle: WidgetStateProperty.all(
                        TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                          letterSpacing: 0.4,
                        ),
                      ),
                      onSubmitted: (value) {
                        if (qApps.isNotEmpty) {
                          InstalledApps.startApp(qApps.first.packageName);
                        }
                      },
                      textStyle: WidgetStateProperty.all(
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                      leading: const Icon(
                        Icons.search_rounded,
                        color: holoCyan,
                        size: 22,
                      ),
                      backgroundColor: WidgetStateProperty.all(
                        Colors.black.withValues(alpha: 0.35),
                      ),
                      elevation: WidgetStateProperty.all(0),
                      side: WidgetStateProperty.all(
                        BorderSide(
                          color: holoCyan.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (String q) {
                        setState(() {
                          _searchQuery = q.toLowerCase();
                        });
                        onSearchChanged(q);
                      },
                      trailing: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: holoCyan, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _currentDefinition = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),

                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          holoCyan.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty &&
                      tryCalculate(_searchQuery) != null)
                    ListTile(
                      leading: const Icon(
                        Icons.calculate_rounded,
                        color: Colors.cyan,
                      ),
                      title: Text("=${tryCalculate(_searchQuery)}"),
                      onTap: () {
                        final result = tryCalculate(_searchQuery);
                        if (result != null) {
                          Clipboard.setData(ClipboardData(text: result));
                          HapticFeedback.mediumImpact();
                        }
                      },
                    ),
                  Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: qApps.length,
                      itemBuilder: (context, index) {
                        final app = qApps[index];

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            InstalledApps.startApp(app.packageName);
                          },
                          onLongPress: () => showAppContextMenu(
                            context,
                            app: app,
                            isPinned: widget.pinnedApps.any(
                              (a) => a.packageName == app.packageName,
                            ),
                            onTogglePin: widget.onTogglePin,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildAppIcon(app),
                              const SizedBox(height: 8),
                              Text(
                                app.name,
                                maxLines: 10,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  letterSpacing: 0.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty && def != null)
                    ListTile(
                      leading: def.thumbnailUrl != null
                          ? Image.network(
                              def.thumbnailUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.menu_book, color: Colors.cyan),
                      title: Text(def.title),
                      subtitle: Text(
                        def.summary,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        final wikiUrl = Uri.parse(
                          'https://en.wikipedia.org/wiki/${Uri.encodeComponent(def.title)}',
                        );
                        launchUrl(wikiUrl, mode: LaunchMode.externalApplication);
                      },
                    ),
                  if (_searchQuery.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.public, color: Colors.cyan),
                      title: Text('Search web for "$_searchQuery"'),
                      onTap: () => searchTheWeb(_searchQuery),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
