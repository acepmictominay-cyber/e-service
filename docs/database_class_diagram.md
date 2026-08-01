# Database Class Diagram - E-Service Magang

## Diagram Format: PlantUML (.puml)

The complete UML class diagram has been saved to:
**`docs/database_class_diagram.puml`**

You can view this diagram by:
1. Opening the `.puml` file in VS Code with the PlantUML extension
2. Using an online PlantUML viewer: https://www.plantuml.com/plantuml
3. Rendering it locally with PlantUML command line tool

---

## Quick Visual Overview (Mermaid Syntax)

If you prefer Mermaid (for GitHub/GitLab rendering), here's the equivalent:

````mermaid
erDiagram
    CUSTOMER ||--o{ ORDER : "places"
    TECHNICIAN ||--o{ ORDER : "handles"
    ORDER ||--o{ ORDER_ITEM : "contains"
    ORDER ||--o{ SERVICE_ACTION : "performs"
    ORDER ||--o{ PAYMENT_TRANSACTION : "pays_for"
    CUSTOMER ||--o{ USER_VOUCHER : "claims"
    VOUCHER ||--o{ USER_VOUCHER : "available_to"

    CUSTOMER {
        string cos_kode PK
        string cos_nama
        text cos_alamat
        string cos_hp
        date cos_tgl_lahir
        int cos_poin
        string username
        string email
        datetime created_at
        datetime updated_at
    }

    TECHNICIAN {
        string kry_kode PK
        string kry_nama
        text kry_alamat
        string kry_hp
        string username
        datetime created_at
        datetime updated_at
    }

    ORDER {
        string trans_kode PK
        string cos_kode FK
        string kry_kode FK
        string trans_status
        decimal trans_total
        text ket_keluhan
        text alamat
        string device
        string merek
        string seri
        datetime created_at
        datetime updated_at
    }

    ORDER_ITEM {
        int id PK
        string trans_kode FK
        string brg_kode
        int jumlah
        decimal price
        decimal subtotal
    }

    SERVICE_ACTION {
        int id PK
        string trans_kode FK
        string tindakan
        decimal harga
        decimal subtotal
        datetime created_at
    }

    PRODUCT {
        string kode_barang PK
        string nama_produk
        int harga
        text deskripsi
    }

    VOUCHER {
        int voucher_id PK
        string voucher_code
        decimal discount_percent
        date start_date
        date end_date
        int max_usage
        string status
    }

    USER_VOUCHER {
        int id PK
        string id_costomer FK
        int voucher_id FK
        datetime claimed_date
        string used
    }

    PAYMENT_TRANSACTION {
        bigint id PK
        string external_id
        string payment_method
        decimal amount
        string status
        datetime created_at
    }
````

---

## Table Summary

### ✅ Implemented Tables

| Table | Indonesian Name | Purpose | Primary Key |
|-------|----------------|---------|-------------|
| `costomers` | Pelanggan | Customer data | `cos_kode` |
| `karyawan` | Karyawan | Technician/staff data | `kry_kode` |
| `transaksi` | Transaksi | Main service orders | `trans_kode` |
| `order_list` | Order List | Order items/services | `id` |
| `tindakan` | Tindakan | Service actions performed | `id` |
| `produk` | Produk | Products inventory | `kode_barang` |
| `vouchers` | Voucher | Discount vouchers | `voucher_id` |
| `user_vouchers` | User Voucher | Voucher claims | `id` |
| `payment_transactions` | Payment | Payment gateway records | `id` |

### ⚠️ Missing Tables (Requested but Not Implemented)

| Table | Purpose | Status |
|-------|---------|--------|
| `status_tracking` | Track status change history | **NOT FOUND** |
| `tts` (Tanda Terima Service) | Digital receipt/signature capture | **NOT FOUND** |
| `penugasan_teknisi` | Technician assignment tracking | **NOT FOUND** |

> **Note:** Status tracking is done via `transaksi.trans_status` (overwritten). Technician assignment uses `transaksi.kry_kode`. No history/signature tables exist.

---

## Relationship Cardinality

```
Customer (1) ────► (Many) ServiceOrder
Technician (1) ───► (Many) ServiceOrder
ServiceOrder (1) ─► (Many) OrderItem
ServiceOrder (1) ─► (Many) ServiceAction
ServiceOrder (1) ─► (Many) PaymentTransaction
Customer (1) ─────► (Many) UserVoucher
Voucher (1) ──────► (Many) UserVoucher
```

---

## Key Findings

1. **No normalization for status history** - All status updates overwrite the previous value in `trans_status` field
2. **No separate assignment table** - Technician assignment is a simple foreign key (`kry_kode`) in `transaksi`
3. **No signature/receipt confirmation** - TTS concept not implemented in database
4. **Order items (`order_list`) and actions (`tindakan`)** are separate tables with FK to `transaksi`
5. **Customer points** tracked via `cos_poin` field (not normalized into transaction history)

---

## Files Analyzed

- `lib/models/technician_order_model.dart` - Order model & status enum
- `lib/api_services/api_service.dart` - All API endpoints revealing table structures
- `lib/Service/*.dart` - Service pages using all table fields
- `lib/Teknisi/*.dart` - Technician pages with assignment logic
- `lib/Others/*.dart` - Checkout, payment, notification modules
