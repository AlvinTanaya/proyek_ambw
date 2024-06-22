import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  Widget _buildCategoryTab(String category) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: selectedCategory == category ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(25.0),
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: selectedCategory == category ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(DocumentSnapshot item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarketPlaceDetailScreen(
              item: item,
              canEditDelete: false,
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(15.0),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(15.0),
                    ),
                  ),
                  child: Center(
                    child: item['images'] != null && item['images'].isNotEmpty
                        ? Image.network(
                            item['images'][0],
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.image,
                            color: Colors.grey[400],
                            size: 60,
                          ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? 'No Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.attach_money, size: 16, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        item['price']?.toString() ?? 'N/A',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                SizedBox(width: 8.0),
                _buildCategoryTab('All'),
                SizedBox(width: 8.0),
                _buildCategoryTab('Electronics'),
                SizedBox(width: 8.0),
                _buildCategoryTab('Automobile'),
                SizedBox(width: 8.0),
                _buildCategoryTab('Gaming'),
                SizedBox(width: 8.0),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  'Today\'s picks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                InkWell(
                  onTap: _showLocationsDialog,
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.black),
                      SizedBox(width: 4),
                      Text(
                        selectedLocation == 'All'
                            ? 'Select Location'
                            : selectedLocation,
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
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
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildItemCard(items[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60.0), // Adjust the value as needed
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InputMarketPlaceScreen(),
              ),
            );
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }
}
