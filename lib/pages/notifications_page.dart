import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'parent_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentNotificationsPage extends StatefulWidget {
  const ParentNotificationsPage({super.key});

  @override
  State<ParentNotificationsPage> createState() =>
      _ParentNotificationsPageState();
}

class _ParentNotificationsPageState extends State<ParentNotificationsPage> {
  /// Fetch notifications stream with kid info
  Stream<List<Map<String, dynamic>>> getNotificationsStream() async* {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      yield [];
      return;
    }

    final familyAccountId = currentUser.uid;

    // Step 1: Get all kids with matching family account user_id
    final kidSnapshot = await FirebaseFirestore.instance
        .collection('kids')
        .where('user_id', isEqualTo: familyAccountId)
        .get();

    final kidIds = kidSnapshot.docs.map((doc) => doc.id).toList();
    if (kidIds.isEmpty) {
      yield [];
      return;
    }

    // Step 2: Listen for all notifications, filter by matching kid_id
    yield* FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> notifications = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final kidId = data['kid_id'];

        if (!kidIds.contains(kidId)) continue; // Only include this parent's kids

        final kidDoc = kidSnapshot.docs.firstWhere((k) => k.id == kidId);
        final kidData = kidDoc.data();

        notifications.add({
          'id': doc.id,
          'type': data['type'],
          'kidId': kidId,
          'kidName': kidData['firstName'] ?? 'Kid',
          'avatar': kidData['avatar'] ?? 'assets/avatar1.png',
          'choreTitle': data['chore_title'],
          'choreDesc': data['description'],
          'title': data['title'],
          'amount': data['amount'],
          'status': data['status'] ?? 'pending',
          'timestamp': data['timestamp'],
        });
      }

      return notifications;
    });
  }

  /// Show reward modal and reward chore
Future<void> showRewardChoreModal(
  BuildContext context,
  String notifId,
  String kidName,
  String kidId,
  String avatar,
  String choreTitle,
  VoidCallback onRewarded, // ✅ proper function type
) async {
  final TextEditingController messageController = TextEditingController();
  final FocusNode messageFocusNode = FocusNode();
  double rewardAmount = 0.0;

  // 🔍 Fetch reward_money from Firestore
  try {
    final choreQuery = await FirebaseFirestore.instance
        .collection('chores')
        .where('kid_id', isEqualTo: kidId)
        .where('chore_title', isEqualTo: choreTitle)
        .limit(1)
        .get();

    if (choreQuery.docs.isNotEmpty) {
      final choreData = choreQuery.docs.first.data();
      rewardAmount = (choreData['reward_money'] ?? 0).toDouble();
    }
  } catch (e) {
    debugPrint("Error fetching reward_money: $e");
  }

  final TextEditingController amountController =
      TextEditingController(text: rewardAmount.toStringAsFixed(2));

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom * 0.4,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Stack(
                    children: [
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Image.asset(
                          avatar,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            "Reward Chore",
                            style: GoogleFonts.fredoka(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "for $kidName",
                            style: GoogleFonts.fredoka(
                              fontSize: 24,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 💰 Read-only Reward Amount Field
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: amountController,
                                  readOnly: true,
                                  enabled: false,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    labelText: "Reward",
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.black, width: 2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ✉️ Message Field
                          TextField(
                            controller: messageController,
                            focusNode: messageFocusNode,
                            maxLines: 2,
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: "Message for Kid (required)",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ✅ Confirm Button
                          ElevatedButton(
                            onPressed: () async {
                              final String message =
                                  messageController.text.trim();
                              final enteredAmount = double.tryParse(
                                  amountController.text.trim());

                              if (enteredAmount == null || enteredAmount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "⚠️ Invalid reward amount.",
                                      style: GoogleFonts.fredoka(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              if (message.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "⚠️ Please enter a message for the kid.",
                                      style: GoogleFonts.fredoka(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              try {
                                final paymentDoc = FirebaseFirestore.instance
                                    .collection('kids_payment_info')
                                    .doc(kidId);

                                final paymentSnapshot = await paymentDoc.get();
                                double currentBalance = 0;
                                if (paymentSnapshot.exists) {
                                  currentBalance = (paymentSnapshot
                                              .data()?['usable_balance'] ??
                                          0)
                                      .toDouble();
                                }

                                final newBalance =
                                    currentBalance + enteredAmount;

                                await paymentDoc.set({
                                  'usable_balance': newBalance,
                                  'last_updated': FieldValue.serverTimestamp(),
                                });

                                await FirebaseFirestore.instance
                                    .collection('notifications')
                                    .doc(notifId)
                                    .update({'status': 'rewarded'});

                                final choreQuery = await FirebaseFirestore
                                    .instance
                                    .collection('chores')
                                    .where('kid_id', isEqualTo: kidId)
                                    .where('chore_title',
                                        isEqualTo: choreTitle)
                                    .get();

                                for (var choreDoc in choreQuery.docs) {
                                  await choreDoc.reference
                                      .update({'status': 'rewarded'});
                                }

                                await FirebaseFirestore.instance
                                    .collection('kids_notifications')
                                    .add({
                                  'kid_id': kidId,
                                  'chore_title': choreTitle,
                                  'amount': enteredAmount,
                                  'message': message,
                                  'timestamp': FieldValue.serverTimestamp(),
                                  'type': 'reward',
                                });

                                Navigator.pop(context);
                                onRewarded();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "✅ Chore rewarded successfully!",
                                      style: GoogleFonts.fredoka(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "❌ Failed to reward chore. Try again.",
                                      style: GoogleFonts.fredoka(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF60C56F),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: const BorderSide(
                                    color: Colors.black, width: 2),
                              ),
                            ),
                            child: Text(
                              "Confirm and Reward",
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );

  // 🔁 Focus message box after slight delay
  Future.delayed(const Duration(milliseconds: 300), () {
    FocusScope.of(context).requestFocus(messageFocusNode);
  });
}

  @override
  Widget build(BuildContext context) {
  return PopScope(
    canPop: false, // Prevent back navigation
    onPopInvokedWithResult: (didPop, result) async {},
    child: Scaffold(
      drawer: const ParentDrawer(selectedPage: 'notifications'),
      backgroundColor: const Color(0xFFFFCA26),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFCA26),
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Notifications",
          style: GoogleFonts.fredoka(
            fontSize: 44,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: Builder(
          builder: (context) => Padding(
            padding:
                const EdgeInsets.only(left: 12, right: 4, top: 5, bottom: 10),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: getNotificationsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error loading notifications",
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      color: Colors.red,
                    ),
                  ),
                );
              }
              final notifications = snapshot.data ?? [];
              if (notifications.isEmpty) {
                return Center(
                  child: Text(
                    "No notifications yet!",
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final isChore = notif['type'] == 'chore_completed';
                  final isRewarded = notif['status'] == 'rewarded';
                  final timestamp = notif['timestamp']?.toDate();

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: const Color(0xFFFFCA26),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage: AssetImage(notif['avatar']),
                      ),
                      title: Text(
                        isChore
                            ? "${notif['kidName']} completed a chore!"
                            : "${notif['kidName']} withdrew \$${(notif['amount'] as num).toStringAsFixed(2)}",
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isRewarded
                              ? const Color(0xFF7d5e0d)
                              : Colors.black,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isChore)
                            GestureDetector(
                              onTap: isRewarded
                                  ? null
                                  : () {
                                      showRewardChoreModal(
                                        context,
                                        notif['id'], //Pass notification ID
                                        notif['kidName'],
                                        notif['kidId'],
                                        notif['avatar'],
                                        notif['choreTitle'],
                                        () {
                                          setState(() {}); // Refresh
                                        },
                                      );
                                    },
                              child: Text(
                                "\"${notif['choreTitle']}\" | Click to confirm & reward",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF7d5e0d),
                                  decoration: isRewarded
                                      ? TextDecoration.none
                                      : TextDecoration.underline,
                                ),
                              ),
                            )
                          else if (timestamp != null)
                          Text(
                            "${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} | "
                            "\"${notif['title']}\""
                            "${(notif['choreDesc'] != null && notif['choreDesc'].toString().isNotEmpty) ? " | ${notif['choreDesc']}" : ""}",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.black,
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
      ),
    ),
  );
  }
}