import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../config/contact_config.dart';
import 'logger_service.dart';

class ContactService {
  static final LoggerService _logger = LoggerService();

  /// Open phone dialer with the support number
  static Future<bool> callSupport() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: ContactConfig.supportPhoneNumber,
    );
    try {
      if (await canLaunchUrl(phoneUri)) {
        return await launchUrl(phoneUri);
      } else {
        throw 'Could not launch phone dialer';
      }
    } catch (e) {
      _logger.error('Error launching phone dialer: $e');
      return false;
    }
  }

  /// Open email client to send support email
  static Future<bool> emailSupport({String? subject, String? body}) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: ContactConfig.supportEmail,
      queryParameters: {
        'subject': subject ?? ContactConfig.defaultEmailSubject,
        'body': body ?? ContactConfig.defaultEmailBody,
      },
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        return await launchUrl(emailUri);
      } else {
        throw 'Could not launch email client';
      }
    } catch (e) {
      _logger.error('Error launching email client: $e');
      return false;
    }
  }

  /// Open live chat in browser
  static Future<bool> openLiveChat() async {
    final Uri chatUri = Uri.parse(ContactConfig.liveChatUrl);
    try {
      if (await canLaunchUrl(chatUri)) {
        return await launchUrl(chatUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open live chat';
      }
    } catch (e) {
      _logger.error('Error opening live chat: $e');
      return false;
    }
  }

  /// Show error snack bar
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show success snack bar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
