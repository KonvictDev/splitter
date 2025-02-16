import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PushNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  final HttpsCallable validateEnvCallable =
  FirebaseFunctions.instance.httpsCallable('validateEnv');


  /// Retrieves the FCM token stored in Firestore for the given contact phone.
  /// The token is nested under the "pidata" map.
  Future<String?> getFcmTokenForContact(String contactPhone) async {
    // Format the phone number (e.g. trim, add country code if needed)
    final formattedPhone = contactPhone.trim();
    final doc = await _firestore.collection("users").doc(formattedPhone).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey("pidata") && data["pidata"] is Map<String, dynamic>) {
        final pidata = data["pidata"] as Map<String, dynamic>;
        return pidata["fcmToken"] as String?;
      }
    }
    return null;
  }

  /// Sends a push notification to the selected contact by:
  /// 1. Retrieving the contact's FCM token from Firestore.
  /// 2. Calling the Cloud Function "sendPushNotification" with the token and message.


  Future<void> sendPushNotification( {required String contactPhone, required String title, required String body}) async {

    final fcmToken = await getFcmTokenForContact(contactPhone);
    print("Retrieved FCM token: $fcmToken");
    if (fcmToken == null) {
      print("No FCM token found for $contactPhone");
      return;
    }

    try {
      // Prepare the callable function instance.
      final HttpsCallable callable =
      FirebaseFunctions.instance.httpsCallable('sendNotification');

      // Define the notification details.
      final result = await callable.call({
        'token': fcmToken,
        'title': title,
        'body': body,
      });

      print('Function result: ${result.data}');
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }


}
