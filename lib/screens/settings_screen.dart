import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailUpdates = true;
  bool _orderUpdates = true;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Light';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Notifications Section
            _buildSectionHeader('Notifications'),
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Receive push notifications',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            _buildSwitchTile(
              title: 'Email Updates',
              subtitle: 'Receive email about new offers',
              value: _emailUpdates,
              onChanged: (value) {
                setState(() {
                  _emailUpdates = value;
                });
              },
            ),
            _buildSwitchTile(
              title: 'Order Updates',
              subtitle: 'Get notified about your orders',
              value: _orderUpdates,
              onChanged: (value) {
                setState(() {
                  _orderUpdates = value;
                });
              },
            ),
            const Divider(),

            // Preferences Section
            _buildSectionHeader('Preferences'),
            _buildDropdownTile(
              title: 'Language',
              value: _selectedLanguage,
              items: ['English', 'Spanish', 'French', 'German'],
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Language changed to $value'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            _buildDropdownTile(
              title: 'Theme',
              value: _selectedTheme,
              items: ['Light', 'Dark', 'Auto'],
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Theme changed to $value'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            const Divider(),

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
                  const SnackBar(
                    content: Text('Opening Privacy Policy...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            _buildMenuTile(
              icon: Icons.description,
              title: 'Terms & Conditions',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening Terms & Conditions...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            const Divider(),

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
                  const SnackBar(
                    content: Text('Opening bug report form...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            _buildMenuTile(
              icon: Icons.star,
              title: 'Rate App',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Redirecting to app store...'),
                    duration: Duration(seconds: 2),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.teal.shade700,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          DropdownButton<String>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
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
    return ListTile(
      leading: Icon(icon, color: Colors.teal.shade700),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text ==
                  confirmPasswordController.text) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
