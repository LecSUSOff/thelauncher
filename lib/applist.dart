import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

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
  static const Color holoCyan = Color(0xFF33B5E5);
  static const Color holoSurface = Color(0xCC181B20);

  String _searchQuery = '';

  Widget _buildAppIcon(AppInfo app) {
    if (app.icon != null) {
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
          Image.memory(
            app.icon!,
            width: 50,
            height: 50,
          ),
        ],
      );
    } else {
      return const Icon(
        Icons.android_rounded,
        size: 50,
        color: holoCyan,
        shadows: [
          Shadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: Offset(0, 3.5),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final qApps = widget.apps.where((app) {
      return app.name.toLowerCase().contains(_searchQuery);
    }).toList();

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
            child: Column(
              children: [
                // Top Holo cyan gradient accent line
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

                // Search Bar with glass surface styling
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: SearchBar(
                    hintText: "Search apps...",
                    hintStyle: WidgetStateProperty.all(
                      TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                        letterSpacing: 0.4,
                      ),
                    ),
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
                    },
                  ),
                ),

                // Subtle glowing separator
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

                // App Grid
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
                        onTap: () => InstalledApps.startApp(app.packageName),
                        onLongPress: () {
                          final bool isPinned = widget.pinnedApps.any(
                            (a) => a.packageName == app.packageName,
                          );

                          showModalBottomSheet(
                            context: context,
                            backgroundColor: const Color(0xFF1E2228),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              side: BorderSide(
                                color: Color(0x3333B5E5),
                                width: 1,
                              ),
                            ),
                            builder: (modalContext) {
                              return SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 4,
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: holoCyan.withValues(alpha: 0.5),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                      ListTile(
                                        leading: Icon(
                                          isPinned
                                              ? Icons.push_pin_rounded
                                              : Icons.push_pin_outlined,
                                          color: holoCyan,
                                        ),
                                        title: Text(
                                          isPinned
                                              ? 'Unpin from Dock'
                                              : 'Pin to Dock',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.pop(modalContext);
                                          widget.onTogglePin(app);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildAppIcon(app),
                            const SizedBox(height: 8),
                            Text(
                              app.name,
                              maxLines: 1,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}