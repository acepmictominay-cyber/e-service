# ERD and Use Case Diagrams for Azza Service App

## Overview
Azza Service is a Flutter-based mobile application for computer and laptop service management. It connects customers with technicians for repair and cleaning services, includes product sales, and features a points/voucher system.

## Entity-Relationship Diagram (ERD)

The ERD diagram is saved in `erd_diagram.puml` (PlantUML format).

### Main Entities:

1. **User**
   - Represents customers and technicians
   - Fields: id, name, phone, email, role, points, birthday, address, created_at

2. **Order**
   - Service orders placed by customers
   - Fields: order_id, customer_id, technician_id, device details, service info, status, pricing, timestamps

3. **Product**
   - Items available for purchase
   - Fields: kode_barang, nama_produk, harga, deskripsi, gambar

4. **Voucher**
   - Discount vouchers
   - Fields: voucher_id, code, discount_percent, validity dates, usage limits

5. **UserVoucher**
   - Junction table for user-voucher claims
   - Fields: id, user_id, voucher_id, claimed_date, used status

6. **Promo**
   - Promotional items
   - Fields: kode_barang, tipe_produk, diskon, koin, gambar, harga

7. **Notification**
   - User notifications
   - Fields: id, user_id, title, subtitle, styling, timestamp

### Key Relationships:
- User places multiple Orders (as customer)
- User handles multiple Orders (as technician)
- User claims multiple UserVouchers
- Voucher can be claimed by multiple users (with limits)
- User receives multiple Notifications

## Use Case Diagram

The Use Case diagram is saved in `use_case_diagram.puml` (PlantUML format).

### Actors:

1. **Customer**
   - End users who need services or buy products

2. **Technician**
   - Service providers who handle repairs/cleaning

3. **Admin**
   - System administrators who approve orders

4. **Payment System**
   - External payment processing system

### Main Use Cases:

#### Customer Use Cases:
- Login/Register: Authentication
- View Home/Dashboard: Main app interface
- Order Service: Request cleaning/repair services
- Buy Products: Purchase computer accessories
- View Profile & Points: Manage account and loyalty points
- Chat: Communicate with technicians
- View Notifications: Check system messages
- Use Vouchers/Promos: Apply discounts
- View History: Past orders and transactions
- Scan QR Code: For payments or verification
- View Articles/Tips: Educational content

#### Technician Use Cases:
- Login: Authentication
- View Home/Dashboard: Task overview
- Accept Order: Take on service requests
- Update Order Status: Progress tracking
- Chat: Communicate with customers
- Track Location: GPS for service visits
- View Notifications: Order updates
- View History: Completed jobs

#### Admin Use Cases:
- Approve Order: Final approval for service estimates

#### System Use Cases:
- Process Payment: Handle transactions via Midtrans/QRIS

## How to View Diagrams

1. Install PlantUML plugin for VS Code or use online PlantUML viewer
2. Open the `.puml` files
3. The diagrams will render automatically

Alternatively, copy the PlantUML code to any PlantUML renderer online.

## App Flow Summary

1. **Customer Journey:**
   - Register/Login → Browse services/products → Place order → Chat with technician → Payment → Receive service → Rate/review

2. **Technician Journey:**
   - Login → View assigned tasks → Accept orders → Travel to location → Perform service → Update status → Complete order

3. **Admin Role:**
   - Review and approve high-value service estimates before technician proceeds

The app integrates maps for location tracking, push notifications for updates, QR code payments, and a comprehensive point/voucher system for customer loyalty.