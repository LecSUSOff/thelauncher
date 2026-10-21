import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'dart:ui' as ui;

class AppList extends StatefulWidget {
  final List<AppInfo> apps;
  String _searchQuery = ''; 
  AppList({super.key, required this.apps});

  @override
  State<AppList> createState() => _AppListState();
}

class _AppListState extends State<AppList> {
  @override
  Widget build(BuildContext context) {
    final qApps = widget.apps.where((app) {
      return app.name.toLowerCase().contains(widget._searchQuery);
    }).toList();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          color: Colors.white.withValues(alpha: 0.75),
          child: Column(
            children: [
              SearchBar(
                hintText: "Search anything...",
                onChanged: (String q) {
                setState(() {
                  widget._searchQuery = q.toLowerCase(); // lowercase it for matching
                });
              },
              ),
              Divider(),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                    childAspectRatio: 1,
                  ),
                  itemCount: qApps.length,
                  itemBuilder: (context, index) {
                    final app = qApps[index];
                      
                    return GestureDetector(
                      onTap: () => InstalledApps.startApp(app.packageName),
                      onLongPress: () => InstalledApps.openSettings(app.packageName),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (app.icon != null)
                            Image.memory(app.icon!, width: 56, height: 56)
                          else
                            const Icon(Icons.android, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            app.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
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
    );
  }
}
