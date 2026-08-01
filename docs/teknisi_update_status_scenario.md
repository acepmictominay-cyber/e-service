# Technician Update Repair Status - Scenario Diagram

```mermaid
graph TD
    A[Technician Home<br/>teknisi_home.dart] --> B[Task List<br/>tasks_tab.dart]
    
    subgraph "Technician Dashboard"
        B --> C[View Assigned Orders]
        B --> D[Auto-Refresh Toggle]
        B --> E[Open Maps Navigation]
    end
    
    C --> F{Order Status?}
    
    subgraph "Status: WAITING"
        F --> G[Accept Order<br/>_updateOrderStatus]
        G --> H[Status: ACCEPTED]
    end
    
    subgraph "Status: ACCEPTED"
        H --> I[Mark En Route<br/>_updateOrderStatus]
        I --> J[Status: EN_ROUTE<br/>Location Tracking Start]
    end
    
    subgraph "Status: EN_ROUTE"
        J --> K[Mark Arrived<br/>_updateOrderStatus]
        K --> L[Status: ARRIVED<br/>Location Tracking Stop]
    end
    
    subgraph "Status: ARRIVED"
        L --> M[Perform Actions]
        M --> N{Action Type?}
        
        N --> O[Direct Complete<br/>_updateOrderStatus]
        N --> P[Request Approval<br/>_showTindakanForm]
    end
    
    subgraph "Action Input (Tindakan)"
        P --> Q[Select Action Type]
        Q --> R[Dropdown/Manual Input]
        R --> S[Quantity & Details]
        S --> T[Submit to Admin<br/>_saveTindakanAndUpdateStatus]
        T --> U[Status: WAITING_APPROVAL]
    end
    
    subgraph "Status: WAITING_APPROVAL"
        U --> V[Admin Review]
        V --> W{Approval Decision}
        W --> X[Status: APPROVED]
        W --> Y[Status: WAITING<br/>Revision Request]
    end
    
    subgraph "Status: APPROVED"
        X --> Z[Pick Parts<br/>_updateOrderStatus]
        Z --> AA[Status: PICKING_PARTS<br/>Location Tracking Start]
    end
    
    subgraph "Status: PICKING_PARTS"
        AA --> AB[Start Repair<br/>_updateOrderStatus]
        AB --> AC[Status: REPAIRING<br/>Location Tracking Stop]
    end
    
    subgraph "Status: REPAIRING"
        AC --> AD[Complete Service<br/>_updateOrderStatus]
        AD --> AE[Status: COMPLETED]
    end
    
    subgraph "Additional Features"
        A --> AF[Tracking Tab<br/>tracking_tab.dart]
        AF --> AG[Real-time Location]
        
        A --> AH[Waiting Tasks<br/>waiting_tasks_page.dart]
        AH --> AI[View Pending Approval]
        
        A --> AJ[History Tab<br/>history_tab.dart]
        AJ --> AK[View Completed Orders]
        
        A --> AL[Chat/Notifications<br/>notifikasi.dart]
    end
    
    style G fill:#90EE90
    style H fill:#90EE90
    style I fill:#FFE4B5
    style J fill:#FFE4B5
    style K fill:#ADD8E6
    style L fill:#ADD8E6
    style O fill:#90EE90
    style U fill:#FFB6C1
    style X fill:#90EE90
    style Z fill:#FFE4B5
    style AB fill:#FFE4B5
    style AD fill:#90EE90
    style AE fill:#90EE90
```

---

## Status Transition Flow

```mermaid
stateDiagram-v2
    [*] --> WAITING: Order Assigned
    
    WAITING --> ACCEPTED: Technician Accepts
    ACCEPTED --> EN_ROUTE: Mark En Route
    EN_ROUTE --> ARRIVED: Arrive at Location
    
    ARRIVED --> COMPLETED: Direct Complete
    ARRIVED --> WAITING_APPROVAL: Request Parts/Action
    
    WAITING_APPROVAL --> APPROVED: Admin Approves
    WAITING_APPROVAL --> WAITING: Admin Rejects
    
    APPROVED --> PICKING_PARTS: Start Picking Parts
    PICKING_PARTS --> REPAIRING: Start Repairing
    REPAIRING --> COMPLETED: Service Done
    
    COMPLETED --> [*]: Order Closed
    
    note right of WAITING
        teknisi_home.dart
        tasks_tab.dart
    end note
    
    note right of EN_ROUTE
        LocationService.instance.startTracking()
    end note
    
    note right of ARRIVED
        LocationService.instance.stopTracking()
    end note
    
    note right of WAITING_APPROVAL
        _showTindakanForm()
        ApiService.createTindakan()
    end note
    
    note right of REPAIRING
        perbaikan_service.dart
    end note
```

---

## Detailed Flow Steps

### 1. **Technician Dashboard** (`lib/Teknisi/teknisi_home.dart`)
   - View assigned orders list
   - Auto-refresh toggle (every 4 seconds)
   - Notification for new orders

### 2. **Accept Order** (`_updateOrderStatus`)
   - Technician accepts pending order
   - Validates status transition: WAITING → ACCEPTED

### 3. **En Route** 
   - Mark as traveling to location
   - Enters status: EN_ROUTE
   - Location tracking starts

### 4. **Arrived**
   - Mark arrival at customer location
   - Enters status: ARRIVED
   - Location tracking stops

### 5. **Action/Tindakan Form** (`_showTindakanForm`)
   - Standard actions: Cleaning, Sparepart Replacement, Calibration, Diagnose, Hardware Repair, Software Update
   - Custom manual input option
   - Quantity and detail inputs

### 6. **Submit for Approval**
   - Technician inputs tindakan details
   - Sends to admin for approval
   - Status changes to WAITING_APPROVAL

### 7. **Admin Decision**
   - Admin reviews requested actions
   - Approve or reject with feedback
   - If approved: status → APPROVED
   - If rejected: status → WAITING (for revision)

### 8. **Pick Parts** (`_updateOrderStatus`)
   - After approval, technician picks up parts
   - Status: PICKING_PARTS
   - Location tracking starts

### 9. **Repairing**
   - Technician performs repair work
   - Status: REPAIRING

### 10. **Complete Service**
   - Technician marks service as done
   - Status: COMPLETED
   - Location tracking stops

---

## Valid Status Transitions

| Current Status | Next Status | Trigger | Location Tracking |
|----------------|------------|---------|-------------------|
| WAITING | ACCEPTED | Accept Order | - |
| ACCEPTED | EN_ROUTE | Mark En Route | Start |
| EN_ROUTE | ARRIVED | Mark Arrived | Stop |
| ARRIVED | COMPLETED | Direct Complete | - |
| ARRIVED | WAITING_APPROVAL | Request Approval | - |
| WAITING_APPROVAL | WAITING | Admin Reject | - |
| APPROVED | PICKING_PARTS | Start Picking | Start |
| PICKING_PARTS | REPAIRING | Start Repair | Stop |
| REPAIRING | COMPLETED | Complete | - |

---

## Files Involved

| File | Description |
|------|-------------|
| `lib/Teknisi/teknisi_home.dart` | Main technician dashboard |
| `lib/Teknisi/tasks_tab.dart` | Task list view |
| `lib/Teknisi/tracking_tab.dart` | Location tracking view |
| `lib/Teknisi/waiting_tasks_page.dart` | Pending approval view |
| `lib/Teknisi/history_tab.dart` | Completed orders history |
| `lib/Teknisi/teknisi_profil.dart` | Technician profile |
| `lib/Service/progres_service.dart` | Service progress tracking |
| `lib/Service/perbaikan_service.dart` | Repair service handling |
| `lib/api_services/api_service.dart` | API communication |

---

## User Actions Summary

| Action | Method | File |
|--------|--------|------|
| View Assigned Orders | `_refreshData()` | teknisi_home.dart |
| Accept Order | `_updateOrderStatus(order, ACCEPTED)` | teknisi_home.dart |
| Mark En Route | `_updateOrderStatus(order, EN_ROUTE)` | teknisi_home.dart |
| Mark Arrived | `_updateOrderStatus(order, ARRIVED)` | teknisi_home.dart |
| Input Action Details | `_showTindakanForm()` | teknisi_home.dart |
| Submit for Approval | `_saveTindakanAndUpdateStatus()` | teknisi_home.dart |
| Pick Parts | `_updateOrderStatus(order, PICKING_PARTS)` | teknisi_home.dart |
| Start Repair | `_updateOrderStatus(order, REPAIRING)` | teknisi_home.dart |
| Complete Service | `_updateOrderStatus(order, COMPLETED)` | teknisi_home.dart |
| View on Maps | `_openMaps()` | teknisi_home.dart |