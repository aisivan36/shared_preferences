import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_dropdown.dart';
import '../colors.dart';

class RecipeList extends StatefulWidget {
  const RecipeList({Key? key}) : super(key: key);

  @override
  _RecipeListState createState() => _RecipeListState();
}

class _RecipeListState extends State<RecipeList> {
  /// All preferences need to use a unique  key or they will be overwritten.
  /// Here we're simply  defining a constant fo the preferences key
  static const String prefSearchKey = 'previousSearches';
  late TextEditingController searchTextController;
  final ScrollController _scrollController = ScrollController();
  List currentSearchList = [];
  int currentCount = 0;
  int currentStartPosition = 0;
  int currentEndPosition = 20;
  int pageCount = 20;
  bool hasMore = false;
  bool loading = false;
  bool inErrorState = false;

  /// Clears the way for us to save the user's previous searches and keep track
  /// of the current search
  List<String> previousSearches = <String>[];

  @override
  void initState() {
    super.initState();

    ///[getPreviousSearches]
    ///This loads any previous searches when the user restart the app
    getPreviousSearches();
    searchTextController = TextEditingController(text: '');
    _scrollController
      ..addListener(() {
        final triggerFetchMoreSize =
            0.7 * _scrollController.position.maxScrollExtent;

        if (_scrollController.position.pixels > triggerFetchMoreSize) {
          if (hasMore &&
              currentEndPosition < currentCount &&
              !loading &&
              !inErrorState) {
            setState(() {
              loading = true;
              currentStartPosition = currentEndPosition;
              currentEndPosition =
                  min(currentStartPosition + pageCount, currentCount);
            });
          }
        }
      });
  }

  @override
  void dispose() {
    searchTextController.dispose();
    super.dispose();
  }

  void savePreviouseSearches() async {
    // uses the await keyword to wait for an instace of SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    // Saves the list of previous searches using the prefSearchKey key
    prefs.setStringList(prefSearchKey, previousSearches);
  }

  void getPreviousSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(prefSearchKey)) {
      final searches = prefs.getStringList(prefSearchKey);

      /// If the list is not null, set the previous searches,
      /// otherwise initialize an empty list
      if (searches != null) {
        previousSearches = searches;
      } else {
        previousSearches = <String>[];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _buildSearchCard(),
            _buildRecipeLoader(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 4,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0))),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            IconButton(
              // Add on presed to handle tap event
              onPressed: () {
                // use the current search text to start a search
                startSearch(searchTextController.text);
                // hide the keyboard by using the FocusScope class
                final currentFocus = FocusScope.of(context);
                if (!currentFocus.hasPrimaryFocus) {
                  currentFocus.unfocus();
                }
              },
              icon: const Icon(Icons.search),
            ),
            const SizedBox(
              width: 6.0,
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      // Field To enter the search
                      child: TextField(
                    decoration: const InputDecoration(
                        border: InputBorder.none, hintText: 'Search'),
                    autofocus: false,

                    /// Set keyboard action to [TextInputAction.done]
                    //this closes the keyboard when the user presses the Done
                    /// button
                    textInputAction: TextInputAction.done,

                    /// Save the search when the user finishes entering text
                    onSubmitted: (value) {
                      if (!previousSearches.contains(value)) {
                        previousSearches.add(value);
                        savePreviouseSearches();
                      }
                    },
                    controller: searchTextController,
                  )),

                  ///Create [PopMenuButton] to sign previous search
                  PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: lightGrey,
                      ),

                      /// when the user selects an item from previous searches
                      /// start a new search
                      onSelected: (String value) {
                        searchTextController.text = value;
                        startSearch(searchTextController.text);
                      },
                      itemBuilder: (BuildContext context) {
                        /// Build a list of custom drop-down menu to display
                        /// previous searches
                        return previousSearches
                            .map<CustomDropdownMenuItem<String>>(
                                (String value) {
                          return CustomDropdownMenuItem<String>(
                            value: value,
                            text: value,
                            callback: () {
                              setState(() {
                                /// If the [X] Icon is pressed,
                                /// removedthe search from the previous searches
                                /// and close the pop-up menu
                                previousSearches.remove(value);
                                Navigator.pop(context);
                              });
                            },
                          );
                        }).toList();
                      })
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void startSearch(String value) {
    /// [setSatet] triggers the widgets to rebuild
    setState(() {
      // Clear the current search list and reset the count,
      // start and end positions
      currentSearchList.clear();
      currentCount = 0;
      currentEndPosition = pageCount;
      currentStartPosition = 0;
      hasMore = true;
      value = value.trim();

      ///Check to ensure the search text has not already been added
      /// to the previous search list
      if (!previousSearches.contains(value)) {
        //Add the search item to the previous search list
        previousSearches.add(value);
        // save the new list of previous searches
        savePreviouseSearches();
      }
    });
  }

  Widget _buildRecipeLoader(BuildContext context) {
    if (searchTextController.text.length < 3) {
      return Container();
    }
    // Show a loading indicator while waiting for the movies
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
