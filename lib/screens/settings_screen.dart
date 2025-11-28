import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/logger_service.dart';
import '../services/notification_preferences_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final NotificationPreferencesService _notificationPrefsService =
      NotificationPreferencesService();
  final NotificationService _notificationService = NotificationService();
  final LoggerService _logger = LoggerService();

  bool _notificationsEnabled = true;
  bool _emailUpdates = true;
  bool _orderUpdates = true;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Light';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadNotificationPreferences();
    // Start real-time listeners for notifications
    _notificationService.startListeners();
  }

  @override
  void dispose() {
    _notificationService.stopListeners();
    _notificationPrefsService.dispose();
    super.dispose();
  }

  /// Load saved preferences from Firebase
  Future<void> _loadPreferences() async {
    try {
      final prefs = await _authService.getPreferences();
      if (prefs != null) {
        setState(() {
          _selectedLanguage = prefs['language'] ?? 'English';
          _selectedTheme = prefs['theme'] ?? 'Light';
        });
      }
    } catch (e) {
      _logger.error('Error loading preferences: $e');
    }
  }

  /// Load notification preferences from Firebase
  Future<void> _loadNotificationPreferences() async {
    try {
      final notifPrefs = await _notificationPrefsService
          .getNotificationPreferences();
      if (notifPrefs != null) {
        setState(() {
          _notificationsEnabled = notifPrefs['pushNotifications'] ?? true;
          _emailUpdates = notifPrefs['emailUpdates'] ?? true;
          _orderUpdates = notifPrefs['orderUpdates'] ?? true;
        });
      }
    } catch (e) {
      _logger.error('Error loading notification preferences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.white, size: 26),
                const SizedBox(width: 10),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.4,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                        color: Colors.black.withAlpha(77),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your preferences',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.cyan[100],
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Notifications Section
            _buildSectionHeader('Notifications'),
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Receive push notifications',
              value: _notificationsEnabled,
              onChanged: (value) async {
                final scaffold = ScaffoldMessenger.of(context);
                final result = await _notificationPrefsService
                    .saveNotificationPreferences(
                      pushNotifications: value,
                      emailUpdates: _emailUpdates,
                      orderUpdates: _orderUpdates,
                    );
                if (!mounted) return;

                if (result.success) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Push notifications enabled'
                            : 'Push notifications disabled',
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green.shade600,
                    ),
                  );
                } else {
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text('Error: ${result.message}'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                }
              },
            ),
            _buildSwitchTile(
              title: 'Email Updates',
              subtitle: 'Receive email about new offers',
              value: _emailUpdates,
              onChanged: (value) async {
                final scaffold = ScaffoldMessenger.of(context);
                final result = await _notificationPrefsService
                    .saveNotificationPreferences(
                      pushNotifications: _notificationsEnabled,
                      emailUpdates: value,
                      orderUpdates: _orderUpdates,
                    );
                if (!mounted) return;

                if (result.success) {
                  setState(() {
                    _emailUpdates = value;
                  });
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Email updates enabled'
                            : 'Email updates disabled',
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green.shade600,
                    ),
                  );
                } else {
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text('Error: ${result.message}'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                }
              },
            ),
            _buildSwitchTile(
              title: 'Order Updates',
              subtitle: 'Get notified about your orders',
              value: _orderUpdates,
              onChanged: (value) async {
                final scaffold = ScaffoldMessenger.of(context);
                final result = await _notificationPrefsService
                    .saveNotificationPreferences(
                      pushNotifications: _notificationsEnabled,
                      emailUpdates: _emailUpdates,
                      orderUpdates: value,
                    );
                if (!mounted) return;

                if (result.success) {
                  setState(() {
                    _orderUpdates = value;
                  });
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Order updates enabled'
                            : 'Order updates disabled',
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green.shade600,
                    ),
                  );
                } else {
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text('Error: ${result.message}'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                }
              },
            ),

            // Preferences Section
            _buildSectionHeader('Preferences'),
            _buildDropdownTile(
              title: 'Language',
              value: _selectedLanguage,
              items: ['English', 'Spanish', 'French', 'German'],
              onChanged: (value) async {
                // Save to database
                final scaffold = ScaffoldMessenger.of(context);
                final result = await _authService.savePreferences(
                  language: value,
                  theme: _selectedTheme,
                );
                if (!mounted) return;

                if (result.success) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text('Language changed to $value'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green.shade600,
                    ),
                  );
                } else {
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text('Error: ${result.message}'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                }
              },
            ),
            _buildDropdownTile(
              title: 'Theme',
              value: _selectedTheme,
              items: ['Light', 'Dark', 'Auto'],
              onChanged: (value) async {
                // Save to database
                final scaffold = ScaffoldMessenger.of(context);
                final result = await _authService.savePreferences(
                  language: _selectedLanguage,
                  theme: value,
                );
                if (!mounted) return;

                if (result.success) {
                  setState(() {
                    _selectedTheme = value;
                  });
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text('Theme changed to $value'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green.shade600,
                    ),
                  );
                } else {
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text('Error: ${result.message}'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                }
              },
            ),

            // Account Section
            _buildSectionHeader('Account'),
            _buildMenuTile(
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () {
                _showChangePasswordDialog();
              },
            ),
            _buildMenuTile(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Opening Privacy Policy...'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.teal.shade700,
                  ),
                );
              },
            ),
            _buildMenuTile(
              icon: Icons.description,
              title: 'Terms & Conditions',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Opening Terms & Conditions...'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.teal.shade700,
                  ),
                );
              },
            ),

            // About Section
            _buildSectionHeader('About'),
            _buildMenuTile(
              icon: Icons.info,
              title: 'About App',
              subtitle: 'Version 1.0.0',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Pharmacy App',
                  applicationVersion: '1.0.0',
                  applicationLegalese:
                      '© 2024 Pharmacy App. All rights reserved.',
                );
              },
            ),
            _buildMenuTile(
              icon: Icons.bug_report,
              title: 'Report Bug',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Opening bug report form...'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.teal.shade700,
                  ),
                );
              },
            ),
            _buildMenuTile(
              icon: Icons.star,
              title: 'Rate App',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Redirecting to app store...'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.teal.shade700,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.teal.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade100.withAlpha(51),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.teal.shade700,
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade100.withAlpha(51),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.teal.shade900,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: value,
              underline: const SizedBox.shrink(),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.teal.shade700,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade100.withAlpha(51),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.teal.shade700, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade900,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.teal.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool showOldPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock, color: Colors.teal.shade700),
              const SizedBox(width: 10),
              const Text('Change Password'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: !showOldPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: TextStyle(color: Colors.teal.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.teal.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.teal.shade700,
                        width: 2,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showOldPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.teal.shade700,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          showOldPassword = !showOldPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: !showNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: Colors.teal.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.teal.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.teal.shade700,
                        width: 2,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.teal.shade700,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          showNewPassword = !showNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !showConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: Colors.teal.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.teal.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.teal.shade700,
                        width: 2,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.teal.shade700,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          showConfirmPassword = !showConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              onPressed: () async {
                // Validation
                if (oldPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter current password'),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                  return;
                }

                if (newPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter new password'),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                  return;
                }

                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Passwords do not match'),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                  return;
                }

                // Change password via AuthService
                final navigator = Navigator.of(context);
                final scaffold = ScaffoldMessenger.of(context);
                final result = await _authService.changePassword(
                  currentPassword: oldPasswordController.text,
                  newPassword: newPasswordController.text,
                );
                if (!mounted) return;

                if (result.success) {
                  navigator.pop();
                  scaffold.showSnackBar(
                    SnackBar(
                      content: const Text('Password changed successfully'),
                      backgroundColor: Colors.green.shade600,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } else {
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text('Error: ${result.message}'),
                      backgroundColor: Colors.red.shade400,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              label: const Text('Change'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
