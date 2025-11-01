import 'package:workmanager/workmanager.dart';
import 'package:e_service/Others/new_order_notification_service.dart';
import 'package:e_service/Others/birthday_notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('🚀 [BACKGROUND] Task started: $task');

    try {
      switch (task) {
        case 'checkNewOrders':
          print('📦 [BACKGROUND] Checking new orders...');
          await NewOrderNotificationService.checkAndSendNewOrderNotifications();
          print('✅ [BACKGROUND] New order check completed');
          break;

        case 'checkBirthdays':
          print('🎂 [BACKGROUND] Checking birthdays...');
          await BirthdayNotificationService.checkAndSendBirthdayNotifications();
          print('✅ [BACKGROUND] Birthday check completed');
          break;

        default:
          print('⚠️ [BACKGROUND] Unknown task: $task');
      }

      return Future.value(true);
    } catch (e) {
      print('❌ [BACKGROUND] Task error: $e');
      return Future.value(false);
    }
  });
}