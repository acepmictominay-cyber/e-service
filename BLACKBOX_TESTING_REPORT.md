# Blackbox Testing Report - E-Service App

## Overview
This report contains comprehensive blackbox test cases for the E-Service Flutter application. Blackbox testing focuses on functionality without knowledge of internal code implementation.

## Test Environment
- **Platform**: Mobile (Android/iOS)
- **App Version**: Based on analyzed codebase
- **User Roles**: Customer, Technician (karyawan)
- **Key Features**: Authentication, Service booking, Product shopping, Technician management, Payments, Notifications

## Test Case Format
- **Test Case ID**: Unique identifier
- **Test Scenario**: Description of what is being tested
- **Preconditions**: Required state before test
- **Test Steps**: Step-by-step actions
- **Expected Result**: Expected behavior
- **Actual Result**: To be filled during testing
- **Status**: Pass/Fail
- **Priority**: High/Medium/Low

---

## 1. Authentication Test Cases

### TC_AUTH_001: Valid Customer Login
**Test Scenario**: Verify successful login with valid customer credentials
**Preconditions**: User has valid account, app is installed
**Test Steps**:
1. Open the app
2. Wait for splash screen to complete
3. Ensure "Masuk" tab is selected
4. Enter valid username in username field
5. Enter valid password in password field
6. Tap "Masuk" button
**Expected Result**: User successfully logs in, redirected to Home page with welcome notification
**Priority**: High

### TC_AUTH_002: Invalid Login Credentials
**Test Scenario**: Verify error handling for invalid credentials
**Preconditions**: App is at login screen
**Test Steps**:
1. Enter invalid username
2. Enter invalid password
3. Tap "Masuk" button
**Expected Result**: Error message displayed, login fails, remains on login screen
**Priority**: High

### TC_AUTH_003: Empty Login Fields
**Test Scenario**: Verify validation for empty fields
**Preconditions**: App is at login screen
**Test Steps**:
1. Leave username field empty
2. Leave password field empty
3. Tap "Masuk" button
**Expected Result**: Error message "Username dan password wajib diisi" displayed
**Priority**: High

### TC_AUTH_004: Password Visibility Toggle
**Test Scenario**: Verify password visibility toggle functionality
**Preconditions**: App is at login screen
**Test Steps**:
1. Enter password in password field
2. Tap the visibility icon
3. Observe password display
4. Tap visibility icon again
**Expected Result**: Password becomes visible when icon tapped, hidden when tapped again
**Priority**: Medium

### TC_AUTH_005: Technician Login
**Test Scenario**: Verify technician login redirects to technician dashboard
**Preconditions**: Valid technician account exists
**Test Steps**:
1. Enter valid technician username
2. Enter valid technician password
3. Tap "Masuk" button
**Expected Result**: Redirected to TeknisiHomePage with technician dashboard
**Priority**: High

### TC_AUTH_006: Forget Password Navigation
**Test Scenario**: Verify forget password screen navigation
**Preconditions**: App is at login screen
**Test Steps**:
1. Tap "Lupa Kata Sandi" link
**Expected Result**: Navigates to ForgetPasswordScreen
**Priority**: Medium

### TC_AUTH_007: Register Navigation
**Test Scenario**: Verify registration screen navigation
**Preconditions**: App is at login screen
**Test Steps**:
1. Tap "Daftar" tab
**Expected Result**: Switches to registration form
**Priority**: Medium

---

## 2. Customer Home Test Cases

### TC_HOME_001: Home Page Display
**Test Scenario**: Verify home page displays correctly for logged-in customer
**Preconditions**: User is logged in as customer
**Test Steps**:
1. Navigate to Home tab
2. Observe page content
**Expected Result**: Shows member card with user info and points, banner slider, hot items list
**Priority**: High

### TC_HOME_002: Banner Navigation
**Test Scenario**: Verify banner buttons navigate to correct pages
**Preconditions**: Home page is displayed
**Test Steps**:
1. Tap "Lihat Sekarang" on first banner (Garansi)
2. Return to home
3. Tap "Lihat Sekarang" on second banner (Tips)
4. Return to home
5. Tap "Lihat Sekarang" on third banner (Kebersihan)
6. Return to home
7. Tap "Lihat Sekarang" on fourth banner (Poin Info)
**Expected Result**: Each banner navigates to respective page (CekGaransiPage, TipsPage, KebersihanAlatPage, PoinInfoPage)
**Priority**: Medium

### TC_HOME_003: Product Card Interaction
**Test Scenario**: Verify product card tap navigates to detail page
**Preconditions**: Home page displays products
**Test Steps**:
1. Tap on any product card in Hot Items
**Expected Result**: Navigates to DetailProdukPage with product details
**Priority**: High

### TC_HOME_004: Bottom Navigation
**Test Scenario**: Verify bottom navigation switches between pages
**Preconditions**: User is on Home page
**Test Steps**:
1. Tap Service tab
2. Tap Beli tab
3. Tap Promo tab
4. Tap Profile tab
5. Return to Beranda tab
**Expected Result**: Each tab navigates to respective page (ServicePage, MarketplacePage, TukarPoinPage, ProfilePage)
**Priority**: High

### TC_HOME_005: Welcome Notification
**Test Scenario**: Verify welcome notification on fresh login
**Preconditions**: Fresh login
**Test Steps**:
1. Login with valid credentials
2. Observe notification overlay
**Expected Result**: Welcome notification appears with user name, can be dismissed
**Priority**: Medium

---

## 3. Service Test Cases

### TC_SERVICE_001: Service Page Display
**Test Scenario**: Verify service page displays correctly
**Preconditions**: User is logged in as customer
**Test Steps**:
1. Navigate to Service tab
2. Observe page content
**Expected Result**: Shows search bar, service image, home delivery info, repair service card
**Priority**: High

### TC_SERVICE_002: Transaction Search Valid
**Test Scenario**: Verify searching for valid transaction code
**Preconditions**: User has ongoing service, on Service page
**Test Steps**:
1. Enter valid transaction code in search field
2. Tap search icon or press enter
**Expected Result**: Navigates to appropriate page based on status (WaitingApprovalPage or TrackingPage)
**Priority**: High

### TC_SERVICE_003: Transaction Search Invalid
**Test Scenario**: Verify searching for invalid transaction code
**Preconditions**: On Service page
**Test Steps**:
1. Enter invalid transaction code
2. Tap search icon
**Expected Result**: Error message "Transaksi tidak ditemukan"
**Priority**: High

### TC_SERVICE_004: Transaction Search Empty
**Test Scenario**: Verify empty search validation
**Preconditions**: On Service page
**Test Steps**:
1. Leave search field empty
2. Tap search icon
**Expected Result**: Error message "Masukkan kode transaksi terlebih dahulu"
**Priority**: Medium

### TC_SERVICE_005: Repair Service Navigation
**Test Scenario**: Verify repair service button navigation
**Preconditions**: On Service page
**Test Steps**:
1. Tap "Perbaikan" card
**Expected Result**: Navigates to PerbaikanServicePage
**Priority**: High

### TC_SERVICE_006: Ongoing Transactions Display
**Test Scenario**: Verify ongoing transactions are displayed
**Preconditions**: User has pending/approved/in_progress/on_the_way orders
**Test Steps**:
1. Navigate to Service page
2. Observe "Transaksi Pending" section
**Expected Result**: Shows list of ongoing transactions with tracking buttons
**Priority**: Medium

### TC_SERVICE_007: Tracking Button Functionality
**Test Scenario**: Verify tracking button navigates correctly
**Preconditions**: Ongoing transactions displayed
**Test Steps**:
1. Tap "Tracking" button on any ongoing transaction
**Expected Result**: Navigates to TrackingPage with transaction details
**Priority**: High

---

## 4. Shopping Test Cases

### TC_SHOP_001: Marketplace Display
**Test Scenario**: Verify marketplace page displays correctly
**Preconditions**: User is logged in as customer
**Test Steps**:
1. Navigate to Beli tab
2. Observe page content
**Expected Result**: Shows search bar, brand filters, product lists
**Priority**: High

### TC_SHOP_002: Product Search
**Test Scenario**: Verify product search functionality
**Preconditions**: On marketplace page
**Test Steps**:
1. Enter product name in search bar
2. Observe results
**Expected Result**: Shows filtered products matching search query
**Priority**: High

### TC_SHOP_003: Brand Filter
**Test Scenario**: Verify brand filtering
**Preconditions**: On marketplace page
**Test Steps**:
1. Tap on a brand chip (e.g., "Asus")
2. Observe product list
**Expected Result**: Shows only products from selected brand
**Priority**: High

### TC_SHOP_004: Product Detail Navigation
**Test Scenario**: Verify product detail page navigation
**Preconditions**: Products displayed
**Test Steps**:
1. Tap on any product card
**Expected Result**: Navigates to DetailProdukPage
**Priority**: High

### TC_SHOP_005: Load More Products
**Test Scenario**: Verify load more functionality
**Preconditions**: Many products available, on "Semua Produk" section
**Test Steps**:
1. Scroll to bottom
2. Tap "Muat Lebih Banyak" button
**Expected Result**: Loads additional products
**Priority**: Medium

### TC_SHOP_006: Product Image Display
**Test Scenario**: Verify product images load correctly
**Preconditions**: Products with images displayed
**Test Steps**:
1. Observe product cards
**Expected Result**: Product images display correctly or show fallback for missing images
**Priority**: Medium

### TC_SHOP_007: Pull to Refresh
**Test Scenario**: Verify pull-to-refresh functionality
**Preconditions**: On marketplace page
**Test Steps**:
1. Pull down on product list
**Expected Result**: Refreshes product data
**Priority**: Medium

---

## 5. Technician Test Cases

### TC_TECH_001: Technician Dashboard Display
**Test Scenario**: Verify technician dashboard displays correctly
**Preconditions**: User logged in as technician
**Test Steps**:
1. Observe dashboard content
**Expected Result**: Shows tabs: Tugas, Pelacakan, Order List, Riwayat, Profil
**Priority**: High

### TC_TECH_002: Auto-Refresh Toggle
**Test Scenario**: Verify auto-refresh functionality
**Preconditions**: On technician dashboard
**Test Steps**:
1. Tap auto-refresh toggle button
2. Observe icon change
3. Tap again to re-enable
**Expected Result**: Auto-refresh enables/disables, shows appropriate notifications
**Priority**: Medium

### TC_TECH_003: New Order Notification
**Test Scenario**: Verify new order notifications
**Preconditions**: Auto-refresh enabled, new orders assigned
**Test Steps**:
1. Wait for new order assignment
2. Observe notification
**Expected Result**: In-app notification appears, can navigate to tasks
**Priority**: High

### TC_TECH_004: Task Status Update
**Test Scenario**: Verify order status update functionality
**Preconditions**: Technician has assigned tasks
**Test Steps**:
1. Go to Tasks tab
2. Tap status update button on a task
3. Select new status
**Expected Result**: Status updates successfully, shows confirmation message
**Priority**: High

### TC_TECH_005: Invalid Status Transition
**Test Scenario**: Verify status transition validation
**Preconditions**: Task in specific status
**Test Steps**:
1. Attempt invalid status change
**Expected Result**: Shows error message "Transisi status tidak valid"
**Priority**: Medium

### TC_TECH_006: Action Form Submission
**Test Scenario**: Verify action form for repairs
**Preconditions**: Task allows action input
**Test Steps**:
1. Tap "Tindakan" button on task
2. Fill action form
3. Submit
**Expected Result**: Action saved, status changes to waiting approval
**Priority**: High

### TC_TECH_007: Location Tracking Start
**Test Scenario**: Verify location tracking starts on enRoute status
**Preconditions**: Task status changes to enRoute
**Test Steps**:
1. Update task to enRoute
2. Check location tracking
**Expected Result**: Location tracking starts automatically
**Priority**: Medium

### TC_TECH_008: Maps Integration
**Test Scenario**: Verify maps open for customer address
**Preconditions**: Task has customer address
**Test Steps**:
1. Tap maps button on task
**Expected Result**: Opens Google Maps with customer address
**Priority**: Medium

### TC_TECH_009: History Tab Display
**Test Scenario**: Verify history tab shows completed transactions
**Preconditions**: Technician has completed orders
**Test Steps**:
1. Navigate to Riwayat tab
2. Observe transaction list
**Expected Result**: Shows completed transactions with details
**Priority**: Medium

---

## 6. Payment and Notification Test Cases

### TC_PAY_001: Payment Integration Display
**Test Scenario**: Verify payment UI elements (if implemented)
**Preconditions**: Payment flow initiated
**Test Steps**:
1. Initiate payment process
2. Observe payment screen
**Expected Result**: Payment screen displays correctly
**Priority**: Medium

### TC_NOTIF_001: In-App Notifications
**Test Scenario**: Verify in-app notification system
**Preconditions**: Actions that trigger notifications
**Test Steps**:
1. Perform action that triggers notification
2. Observe notification overlay
**Expected Result**: Notification appears with correct message
**Priority**: Medium

### TC_NOTIF_002: Notification Navigation
**Test Scenario**: Verify notification page navigation
**Preconditions**: Notifications exist
**Test Steps**:
1. Tap notification icon in app bar
2. Navigate to notification page
**Expected Result**: Shows list of notifications
**Priority**: Medium

### TC_NOTIF_003: Background Order Service
**Test Scenario**: Verify background order checking
**Preconditions**: App in background
**Test Steps**:
1. Put app in background
2. Wait for order updates
3. Bring app to foreground
**Expected Result**: Order updates reflected when app resumes
**Priority**: Low

---

## 7. Profile and Settings Test Cases

### TC_PROFILE_001: Profile Display
**Test Scenario**: Verify profile page displays user information
**Preconditions**: User logged in
**Test Steps**:
1. Navigate to Profile tab
2. Observe profile content
**Expected Result**: Shows user details, points, options
**Priority**: Medium

### TC_PROFILE_002: Profile Edit Navigation
**Test Scenario**: Verify profile edit navigation
**Preconditions**: On profile page
**Test Steps**:
1. Tap edit options (name, phone, birthday)
**Expected Result**: Navigates to respective edit pages
**Priority**: Medium

### TC_PROFILE_003: QR Code Display
**Test Scenario**: Verify QR code functionality
**Preconditions**: On profile page
**Test Steps**:
1. Tap QR code options
**Expected Result**: Shows QR codes for profile/add coins
**Priority**: Low

---

## 8. General App Test Cases

### TC_GENERAL_001: App Launch
**Test Scenario**: Verify app launches correctly
**Preconditions**: App installed
**Test Steps**:
1. Tap app icon
2. Wait for launch
**Expected Result**: Splash screen plays, then login or home based on session
**Priority**: High

### TC_GENERAL_002: App Resume
**Test Scenario**: Verify app resume from background
**Preconditions**: App in background
**Test Steps**:
1. Put app in background
2. Resume app
**Expected Result**: App resumes to previous state
**Priority**: Medium

### TC_GENERAL_003: Network Error Handling
**Test Scenario**: Verify network error handling
**Preconditions**: Network connectivity issues
**Test Steps**:
1. Disable network
2. Perform network-dependent action
**Expected Result**: Appropriate error messages displayed
**Priority**: High

### TC_GENERAL_004: Session Management
**Test Scenario**: Verify session persistence
**Preconditions**: User logged in
**Test Steps**:
1. Close and reopen app
**Expected Result**: User remains logged in
**Priority**: High

### TC_GENERAL_005: Logout Functionality
**Test Scenario**: Verify logout clears session
**Preconditions**: User logged in
**Test Steps**:
1. Logout from profile
2. Close and reopen app
**Expected Result**: User logged out, shows login screen
**Priority**: High

---

## Test Execution Summary

| Test Category | Total Cases | High Priority | Medium Priority | Low Priority |
|---------------|-------------|---------------|-----------------|--------------|
| Authentication | 7 | 4 | 3 | 0 |
| Customer Home | 5 | 3 | 2 | 0 |
| Service | 7 | 5 | 2 | 0 |
| Shopping | 7 | 4 | 3 | 0 |
| Technician | 9 | 5 | 3 | 1 |
| Payment/Notification | 3 | 0 | 2 | 1 |
| Profile/Settings | 3 | 0 | 2 | 1 |
| General App | 5 | 3 | 1 | 1 |
| **TOTAL** | **46** | **24** | **18** | **4** |

## Recommendations
1. Execute high-priority test cases first
2. Test on multiple devices and OS versions
3. Include real device testing for location and camera features
4. Test with various network conditions
5. Consider automated testing for regression testing

## Notes
- Some features may require backend services to be running
- Payment integration appears partially implemented (Midtrans commented out)
- Location services require appropriate permissions
- Camera functionality for technician actions requires testing on device