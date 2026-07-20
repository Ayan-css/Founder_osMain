import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  /// Formats the phone number to ensure it has a country code.
  /// If it starts with 0, removes it and prepends +91.
  /// If it doesn't start with +, prepends +91.
  static String formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), ''); // Remove non-digits
    
    // If it starts with 0, drop the 0
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    // After cleaning, if it's 10 digits, assume it's Indian without country code
    if (cleaned.length == 10) {
      cleaned = '91$cleaned';
    } else if (!phone.startsWith('+') && cleaned.isNotEmpty) {
      // If no '+' and not 10 digits, we still just slap 91 on it if it's short,
      // but if they provided something with a country code without +, just use it.
      // Usually, length > 10 implies country code might be there without +.
      // To be safe, if length is exactly 12 and starts with 91, it's fine.
      if (!cleaned.startsWith('91')) {
         cleaned = '91$cleaned';
      }
    }
    return '+$cleaned';
  }

  static Future<void> launchWhatsApp(String phone, String message) async {
    final formattedPhone = formatPhoneNumber(phone).replaceAll('+', '');

    // NOTE: The native `whatsapp://send` URI scheme truncates multi-line messages
    // on most devices — it strips everything after the first newline.
    // We always use the `https://wa.me/` link which correctly preserves newlines
    // encoded as %0A by Dart's Uri() queryParameters encoder.
    final webUri = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}');

    try {
      final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      throw Exception('Could not launch WhatsApp. Error: $e');
    }
  }

  /// Generates an Islamic-themed payment reminder message
  static String getPaymentReminderMessage(String clientName, String service, String amount, String dueDate) {
    return '''Assalamu Alaikum $clientName,

I hope this message finds you in the best of health and imaan. 

This is a gentle reminder regarding the invoice for $service. An amount of ₹$amount is due on $dueDate. 

Please process the payment at your earliest convenience. If you have already made the payment, please ignore this message.

JazakAllah Khair!''';
  }

  /// Generates an Islamic-themed welcome message
  static String getWelcomeMessage(String clientName, String agencyName) {
    return '''Assalamu Alaikum $clientName,

Welcome to $agencyName! We are absolutely thrilled to have you onboard. 

May Allah bless this collaboration and bring barakah to our work together. We look forward to achieving great things together!

If you have any questions or need assistance to get started, please don't hesitate to reach out.

JazakAllah Khair!''';
  }

  /// Generates an Islamic-themed farewell/project completion message
  static String getFarewellMessage(String clientName) {
    return '''Assalamu Alaikum $clientName,

It was an absolute pleasure working with you on this project. 

May Allah bring barakah to your business and grant you immense success! We hope we will work together again inshhallah.

Let's stay in touch!

JazakAllah Khair!''';
  }
}
