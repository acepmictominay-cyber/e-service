# Service Ordering Process - Scenario Diagram

```mermaid
graph TD
    A[User/Home Page] --> B[Select Service Type]
    
    subgraph "Service Selection"
        B --> C[Service.dart<br/>Service Categories]
        B --> D[Perbaikan Service<br/>Repair Services]
        B --> E[Order Service<br/>Direct Order]
    end
    
    C --> F[Service Details Page]
    D --> F
    E --> F
    
    F --> G{User Action?}
    
    G --> H[Place Order<br/>order_service.dart]
    G --> I[Start Repair<br/>progres_service.dart]
    
    subgraph "Order Process"
        H --> J[Create Order Object]
        J --> K[Order Confirmation<br/> struck_pesanan.dart]
        K --> L[Payment Method Selection]
        L --> M[Payment Processing<br/>detail_service_midtrans.dart]
        M --> N[Payment Confirmation]
        N --> O[Upload Payment Proof<br/>payment_proof_confirmation.dart]
    end
    
    subgraph "Service Progress"
        I --> P[Technician Assignment<br/> teknisi_home.dart]
        P --> Q[Progress Tracking<br/> progres_service.dart]
        Q --> R[Service Completion]
    end
    
    subgraph "Post Service"
        O --> S[Order Status Updated]
        R --> S
        S --> T[Review/Rating]
        T --> U[Service History]
    end
    
    subgraph "Additional Features"
        A --> V[QR Scanner<br/>scan_qr.dart]
        V --> W[QR Detail<br/>show_qr_detail.dart]
        V --> X[Add Coin<br/>show_qr_addcoin.dart]
        
        A --> Y[AI Chat Support<br/>ai_chat_service.dart]
        Y --> Z[OCR Service<br/>ocr_service.dart]
    end
```

---

## Detailed Flow Steps

### 1. **Service Browsing** (`lib/Service/Service.dart`)
   - User views available service categories
   - Selects desired service type

### 2. **Order Placement** (`lib/Service/order_service.dart`)
   - User fills order details
   - Creates new order record
   - Redirects to order confirmation

### 3. **Order Confirmation** (`lib/Others/struck_pesanan.dart`)
   - Displays order summary
   - Shows payment instructions

### 4. **Payment Processing** (`lib/Service/detail_service_midtrans.dart`)
   - Integrates with Midtrans payment gateway
   - Handles payment transactions

### 5. **Payment Proof** (`lib/Others/payment_proof_confirmation.dart`)
   - User uploads payment proof
   - Admin verifies payment

### 6. **Service Progress** (`lib/Service/progres_service.dart`)
   - Technician assigned
   - Status tracked (pending → processing → completed)

### 7. **Repair Service Flow** (`lib/Service/perbaikan_service.dart`)
   - Specific flow for repair services
   - Includes damage assessment

### 8. **Admin/Store** (`lib/Admin/instore_transaction.dart`)
   - Admin manages transactions
   - Tracks in-store orders

### 9. **QR Features** (`lib/Profile/scan_qr.dart`, `show_qr_detail.dart`, `show_qr_addcoin.dart`)
   - QR code scanning
   - Coin/reward system

### 10. **AI & OCR** (`lib/services/ai_chat_service.dart`, `ocr_service.dart`)
    - AI chat assistant
    - OCR for document/image processing

---

## User Roles Interactions

| Role | Actions | Files Involved |
|------|---------|----------------|
| **Customer** | Browse, Order, Pay, Track, Review | order_service.dart, progres_service.dart |
| **Technician** | Accept, Process, Complete Service | teknisi_home.dart, progres_service.dart |
| **Admin** | Manage Orders, Verify Payment, Confirm | instore_transaction.dart, payment_proof_confirmation.dart |
| **System** | AI Support, QR Processing, OCR | ai_chat_service.dart, ocr_service.dart |

---

## State Transition Diagram

```mermaid
stateDiagram-v2
    [*] --> DRAFT: Create Order
    DRAFT --> PENDING: Submit Order
    PENDING --> AWAITING_PAYMENT: Order Confirmed
    AWAITING_PAYMENT --> VERIFICATION_PENDING: Proof Uploaded
    VERIFICATION_PENDING --> ASSIGNED: Payment Verified
    ASSIGNED --> IN_PROGRESS: Technician Assigned
    IN_PROGRESS --> COMPLETED: Service Done
    COMPLETED --> [*]: Order Closed
    
    note right of DRAFT
        order_service.dart
        struck_pesanan.dart
    end note
    
    note right of AWAITING_PAYMENT
        detail_service_midtrans.dart
        payment_proof_confirmation.dart
    end note
    
    note right of IN_PROGRESS
        progres_service.dart
        perbaikan_service.dart
    end note
```