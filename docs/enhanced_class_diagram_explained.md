# E-SERVICE MAGANG - ENHANCED UML CLASS DIAGRAM

## Diagram with Methods & Operations

**File:** `docs/enhanced_class_diagram_with_methods.puml`

This enhanced diagram includes:

1. **Database Entities** (with attributes)
2. **Service Classes** (with business logic methods)
3. **API Operations** (mapped to entity methods)
4. **Computed Properties** (getter methods)
5. **Missing Tables** (with reasons)

---

## Entity Classes with Operations

### 🗂️ Customer (`costomers` table)

#### Attributes
```plantuml
+ string cos_kode {PK}
+ string cos_nama
+ text cos_alamat
+ string cos_hp
+ date cos_tgl_lahir
+ int cos_poin
+ string username, email, password
+ string role
+ string cos_gambar
+ datetime created_at, updated_at
```

#### Operations (API Methods)
```dart
// CRUD Operations
getCostomers() → List<Customer>
getCostomerById(id) → Customer
addCostomer(data) → Customer
updateCostomer(id, data) → void
deleteCostomer(id) → void

// Profile
uploadProfile(File file) → {url, path}
```

---

### 🔧 Technician (`karyawan` table)

#### Attributes
```plantuml
+ string kry_kode {PK}
+ string kry_nama
+ text kry_alamat
+ string kry_hp
+ string username, password, role
+ datetime created_at, updated_at
```

#### Operations
```dart
// Fetch orders for this technician
getkry_kode(kryKode) → List<TechnicianOrder>
```

---

### 📦 Service Order (`transaksi` table) - CENTRAL ENTITY

#### Attributes
```plantuml
+ string trans_kode {PK}
+ string order_id
+ string cos_kode {FK → Customer}
+ string kry_kode {FK → Technician}
+ string device, merek, seri
+ string brg_nama, brg_merk, brg_sn
+ string status_garansi
+ text ket_keluhan
+ string trans_status ← 14 possible states
+ decimal trans_total
+ text alamat
+ string service_type
+ text approval_notes
+ decimal biaya_ongkir, visit_cost
+ datetime created_at, updated_at
```

#### Status Enum Values (OrderStatus)
```dart
waiting → accepted → enroute → arrived
→ waitingapproval → approved
→ pickingparts → repairing → completed
→ jobdone
waitingorder → waitingorderlist
```

#### Operations (API Methods)
```dart
// CRUD & Status Management
createTransaksi(data) → ServiceOrder
getTransaksi() → List<ServiceOrder>
getTransaksiByKode(transKode) → ServiceOrder
getPendingTransaksiByKode(transKode) → ServiceOrder

// Update Operations
updateTransaksiStatus(transKode, status) → void
updateTransaksiTemuan(transKode, ketKeluhan, total, [alsoSetStatus]) → Map

// Related Data
getOrderListByTransKode(transKode) → List<OrderItem>
getTindakanByTransKode(transKode) → List<ServiceAction>
```

#### Computed Properties (Getter Methods)
```dart
isApproved → bool              // status == OrderStatus.approved
getStatusColor() → Color       // UI color per status
getStatusDisplayName() → String // Indonesian display name
getStatusIcon() → IconData     // Material icon per status
```

#### Helper Methods (TechnicianOrderModel)
```dart
fromMap(Map) → TechnicianOrder
toMap() → Map
copyWith(...) → TechnicianOrder
OrderStatusExtension.fromString(status) → OrderStatus
```

---

### 📋 Order Items (`order_list` table)

#### Attributes
```plantuml
+ int id {PK}
+ string order_id
+ string trans_kode {FK → ServiceOrder}
+ string brg_kode
+ int jumlah
+ decimal price, subtotal
+ string trans_status
+ datetime created_at, updated_at
```

#### Operations
```dart
createOrderList(data) → OrderItem
getOrderList() → List<OrderItem>
getOrderListByTransKode(transKode) → List<OrderItem>
getOrderListByKryKode(kryKode) → List<OrderItem>
updateOrderListStatus(orderId, newStatus) → void
getOrderDetail(orderId) → OrderItem?
```

---

### 🔨 Service Actions (`tindakan` table)

#### Attributes
```plantuml
+ int id {PK}
+ string trans_kode {FK → ServiceOrder}
+ string tindakan              // Action description
+ decimal harga, subtotal
+ datetime created_at
```

#### Operations
```dart
createTindakan(data) → ServiceAction
getTindakanByTransKode(transKode) → List<ServiceAction>
' Used for: calculating DP, subtotal, total cost
```

---

### 🏷️ Product (`produk` table)

#### Attributes
```plantuml
+ string kode_barang {PK}
+ string nama_produk
+ int harga
+ text deskripsi
+ string gambar, gambar_url
```

#### Operations
```dart
getProduk() → List<Product>
getProdukPaginated(limit, offset) → {data, total, hasMore}
```

---

### 🎟️ Voucher (`vouchers` table)

#### Attributes
```plantuml
+ int voucher_id {PK}
+ string voucher_code
+ text description
+ decimal discount_percent
+ date start_date, end_date
+ int max_usage
+ string status               // active/inactive
+ string voucher_gambar
```

#### Operations
```dart
getVouchers() → List<Voucher>
```

---

### 🎁 User Voucher Junction (`user_vouchers` table)

#### Attributes
```plantuml
+ int id {PK}
+ string id_costomer {FK → Customer}
+ int voucher_id {FK → Voucher}
+ datetime claimed_date
+ string used                 // yes/no
```

#### Operations
```dart
getUserVouchers(customerId) → List<UserVoucher>
claimVoucher(customerId, voucherId) → UserVoucher
updateUserVoucher(userVoucherId, updates) → void
markVoucherUsed(voucherCode, customerId) → void
```

---

### 💳 Payment Transaction (`payment_transactions` table)

#### Attributes
```plantuml
+ bigint id {PK}
+ string external_id           // From payment gateway
+ string transaction_id
+ string payment_method        // EWALLET_OVO, QRIS, VA
+ decimal amount
+ string status                // PENDING, SUCCESS, FAILED
+ text metadata {JSON}
+ datetime created_at, updated_at
```

#### Operations
```dart
getPaymentTransactions(customerId) → List<PaymentTransaction>
```

---

## 🏗️ Service Layer Classes

### CheckoutService (`lib/api_services/api_service.dart`)

**Responsibility:** Order creation, payment, delivery tracking

#### Methods
```dart
estimateShipping(lat, lng) → Map
createCheckoutOrder(customerId, items, total, paymentMethod, address, lat, lng, [voucher]) → Map
updatePaymentStatus(orderCode, status) → Map
updateDeliveryStatus(orderCode, status) → Map
updateCheckoutOrder(orderCode, updates) → Map
getOrderByCode(orderCode) → Map
getCustomerOrders(customerId) → List<Map>
getAllOrders() → List<Map>
getExpeditionZones() → List<Map>
validateVoucher(voucherCode, customerId) → Map
validatePointExchange(customerId, kodeBarang) → Map
processPointExchange(customerId, kodeBarang, orderData) → Map
addPointsFromPurchase(customerId, amount, orderCode) → Map
getPointTransactions(customerId) → List<Map>
```

---

### LocationTrackingService (`lib/services/location_service.dart`)

**Responsibility:** Real-time GPS tracking of technicians

#### Methods
```dart
startTracking(transKode, kryKode) → void
stopTracking() → void
updateDriverLocation(transKode, kryKode, lat, lng) → void
getDriverLocation(transKode) → Map?
isTrackingActive() → bool

// Background tracking
saveTrackingState() → void
clearTrackingState() → void
```

---

### BackgroundOrderService (`lib/Others/background_order_service.dart`)

**Responsibility:** Background sync of new orders for technicians

#### Methods
```dart
scheduleBackgroundSync() → void
syncNewOrders() → List<TechnicianOrder>
checkForNewOrders() → bool
' Polls API for waiting orders assigned to current technician
```

---

### NotificationService (`lib/Others/notification_service.dart`)

#### Methods
```dart
initialize() → void
showOrderNotification(order) → void
showStatusUpdateNotification(transKode, status) → void
scheduleNotification(title, body, time) → void
cancelNotification(id) → void
```

---

## 📊 Operation Summary Table

| Entity | CRUD | Business Logic | Queries |
|--------|------|---------------|---------|
| Customer | ✓✓✓✓ (4) | uploadProfile | getCostomers, getById |
| Technician | ✓ (read only) | getkry_kode | - |
| ServiceOrder | ✓✓✓ (3) | updateStatus, updateTemuan, isApproved | getByKode, getByTransKode |
| OrderItem | ✓✓✓ (3) | updateStatus | getByTransKode, getByKryKode |
| ServiceAction | ✓✓ (2) | - | getByTransKode |
| Product | ✓✓ (2) | - | getPaginated |
| Voucher | ✓ (1) | - | - |
| UserVoucher | ✓✓✓ (3) | claim, markUsed | getUserVouchers |
| PaymentTransaction | ✓ (1) | - | getByCustomer |

---

## 🔗 Relationship Operations

### Cascading/Related Operations
```dart
// When creating order:
createTransaksi() → returns trans_kode
createOrderList({trans_kode, items}) → multiple order_list rows
createTindakan({trans_kode, actions}) → multiple tindakan rows

// When updating order:
updateTransaksiStatus() → updates trans_status
updateOrderListStatus() → updates individual item status

// When fetching order details:
getTransaksiByKode() → main order
getOrderListByTransKode() → line items
getTindakanByTransKode() → service actions
getPaymentTransactions() → payment status
```

---

## ❌ Missing Operations (Because Tables Don't Exist)

```dart
// Status Tracking (no table)
StatusTracking.logStatusChange(transKode, oldStatus, newStatus, changedBy) → void
StatusTracking.getStatusHistory(transKode) → List<StatusTracking>

// TTS Receipt (no table)
TTS.createReceipt(transKode, customerSig, technicianSig) → TTS
TTS.getReceipt(transKode) → TTS
TTS.verifySignature(transKode) → bool

// Assignment (implicit in transaksi.kry_kode)
Assignment.assignTechnician(transKode, kryKode, assignedBy) → Assignment
Assignment.reassignTechnician(transKode, newKryKode) → void
Assignment.getAssignmentHistory(transKode) → List<Assignment>
```

---

## 📁 File Locations Reference

| Class/Service | File Path |
|---------------|-----------|
| `TechnicianOrder` model | `lib/models/technician_order_model.dart` |
| `ApiService` | `lib/api_services/api_service.dart` |
| `LocationTrackingService` | `lib/services/location_service.dart` |
| `BackgroundOrderService` | `lib/Others/background_order_service.dart` |
| `TrackingPage` (UI) | `lib/Service/tracking_driver.dart` |
| `OrderStatus` enum | `lib/models/technician_order_model.dart:3-16` |

---

## 🎯 Key Business Logic

1. **Status Flow** - 14 states managed by `OrderStatus` enum
2. **Location Tracking** - GPS updates via `updateDriverLocation()`
3. **Payment Integration** - Xendit/Midtrans via `payment_service.dart`
4. **Point System** - Auto-add via `addPointsFromPurchase()`
5. **Voucher System** - Claim/validate/use workflow
6. **Background Sync** - Periodic polling for new technician orders

---

## 🚫 Limitations

- **No status history table** → Cannot audit status changes
- **No assignment table** → Cannot track who assigned technician
- **No digital signature** → No TTS/receipt confirmation
- **No service-level agreements** → No SLA tracking
- **No multi-technician** → One technician per order only (`kry_kode` single FK)

---

## 💡 Suggested Improvements

```plantuml
' If implementing missing tables:

' 1. Status Tracking
class status_tracking {
  + int id PK
  + string trans_kode FK
  + string old_status
  + string new_status
  + string changed_by FK → karyawan
  + datetime changed_at
  + text notes
  ' Method: logTransition()
}

' 2. TTS Receipt
class tts {
  + int tts_kode PK
  + string trans_kode FK
  + text customer_signature
  + text technician_signature
  + datetime signed_at
  + text notes
  ' Method: signAsCustomer(), signAsTechnician(), verify()
}

' 3. Assignment History
class penugasan_teknisi {
  + int assignment_id PK
  + string trans_kode FK
  + string kry_kode FK
  + string assigned_by FK
  + datetime assigned_at
  + text reason
  ' Method: assign(), reassign(), cancel()
}
```
