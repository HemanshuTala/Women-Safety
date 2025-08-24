import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:women_safety_user/src/providers/auth_provider.dart';

class SosHistoryScreen extends StatefulWidget {
  final String? userId;
  final String? childName;

  const SosHistoryScreen({super.key, this.userId, this.childName});

  @override
  State<SosHistoryScreen> createState() => _SosHistoryScreenState();
}

class _SosHistoryScreenState extends State<SosHistoryScreen> {
  List<dynamic> _sosHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSosHistory();
  }

  Future<void> _loadSosHistory() async {
    setState(() => _loading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      
      // Get arguments if passed from parent screen
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final targetUserId = args?['userId'] ?? widget.userId ?? auth.userId;

      if (targetUserId.isEmpty) {
        throw Exception('User ID is required to load SOS history');
      }

      final data = await auth.api.getSosHistory(targetUserId);
      debugPrint('SOS History loaded: ${data.length} items for user: $targetUserId');
      setState(() => _sosHistory = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load SOS history: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Unknown time';

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM dd, yyyy - HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  void _showSosDetails(Map<String, dynamic> sos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'SOS Alert Details',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Time
                    _buildDetailRow(
                      'Time',
                      _formatDateTime(sos['createdAt']?.toString()),
                      Icons.access_time,
                    ),

                    // Location
                    if (sos['lat'] != null && sos['lng'] != null)
                      _buildDetailRow(
                        'Location',
                        '${sos['lat']}, ${sos['lng']}',
                        Icons.location_on,
                        onTap: () => _openInMaps(
                          double.tryParse(sos['lat'].toString()) ?? 0.0,
                          double.tryParse(sos['lng'].toString()) ?? 0.0,
                        ),
                      ),

                    // Message
                    if (sos['message'] != null)
                      _buildDetailRow(
                        'Message',
                        sos['message'].toString(),
                        Icons.message,
                      ),

                    // Status
                    _buildDetailRow(
                      'Status',
                      sos['status']?.toString() ?? 'Active',
                      Icons.info_outline,
                    ),

                    // User info (for parents viewing child's SOS)
                    if (sos['user'] != null)
                      _buildDetailRow(
                        'User',
                        sos['user']['name']?.toString() ?? 'Unknown',
                        Icons.person,
                      ),

                    // Audio section removed as requested
                  ],
                ),
              ),

              // Action buttons
              const SizedBox(height: 20),
              Row(
                children: [
                  if (sos['lat'] != null && sos['lng'] != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openInMaps(sos['lat'], sos['lng']),
                        icon: const Icon(Icons.map),
                        label: const Text('View on Map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.grey[600], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInMaps(dynamic lat, dynamic lng) async {
    try {
      // Convert lat and lng to double safely
      final double latitude = double.parse(lat.toString());
      final double longitude = double.parse(lng.toString());

      final url = 'https://www.google.com/maps?q=$latitude,$longitude';
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening maps: $e');
    }
  }

  // Audio playback method removed as requested

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'active':
      default:
        return Colors.red;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'resolved':
        return 'Resolved';
      case 'in_progress':
        return 'In Progress';
      case 'active':
      default:
        return 'Active';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pink = Colors.pink.shade400;
    
    // Get arguments if passed from parent screen
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final displayName = args?['childName'] ?? widget.childName ?? 'SOS History';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.userId != null && widget.userId != Provider.of<AuthProvider>(context, listen: false).userId
              ? '$displayName - SOS History'
              : 'SOS History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: pink,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSosHistory,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sosHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No SOS alerts found',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'SOS alerts will appear here when activated',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSosHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sosHistory.length,
                    itemBuilder: (context, index) {
                      final sosItem = _sosHistory[index];
                      if (sosItem is! Map<String, dynamic>)
                        return const SizedBox.shrink();
                      final sos = sosItem;
                      final status = sos['status']?.toString();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _showSosDetails(sos),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getStatusColor(status),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        _getStatusText(status),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: _getStatusColor(status),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDateTime(
                                          sos['createdAt']?.toString()),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (sos['message'] != null) ...[
                                  Text(
                                    sos['message'].toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Row(
                                  children: [
                                    if (sos['lat'] != null &&
                                        sos['lng'] != null) ...[
                                      Icon(Icons.location_on,
                                          size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'View Location',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    // Audio icon removed as requested
                                    const SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_ios,
                                        size: 12, color: Colors.grey[400]),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
