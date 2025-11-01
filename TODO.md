# TODO: Implement Location Tracking for Technicians

## Steps to Complete:
- [x] Add driver location API methods in api_service.dart (updateDriverLocation, getDriverLocation)
- [x] Update AndroidManifest.xml for location permissions (ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, FOREGROUND_SERVICE)
- [x] Modify tasks_tab.dart: Add Timer for sending location every 5 seconds when status is enRoute
- [x] Modify tracking_driver.dart: Add polling Timer every 3 seconds to fetch and update driver location on map
- [ ] Test location permissions and API connectivity
- [ ] Backend: Create MySQL table `driver_locations` and PHP APIs (update.php, get.php)

## Information Gathered:
- TasksTab handles status changes to enRoute, perfect place to start location sending
- TrackingPage (tracking_driver.dart) has static driver location, needs real-time updates
- API service already has baseUrl configured for Laravel backend
- Geolocator package already included in pubspec.yaml
- OrderStatus.enRoute defined in model

## Dependent Files:
- `lib/api_services/api_service.dart`: Add location API methods
- `android/app/src/main/AndroidManifest.xml`: Add location permissions
- `lib/Teknisi/tasks_tab.dart`: Add location Timer and sending logic
- `lib/Service/tracking_driver.dart`: Add polling Timer and location update logic

## Followup Steps:
- Test end-to-end: Technician location updates, customer sees real-time tracking
- Optional: Implement background location using workmanager for when app is closed
- Optional: Add ETA calculation and notifications
