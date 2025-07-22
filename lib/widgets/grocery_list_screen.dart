import 'dart:convert';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/config/firebase_config.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item_screen.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  // Class variables.
  String? _error;
  bool isLoading = true;
  List<GroceryItem> _groceryItems = [];

  // Class Methods.
  @override
  void initState() {
    super.initState();
    _loadInitialItems();
  }

  Category searchCategoryObject(targetTitle) {
    final catItem = categories.entries.firstWhere((element) => element.value.title == targetTitle);
    return catItem.value;
  }

  void _loadInitialItems() async {
    final url = Uri.https(FirebaseConfig.firebaseURL, 'shopping-list.json');
    final receivedResponse = await http.get(url);
    print('Response we have is ${receivedResponse.body}');

    // Check for HTTP Errors.
    if (receivedResponse.statusCode >= 400) {
      setState(() {
        _error = 'Failed to Fetch Data ! Restart Internet Connection !!';
      });
    }

    if (receivedResponse.body == 'null') {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final Map<String, dynamic> mapOfResponses = json.decode(receivedResponse.body);


    // Store the gotten firebase data
    // into the Grocery Item List.
    final List<GroceryItem> loadedItems = [];

    for (final item in mapOfResponses.entries) {
      final categoryObjectCorrespondingToTitle = searchCategoryObject(item.value['category']);

      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: categoryObjectCorrespondingToTitle,
        ),
      );
    }

    // Update the UI
    // with the loaded items.
    setState(() {
      _groceryItems = loadedItems;
      isLoading = false;
    });
  }

  void _addItem() async {
    // Store the returned Grocery Item
    // from the new_item_screen.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const NewItem();
        },
      ),
    );
    _loadInitialItems();
  }

  void removeItem(index) async {
    final itemToRemove = _groceryItems[index];

    // Delete and rebuild the UI
    // With the locally updated list.
    setState(() {
      _groceryItems.removeAt(index);
    });

    // Then delete From Firebase as well.
    final url = Uri.https(FirebaseConfig.firebaseURL, 'shopping-list/${itemToRemove.id}.json');

    final response = await http.delete(url);

    // Undo the deletion in the local list
    // if the item couldn't be deleted from
    // the firebase.
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, itemToRemove);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Method variable.

    // When there is no grocery items in the list.
    Widget mainContent = const Center(child: Text('No items added yet.'));

    // When waiting for the grocery items to load from the firebase.
    if (isLoading) {
      mainContent = const Center(child: CircularProgressIndicator());
    }

    // When we do have some items in the list.
    if (_groceryItems.isNotEmpty) {
      mainContent = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: ValueKey(_groceryItems[index].id),
            onDismissed: (direction) {
              removeItem(index);
            },
            child: ListTile(
              title: Text(_groceryItems[index].name),
              leading: Container(width: 24, height: 24, color: _groceryItems[index].category.color),
              trailing: Text(_groceryItems[index].quantity.toString()),
            ),
          );
        },
      );
    }

    if (_error != null) {
      mainContent = Center(child: Text(_error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: mainContent,
    );
  }
}
