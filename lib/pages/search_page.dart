import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/search_provider.dart';
import '../models/animal.dart';
import 'animal_details.dart';
import '../transitions/page_transitions.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SearchProvider>(context, listen: false).init(context);
    });
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        Provider.of<SearchProvider>(context, listen: false).clearSearch();
      },
      child: Scaffold(
        appBar: AppBar(
          title: _SearchField(),
          backgroundColor: Colors.orangeAccent,
        ),
        body: Consumer<SearchProvider>(
          builder: (context, searchProvider, child) {
            if (searchProvider.isSearching) {
              return _SearchResults();
            }
            return _SearchHistory();
          },
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);

    return TextField(
      controller: searchProvider.searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'search_hint'.tr(),
        border: InputBorder.none,
        hintStyle: const TextStyle(color: Colors.white70),
        suffixIcon: searchProvider.isSearching
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: () {
                  searchProvider.clearSearch();
                },
              )
            : null,
      ),
      style: const TextStyle(color: Colors.white),
    );
  }
}

class _SearchResults extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        if (searchProvider.searchResults.isEmpty) {
          return Center(
            child: Text('no_results_found'.tr()),
          );
        }

        return ListView.builder(
          itemCount: searchProvider.searchResults.length,
          itemBuilder: (context, index) {
            final animal = searchProvider.searchResults[index];
            return _AnimalListItem(animal: animal);
          },
        );
      },
    );
  }
}

class _SearchHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        if (searchProvider.searchHistory.isEmpty) {
          return Center(
            child: Text('no_search_history'.tr()),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'recent_searches'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => searchProvider.clearHistory(),
                    child: Text('clear_all'.tr()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: searchProvider.searchHistory.length,
                itemBuilder: (context, index) {
                  final query = searchProvider.searchHistory[index];
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(query),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => searchProvider.removeFromHistory(query),
                    ),
                    onTap: () {
                      searchProvider.searchFromHistory(query);
                    },
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

class _AnimalListItem extends StatelessWidget {
  final Animal animal;

  const _AnimalListItem({required this.animal});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.asset(
        animal.imagePath,
        width: 50,
        height: 50,
      ),
      title: Text(animal.name.tr()),
      subtitle: Text(
        animal.description.tr(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        Provider.of<SearchProvider>(context, listen: false)
            .addToHistory(animal.name.tr());
        Navigator.push(
          context,
          PageTransitions.createScaleTransition(
            AnimalDetailsPage(animal: animal),
          ),
        );
      },
    );
  }
}
