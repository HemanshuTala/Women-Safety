import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../routes.dart';

class SmartProfileScreen extends StatefulWidget {
  const SmartProfileScreen({super.key});

  @override
  State<SmartProfileScreen> createState() => _SmartProfileScreenState();
}

class _SmartProfileScreenState extends State<SmartProfileScreen> {
  List<dynamic> _connectionRequests = [];
  List<dynamic> _connectedParents = [];
  List<dynamic> _connectedChildren = [];
  bool _loadingConnections = false;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    setState(() => _loadingConnections = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      // Load connection requests
      final requests = await auth.api.getConnectionRequests();

      // Load connected parents/children from user data
      final user = auth.user;
      final parents = user?['parents'] as List<dynamic>? ?? [];
      final children = user?['children'] as List<dynamic>? ?? [];

      setState(() {
        _connectionRequests = requests;
        _connectedParents = parents;
        _connectedChildren = children;
      });

      // Debug print
      debugPrint("Requests: $_connectionRequests");
      debugPrint("Parents: $_connectedParents");
      debugPrint("Children: $_connectedChildren");
    } catch (e) {
      debugPrint('Error loading connections: $e');
      _showError('Failed to load connections: $e');
    } finally {
      setState(() => _loadingConnections = false);
    }
  }

  Future<void> _respondToRequest(String requestId, String action) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.api.respondToConnectionRequest(requestId, action);

      _showSuccess('Connection request ${action}ed successfully!');

      // Refresh user profile and connections
      await auth.refreshProfile();
      await _loadConnections();
    } catch (e) {
      _showError('Failed to $action request: $e');
    }
  }

  void _navigateToConnectChild() {
    Navigator.pushNamed(context, Routes.connectChild);
  }

  void _navigateToSettings() {
    Navigator.pushNamed(context, Routes.settings);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.shade400,
              Colors.pink.shade300,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 24),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _navigateToSettings,
                        icon: const Icon(Icons.settings,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),

              // Profile Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Profile Header Card
                        _buildProfileHeaderCard(),

                        const SizedBox(height: 24),

                        // Quick Actions
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            final userRole =
                                auth.user?['role']?.toString().toLowerCase();
                            final isParent = userRole == 'parent';

                            return _buildQuickActionsCard(isParent);
                          },
                        ),

                        const SizedBox(height: 24),

                        // Connections Section
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            final userRole =
                                auth.user?['role']?.toString().toLowerCase();
                            final isParent = userRole == 'parent';

                            return _buildConnectionsSection(isParent);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.shade100.withValues(alpha: 0.5),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Avatar with gradient border
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade400, Colors.pink.shade300],
                  ),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.pink.shade400,
                    child: Text(
                      (auth.user?['name']?.toString() ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Name
              Text(
                auth.user?['name']?.toString() ?? 'User',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),

              const SizedBox(height: 8),

              // Phone with icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    auth.user?['phone']?.toString() ?? 'No phone',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Role badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.pink.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (auth.user?['role']?.toString() ?? 'User').toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsCard(bool isParent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Settings Action
              Expanded(
                child: _buildActionButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  color: Colors.blue.shade400,
                  onTap: _navigateToSettings,
                ),
              ),

              const SizedBox(width: 12),

              // Connect Child Action (only for parents)
              if (isParent)
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.person_add,
                    label: 'Connect Child',
                    color: Colors.green.shade400,
                    onTap: _navigateToConnectChild,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionsSection(bool isParent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.pink.shade400, size: 24),
              const SizedBox(width: 8),
              Text(
                'Connections',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              if (_loadingConnections)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _loadConnections,
                  icon: Icon(Icons.refresh, color: Colors.pink.shade400),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Connection Requests
          if (_connectionRequests.isNotEmpty) ...[
            Text(
              'Pending Requests',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade600,
              ),
            ),
            const SizedBox(height: 8),
            ..._connectionRequests.map((req) {
              if (req is Map<String, dynamic>) {
                return _buildRequestCard(req);
              } else {
                return _buildRequestCard({
                  "fromUser": {"name": req.toString()}
                });
              }
            }),
            const SizedBox(height: 16),
          ],

          // Connected Children (for parents)
          if (isParent) ...[
            Text(
              'Connected Children (${_connectedChildren.length})',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 8),
            if (_connectedChildren.isEmpty)
              _buildEmptyConnectionsCard(
                  'No children connected yet', Icons.child_care)
            else
              ..._connectedChildren.map((child) {
                if (child is Map<String, dynamic>) {
                  return _buildConnectionCard(child, true);
                } else {
                  return _buildConnectionCard({"name": child.toString()}, true);
                }
              }),
          ],

          // Connected Parents (for children)
          if (!isParent) ...[
            Text(
              'Connected Parents (${_connectedParents.length})',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 8),
            if (_connectedParents.isEmpty)
              _buildEmptyConnectionsCard(
                  'No parents connected yet', Icons.family_restroom)
            else
              ..._connectedParents.map((parent) {
                if (parent is Map<String, dynamic>) {
                  return _buildConnectionCard(parent, false);
                } else {
                  return _buildConnectionCard(
                      {"name": parent.toString()}, false);
                }
              }),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyConnectionsCard(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final fromUser = request['fromUser'] as Map<String, dynamic>? ?? {};
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.orange.shade400,
            child: Text(
              (fromUser['name']?.toString() ?? 'U')[0].toUpperCase(),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fromUser['name']?.toString() ?? "Unknown",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  fromUser['phone']?.toString() ?? "",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _respondToRequest(
                    request['_id']?.toString() ?? '', 'accept'),
                icon: Icon(Icons.check, color: Colors.green.shade600),
                tooltip: 'Accept',
              ),
              IconButton(
                onPressed: () => _respondToRequest(
                    request['_id']?.toString() ?? '', 'decline'),
                icon: Icon(Icons.close, color: Colors.red.shade600),
                tooltip: 'Decline',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(Map<String, dynamic> connection, bool isChild) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.green.shade400,
            child: Text(
              (connection['name']?.toString() ?? 'U')[0].toUpperCase(),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connection['name']?.toString() ?? "Unknown",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  connection['phone']?.toString() ?? "",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle,
                    size: 14, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Text(
                  'Connected',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
