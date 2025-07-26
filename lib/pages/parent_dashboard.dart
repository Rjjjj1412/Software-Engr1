import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/pages/parent_drawer.dart';
import 'package:flutter/services.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});
  
  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

double totalDepositedFunds = 0.0;

class _ParentDashboardState extends State<ParentDashboard> {
  List<Map<String, dynamic>> kidsData = [];
  int totalChildren = 0;
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final List<Color> tileColors = [
    const Color.fromARGB(255, 252, 193, 220),
    const Color.fromARGB(255, 209, 241, 212),
    const Color.fromARGB(255, 251, 194, 215),
    const Color.fromARGB(255, 224, 182, 238),
    const Color.fromARGB(255, 240, 217, 233),
  ];

  @override
  void initState() {
    super.initState();
    _loadKidsData();
  }

Future<void> _loadKidsData() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('kids')
      .where('user_id', isEqualTo: userId)
      .get();

  final List<Map<String, dynamic>> tempKids = [];
  double runningTotal = 0.0;

  for (var doc in snapshot.docs) {
    final kidId = doc.id;
    final kidName = doc['firstName'] ?? '';
    final avatar = doc['avatar'] ?? '';

    // Get usable_balance
    final balanceDoc = await FirebaseFirestore.instance
        .collection('kids_payment_info')
        .doc(kidId)
        .get();

    final usableBalance = balanceDoc.exists
        ? (balanceDoc.data()?['usable_balance'] ?? 0.0)
        : 0.0;

    // Get total withdrawals for this kid
    final withdrawalsSnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('kid_id', isEqualTo: kidId)
        .where('type', isEqualTo: 'withdrawal')
        .get();

    double totalWithdrawn = 0.0;
    for (var withdrawalDoc in withdrawalsSnapshot.docs) {
      totalWithdrawn += (withdrawalDoc.data()['amount'] ?? 0.0);
    }

    // Total deposited = usable_balance + total withdrawals
    final totalDeposited = usableBalance + totalWithdrawn;

    runningTotal += totalDeposited;

    tempKids.add({
      'id': kidId,
      'name': kidName,
      'avatar': avatar,
      'balance': usableBalance.toDouble(),
      'totalDeposited': totalDeposited.toDouble(),
      'totalWithdrawn': totalWithdrawn.toDouble(),
    });
  }

  setState(() {
    kidsData = tempKids;
    totalChildren = tempKids.length;
    totalDepositedFunds = runningTotal;
  });
}


  void showChoresModal(BuildContext context, String kidName, String kidId, String avatar) {
    
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController(text: '1.00');

  double rewardAmount = 1.00;

  showDialog(
    context: context,
    barrierDismissible: true,
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
                      // Overlapping Image on top-right
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
                            "Chores",
                            style: GoogleFonts.fredoka(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "for $kidName",
                            style: GoogleFonts.fredoka(
                              fontSize: 24,
                              color: const Color.fromARGB(137, 0, 0, 0),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Chore Title Field
                          TextField(
                            controller: titleController,
                            decoration: InputDecoration(
                              labelText: "Chore Title",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Chore Description Field
                          TextField(
                            controller: descriptionController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: "Chore Description",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            "Reward Money",
                            style: GoogleFonts.fredoka(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Reward Controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () {
                                  if (rewardAmount > 1) {
                                    setModalState(() {
                                      rewardAmount -= 1;
                                      amountController.text = rewardAmount.toStringAsFixed(2);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFCA26),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black, width: 2),
                                  ),
                                  child: const Icon(Icons.remove, size: 20),
                                ),
                              ),
                              const SizedBox(width: 5),
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: amountController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(color: Colors.black),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onChanged: (value) {
                                    final parsed = double.tryParse(value);
                                    if (parsed != null && parsed >= 0) {
                                      rewardAmount = parsed;
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 5),
                              InkWell(
                                onTap: () {
                                  setModalState(() {
                                    rewardAmount += 1;
                                    amountController.text = rewardAmount.toStringAsFixed(2);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFCA26),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black, width: 2),
                                  ),
                                  child: const Icon(Icons.add, size: 20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Set Button
                          ElevatedButton(
                            onPressed: () async {
                              final String title = titleController.text.trim();
                              final String description = descriptionController.text.trim();

                              if (title.isEmpty || description.isEmpty || rewardAmount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please fill in all fields and set a valid reward."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              

                              await FirebaseFirestore.instance.collection('chores').add({
                                'kid_id': kidId,
                                'chore_title': title,
                                'chore_desc': description,
                                'reward_money': rewardAmount,
                                'status': 'pending',
                                'timestamp': FieldValue.serverTimestamp(),
                              });

                              // ignore: use_build_context_synchronously
                              Navigator.pop(context);
                              
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text("Chore created successfully!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF60C56F),
                              padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: const BorderSide(color: Colors.black, width: 2),
                              ),
                            ),
                            child: Text(
                              "Set",
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
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
}

void showManageFundsModal(
  BuildContext context,
  String kidName,
  String kidId,
  String avatar,
  {VoidCallback? onFundsUpdated}
) {
  final TextEditingController messageController = TextEditingController();
  final TextEditingController amountController =
      TextEditingController(text: '1.00');
  double fundAmount = 1.00;

  showDialog(
    context: context,
    barrierDismissible: true,
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
                            "Manage Funds",
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

                          // Fund Amount Controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () {
                                  if (fundAmount > 1) {
                                    setModalState(() {
                                      fundAmount -= 1;
                                      amountController.text =
                                          fundAmount.toStringAsFixed(2);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFCA26),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.black, width: 2),
                                  ),
                                  child: const Icon(Icons.remove, size: 20),
                                ),
                              ),
                              const SizedBox(width: 5),
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  textAlign: TextAlign.center,
                                  autofocus: false,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onChanged: (value) {
                                    final parsed = double.tryParse(value);
                                    if (parsed != null && parsed >= 0) {
                                      fundAmount = parsed;
                                    } else if (value.isNotEmpty) {
                                      setModalState(() {
                                        fundAmount = 0;
                                      });
                                    }
                                  },
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}')),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              InkWell(
                                onTap: () {
                                  setModalState(() {
                                    fundAmount += 1;
                                    amountController.text =
                                        fundAmount.toStringAsFixed(2);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFCA26),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.black, width: 2),
                                  ),
                                  child: const Icon(Icons.add, size: 20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Message Field
                          TextField(
                            controller: messageController,
                            autofocus: true, // 🔥 Auto-focus here
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: "Message for Kid",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Deposit and Withdraw Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final String message = messageController.text.trim();
                                    if (message.isEmpty || fundAmount <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("⚠️ Enter a message and valid amount."),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    try {
                                      final docRef = FirebaseFirestore.instance
                                          .collection('kids_payment_info')
                                          .doc(kidId);

                                      final docSnapshot = await docRef.get();
                                      double currentBalance = 0;
                                      if (docSnapshot.exists) {
                                        currentBalance =
                                            (docSnapshot.data()?['usable_balance'] ?? 0).toDouble();
                                      }

                                      final newBalance = currentBalance + fundAmount;

                                      // Update balance
                                      await docRef.set({
                                        'usable_balance': newBalance,
                                        'last_updated': FieldValue.serverTimestamp(),
                                      });

                                      // Push notification
                                      await FirebaseFirestore.instance
                                          .collection('kids_notifications')
                                          .add({
                                        'kid_id': kidId,
                                        'type': 'deposit',
                                        'amount': fundAmount,
                                        'message': message,
                                        'timestamp': FieldValue.serverTimestamp(),
                                      });

                                      // Call the callback BEFORE closing the dialog
                                      if (onFundsUpdated != null) onFundsUpdated();

                                      Navigator.pop(context);

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "✅ Deposited \$${fundAmount.toStringAsFixed(2)} successfully!",
                                            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } catch (e) {
                                      debugPrint("Error during deposit: $e");
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("❌ Failed to deposit funds."),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF60C56F),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: const BorderSide(
                                          color: Colors.black, width: 2),
                                    ),
                                  ),
                                  child: Text(
                                    "Deposit",
                                    style: GoogleFonts.fredoka(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final String message = messageController.text.trim();
                                    if (message.isEmpty || fundAmount <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("⚠️ Enter a message and valid amount."),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    try {
                                      final docRef = FirebaseFirestore.instance
                                          .collection('kids_payment_info')
                                          .doc(kidId);

                                      final docSnapshot = await docRef.get();
                                      double currentBalance = 0;
                                      if (docSnapshot.exists) {
                                        currentBalance =
                                            (docSnapshot.data()?['usable_balance'] ?? 0).toDouble();
                                      }

                                      if (fundAmount > currentBalance) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("❌ Insufficient balance for withdrawal."),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      final newBalance = currentBalance - fundAmount;

                                      // Update balance
                                      await docRef.set({
                                        'usable_balance': newBalance,
                                        'last_updated': FieldValue.serverTimestamp(),
                                      });

                                      // Push notification
                                      await FirebaseFirestore.instance
                                          .collection('kids_notifications')
                                          .add({
                                        'kid_id': kidId,
                                        'type': 'withdrawal',
                                        'amount': fundAmount,
                                        'message': message,
                                        'timestamp': FieldValue.serverTimestamp(),
                                      });

                                      // Call the callback BEFORE closing the dialog
                                      if (onFundsUpdated != null) onFundsUpdated();

                                      Navigator.pop(context);

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "✅ Withdrew \$${fundAmount.toStringAsFixed(2)} successfully!",
                                            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } catch (e) {
                                      debugPrint("Error during withdrawal: $e");
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("❌ Failed to withdraw funds."),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFEB40D),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: const BorderSide(
                                          color: Colors.black, width: 2),
                                    ),
                                  ),
                                  child: Text(
                                    "Withdraw",
                                    style: GoogleFonts.fredoka(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
}

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation
      onPopInvokedWithResult: (didPop, result) async {
        // Do nothing when back is pressed
        },
    child: Scaffold(
      drawer: const ParentDrawer(selectedPage: 'dashboard'),
      backgroundColor: const Color(0xFFFFCA26),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFCA26),
        elevation: 0,
        title: Text(
          "KidsBank",
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
            onTap: () {
              Scaffold.of(context).openDrawer(); // Opens drawer if added
            },
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black, // Black circle background
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.menu,
                color: Color(0xFFFFCA26), // Yellow icon (same as background)
              ),
            ),
          ),
        ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Top Overview Card
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 300,
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCA26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 160), // space for image
                      Text(
                        "\$${totalDepositedFunds.toStringAsFixed(2)}", // Static placeholder
                        style: GoogleFonts.fredoka(
                          fontSize: 46,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        "Total Deposited Funds",
                        style: GoogleFonts.fredoka(
                          fontSize: 17.3,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 12,
                  child: Image.asset(
                    'assets/pig.png',
                    width: 150,
                  ),
                ),
                Positioned(
                  top: 60,
                  right: 70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Children",
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$totalChildren",
                        style: GoogleFonts.fredoka(
                          fontSize: 90.2,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Kids Info Section
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFE6E8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Kids Info",
                      style: GoogleFonts.fredoka(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: kidsData.length,
                        itemBuilder: (context, index) {
                          final kid = kidsData[index];
                          final kidId = kid['id'];
                          final kidName = kid['name'];
                          final kidAvatar = kid['avatar']; 
                          final tileColor = tileColors[index % tileColors.length];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: tileColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: AssetImage(kid['avatar']),
                                  radius: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        kid['name'],
                                        style: GoogleFonts.fredoka(
                                          fontSize: 23,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "\$${kid['balance'].toStringAsFixed(2)}",
                                        style: GoogleFonts.fredoka(
                                          fontSize: 23,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        if (kidId == null || kidName == null || kidAvatar == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Missing kid information")),
                                          );
                                          return;
                                        }

                                        showManageFundsModal(
                                          context,
                                          kidName,
                                          kidId,
                                          kidAvatar,
                                          onFundsUpdated: () {
                                          setState(() {
                                             _loadKidsData();
                                          }); 
                                           }
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFFCA26),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                                        side: const BorderSide(color: Colors.black, width: 2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        "Manage Funds",
                                        style: GoogleFonts.fredoka(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    OutlinedButton(
                                      onPressed: () {
                                       if (kidId == null || kidName == null || kidAvatar == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Missing kid information")),
                                        );
                                        return;
                                      }

                                      showChoresModal(
                                        context,
                                        kidName,
                                        kidId,
                                        kidAvatar,
                                      );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        side: const BorderSide(color: Colors.black, width: 2),
                                        padding: const EdgeInsets.symmetric(horizontal: 33, vertical: 1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        "Chores",
                                        style: GoogleFonts.fredoka(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
