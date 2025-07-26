import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kids_drawer.dart';

class KidsChoresPage extends StatefulWidget {
  final String kidId;

  const KidsChoresPage({
    super.key,
    required this.kidId,
  });

  @override
  State<KidsChoresPage> createState() => _KidsChoresPageState();
}

class _KidsChoresPageState extends State<KidsChoresPage> {
  String kidName = '';
  String avatarPath = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchKidInfo();
  }

  Future<void> fetchKidInfo() async {
    try {
      final kidSnapshot = await FirebaseFirestore.instance
          .collection('kids')
          .doc(widget.kidId)
          .get();

      if (kidSnapshot.exists) {
        final kidData = kidSnapshot.data()!;
        setState(() {
          kidName = kidData['firstName'] ?? 'Kid';
          avatarPath = kidData['avatar'] ?? 'assets/avatar1.png';
        });
      }
    } catch (e) {
      debugPrint('Error fetching kid info: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Stream<List<Map<String, dynamic>>> getChoresStream() {
    return FirebaseFirestore.instance
        .collection('chores')
        .where('kid_id', isEqualTo: widget.kidId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return {
                'id': doc.id,
                'title': doc['chore_title'],
                'description': doc['chore_desc'],
                'reward': doc['reward_money'],
                'status': doc['status'], // pending, completed, rewarded
              };
            }).toList());
  }

  Future<void> handleChoreTap(
      String choreId, String title, bool isLocked) async {
    if (isLocked) return;

    bool confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Mark Chore as Completed?",
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to mark \"$title\" as completed? This will notify your parent for approval.",
          style: GoogleFonts.fredoka(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel",
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text("Yes",
                style: GoogleFonts.fredoka(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (!confirmed) return;

    await FirebaseFirestore.instance
        .collection('chores')
        .doc(choreId)
        .update({'status': 'completed'});

    await FirebaseFirestore.instance.collection('notifications').add({
      'type': 'chore_completed',
      'kid_id': widget.kidId,
      'kid_name': kidName,
      'chore_title': title,
      'timestamp': FieldValue.serverTimestamp(),
    });

    showCustomSnackBar("✅ \"$title\" marked as completed!", Colors.green);
  }

  void showCustomSnackBar(String message, Color bgColor) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: GoogleFonts.fredoka(
            color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Color getTileColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange[100]!;
      case 'completed':
        return Colors.green[100]!;
      case 'rewarded':
        return Colors.blue[100]!;
      default:
        return Colors.grey[300]!;
    }
  }

  Color getIconColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'rewarded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {},
      child: Scaffold(
        drawer: KidsDrawer(selectedPage: 'chores', kidId: widget.kidId),
        backgroundColor: const Color(0xFFFFCA26),
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // ✅ Header Row: Avatar + Hamburger
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white,
                                backgroundImage: AssetImage(avatarPath),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "$kidName's Chores",
                                style: GoogleFonts.fredoka(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Builder(
                            builder: (context) {
                              return GestureDetector(
                                onTap: () {
                                  Scaffold.of(context).openDrawer();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 2),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/hamburger_icon.png',
                                      height: 50, // fixed size
                                      width: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ✅ Chores List
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: getChoresStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(
                                child: Text(
                                  "No chores assigned yet! 🎉",
                                  style: GoogleFonts.fredoka(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              );
                            }
                            final chores = snapshot.data!;
                            return ListView.builder(
                              itemCount: chores.length,
                              itemBuilder: (context, index) {
                                final chore = chores[index];
                                final status = chore['status'];
                                final isLocked = status == 'completed' ||
                                    status == 'rewarded';

                                return GestureDetector(
                                  onTap: () => handleChoreTap(
                                    chore['id'],
                                    chore['title'],
                                    isLocked,
                                  ),
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: getTileColor(status),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.task_alt,
                                        color: getIconColor(status),
                                        size: 30,
                                      ),
                                      title: Text(
                                        chore['title'],
                                        style: GoogleFonts.fredoka(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            chore['description'],
                                            style: GoogleFonts.inter(
                                                fontSize: 12),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            status == 'pending'
                                                ? "🟠 Pending"
                                                : status == 'completed'
                                                    ? "🟢 Completed! Waiting for Parent"
                                                    : "🔵 Rewarded",
                                            style: GoogleFonts.fredoka(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: getIconColor(status),
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                        child: Text(
                                          "\$${chore['reward'].toStringAsFixed(2)}",
                                          style: GoogleFonts.fredoka(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
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
                ),
        ),
      ),
    );
  }
}
