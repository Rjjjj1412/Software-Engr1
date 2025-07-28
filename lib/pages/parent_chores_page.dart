import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'parent_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentChoresPage extends StatefulWidget {
  const ParentChoresPage({super.key});

  @override
  State<ParentChoresPage> createState() => _ParentChoresPageState();
}

class _ParentChoresPageState extends State<ParentChoresPage> {
  List<Map<String, dynamic>> kids = [];
  String? selectedKidId;
  String selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    loadKids();
  }

  Future<void> loadKids() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('kids')
        .where('user_id', isEqualTo: user.uid) // Filter by parent account
        .get();

    setState(() {
      kids = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['firstName'],
          'avatar': doc['avatar'],
        };
      }).toList();

      if (kids.isNotEmpty && selectedKidId == null) {
        selectedKidId = kids.first['id'];
      }
    });
  }

  Future<List<Map<String, dynamic>>> fetchChores() async {
    if (selectedKidId == null) return [];

    final query = FirebaseFirestore.instance
        .collection('chores')
        .where('kid_id', isEqualTo: selectedKidId);

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'title': doc['chore_title'],
        'description': doc['chore_desc'],
        'reward': doc['reward_money'],
        'status': doc['status'],
      };
    }).where((chore) {
      if (selectedStatus == 'All') return true;
      return chore['status'] == selectedStatus.toLowerCase();
    }).toList();
  }

  /// Map status to colors
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange; // 🟠 Pending
      case 'completed':
        return Colors.green; // 🟢 Completed
      case 'rewarded':
        return Colors.blue; // 🔵 Confirmed
      default:
        return Colors.grey; // Default color
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {},
      child: Scaffold(
        drawer: const ParentDrawer(selectedPage: 'chores'),
        backgroundColor: const Color(0xFFFFCA26),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFCA26),
          elevation: 0,
          title: Text(
            "Chores",
            style: GoogleFonts.fredoka(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          leading: Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.only(left: 12, right: 4, top: 5, bottom: 10),
              child: InkWell(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.menu,
                    color: Color(0xFFFFCA26),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Kid Selector
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: kids.length,
                  itemBuilder: (context, index) {
                    final kid = kids[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedKidId = kid['id'];
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedKidId == kid['id'] ? Colors.black : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage(kid['avatar']),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Status Filter Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  DropdownButton<String>(
                    value: selectedStatus,
                    items: ['All', 'Pending', 'Completed', 'Rewarded'].map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(
                          status,
                          style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedStatus = value;
                        });
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Chore List
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchChores(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final chores = snapshot.data!;
                    if (chores.isEmpty) {
                      return Center(
                        child: Text(
                          "No chores found.",
                          style: GoogleFonts.fredoka(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2D0),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: ListView.builder(
                        itemCount: chores.length,
                        itemBuilder: (context, index) {
                          final chore = chores[index];
                          final statusColor = getStatusColor(chore['status']);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.assignment, color: Colors.black),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        chore['title'],
                                        style: GoogleFonts.fredoka(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        chore['description'],
                                        style: GoogleFonts.fredoka(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "\$${chore['reward'].toStringAsFixed(2)}",
                                      style: GoogleFonts.fredoka(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      chore['status'][0].toUpperCase() + chore['status'].substring(1),
                                      style: GoogleFonts.fredoka(
                                        color: statusColor, // Dynamic status color
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
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
