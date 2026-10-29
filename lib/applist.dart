import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:flutter/services.dart';
import 'smart_search.dart';
import 'dart:async';
import 'core/constants.dart';
import 'core/services/app_service.dart';
import 'core/utils/app_utils.dart';
import 'core/utils/url_utils.dart';
import 'widgets/common/app_icon.dart';
import 'widgets/common/glow_divider.dart';
import 'widgets/common/holo_container.dart';
import 'widgets/app_context_menu.dart';

class AppList extends StatefulWidget {
  final List<AppInfo> apps;
  final List<AppInfo> pinnedApps;
  final List<AppInfo> blockedApps;
  final ValueChanged<AppInfo> onTogglePin;
  final ValueChanged<AppInfo> onToggleBlock;

  const AppList({
    super.key,
    required this.apps,
    required this.pinnedApps,
    required this.blockedApps,
    required this.onTogglePin,
    required this.onToggleBlock,
  });

  @override
  State<AppList> createState() => _AppListState();
}

class _AppListState extends State<AppList> {
  final TextEditingController _searchController = TextEditingController();
  // Using AppColors constants

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
      child: HoloContainer(
        borderRadius: AppDimensions.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.holoCyan.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 0),
          ),
        ],
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              const HoloTopGlow(),

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
                      AppService.launchApp(context, qApps.first.packageName);
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
                    color: AppColors.holoCyan,
                    size: 22,
                  ),
                  backgroundColor: WidgetStateProperty.all(
                    Colors.black.withValues(alpha: 0.35),
                  ),
                  elevation: WidgetStateProperty.all(0),
                  side: WidgetStateProperty.all(
                    BorderSide(
                      color: AppColors.holoCyan.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadiusSmall,
                      ),
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
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.holoCyan,
                          size: 20,
                        ),
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

              const GlowDivider(margin: EdgeInsets.symmetric(horizontal: 16)),
              if (_searchQuery.isNotEmpty &&
                  AppUtils.tryCalculate(_searchQuery) != null)
                ListTile(
                  leading: const Icon(
                    Icons.calculate_rounded,
                    color: Colors.cyan,
                  ),
                  title: Text("=${AppUtils.tryCalculate(_searchQuery)}"),
                  onTap: () {
                    final result = AppUtils.tryCalculate(_searchQuery);
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                        AppService.launchApp(context, app.packageName);
                      },
                      onLongPress: () => AppContextMenu.show(
                        context,
                        app: app,
                        isPinned: widget.pinnedApps.any(
                          (a) => a.packageName == app.packageName,
                        ),
                        isBlocked: widget.blockedApps.any(
                          (a) => a.packageName == app.packageName,
                        ),
                        onTogglePin: widget.onTogglePin,
                        onToggleBlock: widget.onToggleBlock,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(app: app),
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
                    UrlUtils.openWikipedia(def.title);
                  },
                ),
              if (_searchQuery.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.public, color: Colors.cyan),
                  title: Text('Search web for "$_searchQuery"'),
                  onTap: () => UrlUtils.searchTheWeb(_searchQuery),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
