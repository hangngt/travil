// Widget hỗ trợ 3 trạng thái
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TripStatusChip extends StatefulWidget {
  final int productId;

  const TripStatusChip({super.key, required this.productId});

  @override
  State<TripStatusChip> createState() => _TripStatusChipState();
}

class _TripStatusChipState extends State<TripStatusChip> {
  String status = "Chưa đi"; // Chưa đi | Sẽ đi | Đã đi

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      status = prefs.getString('status_${widget.productId}') ?? "Chưa đi";
    });
  }

  Future<void> _updateStatus(String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('status_${widget.productId}', newStatus);
    setState(() => status = newStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildChip("Chưa đi", Colors.grey, status == "Chưa đi"),
        const SizedBox(width: 8),
        _buildChip("Sẽ đi", Colors.blue, status == "Sẽ đi"),
        const SizedBox(width: 8),
        _buildChip("Đã đi", Colors.green, status == "Đã đi"),
      ],
    );
  }

  Widget _buildChip(String label, Color color, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _updateStatus(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
