import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'base_screen.dart';
import 'input_marketplace_screen.dart';
import 'marketplace_detail_screen.dart';

class MarketPlaceScreen extends StatefulWidget {
  const MarketPlaceScreen({Key? key}) : super(key: key);

  @override
  _MarketPlaceScreenState createState() => _MarketPlaceScreenState();
}

class _MarketPlaceScreenState extends State<MarketPlaceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String selectedCategory = 'All';
  String selectedLocation = 'All';
  String searchQuery = '';
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  void _showCategoriesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter by Category'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                ListTile(
                  title: Text('All'),
                  onTap: () {
                    setState(() {
                      selectedCategory = 'All';
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text('Electronics'),
                  onTap: () {
                    setState(() {
                      selectedCategory = 'Electronics';
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text('Automobile'),
                  onTap: () {
                    setState(() {
                      selectedCategory = 'Automobile';
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text('Gaming'),
                  onTap: () {
                    setState(() {
                      selectedCategory = 'Gaming';
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLocationsDialog() async {
    var locations = await _firestore.collection('marketplace').get().then(
          (snapshot) =>
              snapshot.docs.map((doc) => doc['location']).toSet().toList(),
        );

    locations.insert(0, 'All'); // Add 'All' to the locations list

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter by Location'),
          content: SingleChildScrollView(
            child: Column(
              children: locations
                  .map((location) => ListTile(
                        title: Text(location),
                        onTap: () {
                          setState(() {
                            selectedLocation = location;
                          });
                          Navigator.of(context).pop();
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  void _startSearch() {
    ModalRoute.of(context)!
        .addLocalHistoryEntry(LocalHistoryEntry(onRemove: _stopSearching));

    setState(() {
      isSearching = true;
    });
  }

  void _stopSearching() {
    _clearSearchQuery();

    setState(() {
      isSearching = false;
    });
  }

  void _clearSearchQuery() {
    setState(() {
      _searchController.clear();
      searchQuery = '';
    });
  }

  Widget _buildTitle(BuildContext context) {
    return Text('Marketplace');
  }

  Widget _buildSearchField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.black54),
          icon: Icon(Icons.search, color: Colors.black54),
        ),
        style: TextStyle(color: Colors.black87, fontSize: 16.0),
        onChanged: (query) => updateSearchQuery(query),
      ),
    );
  }

  List<Widget> _buildActions() {
    if (isSearching) {
      return <Widget>[
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (_searchController.text.isEmpty) {
              Navigator.pop(context);
              return;
            }
            _clearSearchQuery();
          },
        ),
      ];
    }

    return <Widget>[
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: _startSearch,
      ),
    ];
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching ? _buildSearchField() : _buildTitle(context),
        actions: _buildActions(),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text('Today\'s picks',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Spacer(),
                Icon(Icons.location_on),
                InkWell(
                  onTap: _showLocationsDialog,
                  child: Text(
                    selectedLocation == 'All'
                        ? 'Select Location'
                        : selectedLocation,
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => InputMarketPlaceScreen()),
                      );
                    },
                    icon: Icon(Icons.edit),
                    label: Text('Sell'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showCategoriesDialog,
                    icon: Icon(Icons.list),
                    label: Text('Categories'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('marketplace').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var items = snapshot.data!.docs.where((item) {
                  if (selectedCategory != 'All' &&
                      item['category'] != selectedCategory) {
                    return false;
                  }
                  if (selectedLocation != 'All' &&
                      item['location'] != selectedLocation) {
                    return false;
                  }
                  if (searchQuery.isNotEmpty &&
                      !item['name']
                          .toString()
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase())) {
                    return false;
                  }
                  return true;
                }).toList();

                if (items.isEmpty) {
                  return Center(child: Text('No items available.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 3 / 2,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var item = items[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MarketPlaceDetailScreen(
                              item: item,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        child: Column(
                          children: [
                            Expanded(
                              child: item['images'] != null &&
                                      item['images'].isNotEmpty
                                  ? Image.network(
                                      item['images'][0],
                                      fit: BoxFit.cover,
                                    )
                                  : Container(), // Handle missing image
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? 'No Name',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    item['price']?.toString() ?? 'N/A',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BaseScreen(currentIndex: 3),
    );
  }
}
