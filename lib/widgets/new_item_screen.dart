import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});
  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> {
  // Class variable.
  final _formKey = GlobalKey<FormState>();
  int _enteredQuantity = 1;
  String _enteredName = '';
  Category _selectedCategory = categories[Categories.vegetables]!;
  var _isSending = false;

  // Class Method.
  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // If data is being sent to the
      // firebase, show loading circle
      // and disable the btns.
      setState(() {
        _isSending = true;
      });

      // Push Data to Firebase when Saved.
      final url = Uri.https('flutter-test-64387-default-rtdb.firebaseio.com', 'shopping-list.json');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': _enteredName, 'quantity': _enteredQuantity, 'category': _selectedCategory.title}),
      );

      print(response.body);
      print(response.statusCode);

      if (!context.mounted) {
        return;
      }

      Navigator.pop(context);
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a new item')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name Field
              TextFormField(
                maxLength: 50,
                decoration: InputDecoration(label: Text('Name')),
                validator: (value) {
                  if (value == null || value.isEmpty || value.trim().length <= 1 || value.trim().length >= 50) {
                    return 'Must be between 1 and 50 characters.';
                  }
                  return null;
                },
                onSaved: (newValue) {
                  _enteredName = newValue!;
                },
              ),

              // Row For Qty and DropDown.
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Qty. Text Field.
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(label: Text('Quantity')),
                      initialValue: _enteredQuantity.toString(),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Valid Positive Number is Expected !!';
                        }
                        return null;
                      },
                      onSaved: (newValue) {
                        _enteredQuantity = int.parse(newValue!);
                      },
                    ),
                  ),

                  // Horizontal Spacing.
                  SizedBox(width: 8),

                  // Form DropDown Field.
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                // Category Color
                                Container(width: 16, height: 16, color: category.value.color),

                                // Horizontal Space
                                SizedBox(width: 6),

                                // Category Name
                                Text(category.value.title),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (newCategoryValue) {
                        _selectedCategory = newCategoryValue!;
                      },
                    ),
                  ),
                ],
              ),

              // Vertical Space.
              const SizedBox(height: 18),

              // Button Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending? null : (){
                      _resetForm();
                    }, 
                    child: const Text('Reset')
                  ),
                  ElevatedButton(
                    onPressed: _isSending? null : (){
                      _saveItem();
                    }, 
                    child: 
                    _isSending? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(),
                    ) : 
                    const Text('Add Item')
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
