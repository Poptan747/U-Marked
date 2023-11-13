import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:getwidget/getwidget.dart';
import 'package:u_marked/reusable_widget/appBar.dart';
import 'package:u_marked/reusable_widget/bottomSheet.dart';

class locationList extends StatefulWidget {
  @override
  _locationListState createState() => _locationListState();
}

class _locationListState extends State<locationList> {
  final int rowsPerPage = 10;
  int currentPage = 0;
  int totalDocs = 0;
  int endIndex = 0;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: locationListAppBar(context),
      body: SafeArea(
        child: Container(
          color: Colors.lightBlue.shade50,
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    // Update the search query and reset currentPage to 0
                    setState(() {
                      searchQuery = value;
                      currentPage = 0;
                    });
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('locations').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator(); // Loading indicator
                    }

                    List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
                    List<QueryDocumentSnapshot> filteredDocs = [];

                    // Filter data based on search query
                    if (searchQuery.isNotEmpty) {
                      filteredDocs = docs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return data['roomNo'].toLowerCase().contains(searchQuery.toLowerCase()) ||
                            data['building'].toLowerCase().contains(searchQuery.toLowerCase());
                      }).toList();
                    } else {
                      filteredDocs = List.from(docs);
                    }

                    totalDocs = filteredDocs.length;

                    // Paginate data
                    int startIndex = currentPage * rowsPerPage;
                    endIndex = (currentPage + 1) * rowsPerPage;
                    if (endIndex > filteredDocs.length) {
                      endIndex = filteredDocs.length;
                    }

                    List<DataRow> rows = [];
                    for (int i = startIndex; i < endIndex; i++) {
                      var doc = filteredDocs[i];
                      var documentID = doc.id;
                      var data = filteredDocs[i].data() as Map<String, dynamic>;
                      rows.add(
                        DataRow(
                          cells: [
                            DataCell(Text(data['roomNo'])),
                            DataCell(Text(data['building'])),
                            DataCell(
                              GFButton(
                                  shape: GFButtonShape.pills,
                                  elevation: 2,
                                  size: GFSize.SMALL,
                                  child: Text('Modify'),
                                  onPressed: (){
                                    showModalBottomSheet(
                                      isScrollControlled: true,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Padding(
                                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                          child: editLocationBottomSheet(locationId: documentID),
                                        );
                                      },
                                    );
                                  }
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        child: DataTable(
                          columnSpacing: 30,
                          columns: const [
                            DataColumn(label: Text('Room Name')),
                            DataColumn(label: Text('Building')),
                            DataColumn(label: Text('Action')),
                          ],
                          rows: rows,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_back),
            label: 'Previous Page',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_forward),
            label: 'Next Page',
          ),
        ],
        onTap: (index) {
          if (index == 0 && currentPage > 0) {
            setState(() {
              currentPage--;
            });
          } else if (index == 1 && endIndex < totalDocs) {
            setState(() {
              currentPage++;
            });
          }
        },
      ),
    );
  }
}
