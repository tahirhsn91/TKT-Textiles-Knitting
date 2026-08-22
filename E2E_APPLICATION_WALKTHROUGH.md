# TKT Textiles Knitting System - Complete End-to-End Application Walkthrough

**Document Version:** 1.0  
**Date:** August 22, 2026  
**Application:** TKT Textiles Knitting Management System  
**Environment:** Local Development (localhost:3001)

---

## Table of Contents
1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [User Roles & Permissions](#user-roles--permissions)
4. [Journey 1: Administrator Walkthrough](#journey-1-administrator-walkthrough)
5. [Journey 2: Manager Walkthrough](#journey-2-manager-walkthrough)
6. [Journey 3: Supervisor Walkthrough](#journey-3-supervisor-walkthrough)
7. [Core Features Breakdown](#core-features-breakdown)
8. [Data Flow Architecture](#data-flow-architecture)

---

## Overview

The TKT Textiles Knitting System is a comprehensive internal operations management platform designed for textile manufacturing facilities. It orchestrates:

- **Production Tracking** - Daily production records, machine maintenance, factory operations
- **Inventory Management** - Yarn receipts, delivery tracking, fabric balance reports
- **Financial Operations** - Transactions, payroll, salary entries, advances processing
- **Human Resources** - Employee management, attendance tracking
- **Reporting & Analytics** - Production analytics, inventory reports, financial dashboards

The system enforces **Role-Based Access Control (RBAC)** with three distinct user roles:
- **Admin** - Full system access, permission management
- **Manager** - Operations oversight, financial management
- **Supervisor** - Execution-level operations, production tracking

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (React + Vite)                  │
│              localhost:3001 - Responsive Web UI             │
│  (Dashboard, Forms, Analytics, Settings, Protected Routes)  │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTP/REST API
                     │
┌────────────────────▼────────────────────────────────────────┐
│              BACKEND (Node.js + Express)                    │
│           localhost:8080 - REST API Server                  │
│  (Authentication, RBAC Middleware, Data Validation)         │
└────────────────────┬────────────────────────────────────────┘
                     │ SQL Queries
                     │
┌────────────────────▼────────────────────────────────────────┐
│         DATABASE (PostgreSQL 16 - heliumdb)                 │
│    Persistent Data Storage (Roles, Users, Business Data)    │
└─────────────────────────────────────────────────────────────┘
```

---

## User Roles & Permissions

### Role Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                      ADMINISTRATOR                          │
│  • Full system access                                       │
│  • All module permissions (implicit)                        │
│  • User & role management                                   │
│  • Permission configuration                                 │
└─────────────────────────────────────────────────────────────┘
              ▲                                 ▲
              │                                 │
         ┌────┴────────────────────────────────┴─────┐
         │                                            │
    ┌────▼────────────────┐               ┌──────────▼────────┐
    │    MANAGER          │               │   SUPERVISOR      │
    │  (Operations Lead)  │               │  (Field Worker)   │
    ├─────────────────────┤               ├───────────────────┤
    │ ✓ Dashboard         │               │ ✓ Dashboard       │
    │ ✓ Transactions      │               │ ✓ Daily Product   │
    │ ✓ Daily Production  │               │ ✓ Yarn Receipts   │
    │ ✓ Yarn Receipts     │               │ ✓ Daily Delivs    │
    │ ✓ Daily Deliveries  │               │ ✓ Maintenance     │
    │ ✓ Payroll           │               │                   │
    │ ✓ Reports           │               │                   │
    │ ✓ Maintenance       │               │                   │
    └─────────────────────┘               └───────────────────┘
```

### Permission Matrix

| Feature | Admin | Manager | Supervisor |
|---------|:-----:|:-------:|:----------:|
| Dashboard | ✓ | ✓ | ✓ |
| Transactions | ✓ | ✓ | ✗ |
| Daily Production | ✓ | ✓ | ✓ |
| Yarn Receipts | ✓ | ✓ | ✓ |
| Daily Deliveries | ✓ | ✓ | ✓ |
| Payroll | ✓ | ✓ | ✗ |
| Reports | ✓ | ✓ | ✗ |
| Maintenance | ✓ | ✓ | ✓ |
| Settings (Users) | ✓ | ✗ | ✗ |

---

## Journey 1: Administrator Walkthrough

### Story: "Hassan - System Administrator"

**Role:** Administrator  
**Credentials:** `admin` / `tkttextiles12#`  
**Scenario:** Hassan starts his day by reviewing system health, managing users, and configuring role permissions.

---

### Step 1: Authentication & Login

**URL:** `http://localhost:3001/login`

**Visual Flow:**
```
┌─────────────────────────────────────┐
│                                     │
│   TKT TEXTILES LOGIN SCREEN        │
│                                     │
│   Username: [admin           ]     │
│   Password: [••••••••••••   ]     │
│                                     │
│   [ LOGIN BUTTON ]                  │
│                                     │
│   © 2026 TKT Textiles              │
└─────────────────────────────────────┘
```

**Process:**
1. User navigates to `http://localhost:3001`
2. Application detects no auth token → redirects to `/login`
3. User enters credentials: `admin` / `tkttextiles12#`
4. Frontend submits POST request to backend: `POST /api/auth/login`
5. Backend validates credentials via Argon2 hash comparison
6. Backend issues JWT token (stored in browser localStorage)
7. Frontend redirects to `/dashboard`

**Backend Flow:**
```
POST /api/auth/login
├─ Extract username + password from request body
├─ Query database: SELECT * FROM app_user WHERE username = 'admin'
├─ Compare passwordHash using argon2.verify()
├─ If match:
│  ├─ Query roleId and role permissions
│  ├─ Sign JWT with user ID + role + permissions
│  └─ Return token + user profile
└─ If no match: Return 401 Unauthorized
```

---

### Step 2: Dashboard Access

**URL:** `http://localhost:3001/dashboard`

**Module ID:** `dashboard`  
**Permission Check:** Required

**Visual Overview:**
```
┌──────────────────────────────────────────────────────────────┐
│  TKT TEXTILES KNITTING SYSTEM                   👤 admin     │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  📊 DASHBOARD                                                │
│                                                               │
│  ┌─────────────────────┐  ┌──────────────────┐              │
│  │ PRODUCTION STATS    │  │ DAILY OVERVIEW   │              │
│  │ ═══════════════════ │  │ ════════════════ │              │
│  │ Today: 150 units    │  │ Revenue: $12,500 │              │
│  │ Target: 200 units   │  │ Expenses: $8,200 │              │
│  │ YTD: 18,500 units   │  │ Net Profit: $4.3K│              │
│  └─────────────────────┘  └──────────────────┘              │
│                                                               │
│  ┌──────────────────────────────────────────┐               │
│  │ PRODUCTION TREND (Last 30 Days)          │               │
│  │                        ╱╲    ╱╲          │               │
│  │              ╱╲    ╱╲╱  ╲╱  ╲╱           │               │
│  │    ╱╲╱╲╱╲╱╲╱  ╲╱╲╱                      │               │
│  └──────────────────────────────────────────┘               │
│                                                               │
│  ┌─────────────────┐  ┌──────────────────┐                 │
│  │ ACTIVE MACHINES │  │ PENDING TASKS    │                 │
│  │ ═════════════════ │  │ ════════════════ │                 │
│  │ • Loom A1: Running│  │ • Machine B2 Oil│                 │
│  │ • Loom B3: Idle   │  │ • Fabric QC      │                 │
│  │ • Loom C2: Running│  │ • Inventory Audit│                 │
│  └─────────────────┘  └──────────────────┘                 │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

**Data Loaded:**
- Production metrics (daily, YTD)
- Revenue/expense summary
- Active machines status
- Pending maintenance tasks
- Production trend chart (via Recharts)

**API Calls:**
```
GET /api/dashboard/summary           → Daily metrics
GET /api/dashboard/production-stats  → Production data + charts
GET /api/machines/status             → Active machines
GET /api/maintenance/pending         → Pending tasks
GET /api/financials/summary          → Revenue/expense summary
```

---

### Step 3: User Management (Admin-Only Feature)

**URL:** `http://localhost:3001/settings`

**Module ID:** `users`  
**Permission Check:** Admin role only

**Visual Screen:**
```
┌──────────────────────────────────────────────────────────────┐
│  SETTINGS → USER MANAGEMENT                                  │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  👥 ACTIVE USERS                                             │
│  ═════════════════════════════════════════════════════════════│
│                                                               │
│  ID │ Username      │ Display Name      │ Role      │ Active │
│  ───┼───────────────┼──────────────────┼───────────┼────────│
│  1  │ admin         │ Administrator    │ Admin     │   ✓    │
│  2  │ khurranhassan │ Khurram Hassan   │ Manager   │   ✓    │
│  3  │ iftikhar      │ Iftikhar Ahmed   │ Supervsr  │   ✓    │
│  4  │ hassanimam    │ Hassan Imam      │ Manager   │   ✓    │
│  5  │ tahirhassan   │ Tahir Hassan     │ Admin     │   ✓    │
│  6  │ manager       │ Manager User     │ Manager   │   ✓    │
│  7  │ supervisor    │ Supervisor User  │ Supervsr  │   ✓    │
│                                                               │
│  [ + CREATE USER ]  [ EDIT ] [ DEACTIVATE ]                 │
│                                                               │
│  ROLE PERMISSIONS MATRIX                                     │
│  ═════════════════════════════════════════════════════════════│
│                                                               │
│  Role       │ Dashboard │ Transact │ Production │ Payroll   │
│  ───────────┼───────────┼──────────┼────────────┼──────────│
│  Admin      │  ✓ (All)  │  ✓ (All) │  ✓ (All)   │ ✓ (All)  │
│  Manager    │  ✓ View   │  ✓ Edit  │  ✓ Edit    │ ✓ Edit   │
│  Supervisor │  ✓ View   │  ✗       │  ✓ Edit    │ ✗        │
│                                                               │
│  [ EDIT PERMISSIONS ]                                        │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

**Features:**
1. **User List** - Display all users with roles
2. **Create User** - Form to add new user
3. **Edit User** - Modify username, role, status
4. **Deactivate User** - Soft delete (preserve history)
5. **Role Permissions Matrix** - Visual RBAC configuration

**Example: Create New Manager User**

```
FORM: Create User
─────────────────────────────────
Username:      [arjun123     ]
Display Name:  [Arjun Sharma ]
Password:      [••••••••••  ]
Role:          [▼ Manager   ]
Active:        [☑ Yes       ]

[CREATE] [CANCEL]
```

**Backend Process:**
```
POST /api/users
├─ Verify JWT token & Extract admin roleId
├─ Validate username (unique)
├─ Validate password strength
├─ Hash password with Argon2
├─ INSERT INTO app_user (username, display_name, password_hash, role_id, is_active)
└─ Return created user (without password)
```

---

### Step 4: Viewing Transactions (Financial Records)

**URL:** `http://localhost:3001/transactions`

**Module ID:** `transactions`

**Visual List:**
```
┌──────────────────────────────────────────────────────────────┐
│  TRANSACTIONS LIST                                            │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Filter: [Date Range ▼] [Type ▼] [Status ▼] [ SEARCH ]      │
│                                                               │
│  ID    │ Date      │ Type         │ Amount    │ Status │ Act │
│  ──────┼───────────┼──────────────┼───────────┼────────┼─────│
│  T-001 │ 2026-08-22│ Material Puch│ $2,500.00 │ Posted │ [⋯] │
│  T-002 │ 2026-08-22│ Labor Expens │ $1,200.00 │ Posted │ [⋯] │
│  T-003 │ 2026-08-21│ Utilities    │ $450.00   │ Posted │ [⋯] │
│  T-004 │ 2026-08-21│ Sales Revenue│ $8,500.00 │ Posted │ [⋯] │
│  T-005 │ 2026-08-20│ Maintenance  │ $300.00   │ Draft  │ [⋯] │
│  ...                                                          │
│                                                               │
│  [ + NEW TRANSACTION ]  [ EXPORT ]                           │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

**Edit Transaction Flow:**
1. Admin clicks on transaction row or [⋯] menu
2. System loads transaction details in a form
3. Admin can modify amounts, categories, dates
4. Save triggers validation & audit log entry
5. System updates database & invalidates dashboard cache

---

### Step 5: Production Analytics (Manager/Admin View)

**URL:** `http://localhost:3001/daily-production`

**Module ID:** `dailyProduction`

**Visual Overview:**
```
┌──────────────────────────────────────────────────────────────┐
│  DAILY PRODUCTION TRACKING                                    │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  📈 PRODUCTION ANALYTICS TAB                                  │
│  ═════════════════════════════════════════════════════════════│
│                                                               │
│  This Month (August 2026): 4,250 units                        │
│  Target: 6,000 units                                          │
│  Variance: -29% (Behind Schedule)                             │
│                                                               │
│  ┌──────────────────────────────────────────────┐            │
│  │ Production by Machine                        │            │
│  │                                              │            │
│  │ Loom A1: ████████████ 1,200 units (28%)     │            │
│  │ Loom A2: ██████████ 950 units (22%)         │            │
│  │ Loom B1: ███████████ 1,100 units (26%)      │            │
│  │ Loom B2: ████████ 750 units (18%)           │            │
│  │ Loom C1: ████ 250 units (6%)                │            │
│  └──────────────────────────────────────────────┘            │
│                                                               │
│  ┌──────────────────────────────────────────────┐            │
│  │ Daily Production Trend                       │            │
│  │                                              │            │
│  │ 250 │     ╱╲                                 │            │
│  │ 200 │    ╱  ╲      ╱╲                        │            │
│  │ 150 │   ╱    ╲╱╲  ╱  ╲                       │            │
│  │ 100 │  ╱        ╲╱    ╲                      │            │
│  │  50 │                   ╲                    │            │
│  │   0 └─────────────────────────────           │            │
│  │     M  T  W  T  F  S  S  M  T  W  T  F  S  S │            │
│  └──────────────────────────────────────────────┘            │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

### Step 6: Maintenance Management

**URL:** `http://localhost:3001/maintenance/machine`

**Visual Screen:**
```
┌──────────────────────────────────────────────────────────────┐
│  MACHINE MAINTENANCE                                          │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  SCHEDULED MAINTENANCE                                       │
│  ═════════════════════════════════════════════════════════════│
│                                                               │
│  ID  │ Machine │ Type       │ Date Due  │ Status     │ Action │
│  ────┼─────────┼────────────┼───────────┼────────────┼───────│
│  M-1 │ Loom A1 │ Oil Change │ 2026-08-25│ Scheduled  │  [+]  │
│  M-2 │ Loom B2 │ Belt Check │ 2026-08-22│ Overdue!   │  [🔴] │
│  M-3 │ Loom C1 │ Inspection │ 2026-08-30│ Scheduled  │  [+]  │
│  M-4 │ Loom A2 │ Repair     │ 2026-08-23│ In Progress│  [⏳] │
│                                                               │
│  [ + NEW MAINTENANCE RECORD ]                                │
│                                                               │
│  FACTORY MAINTENANCE                                         │
│  ═════════════════════════════════════════════════════════════│
│                                                               │
│  • Cleaning schedule (Daily 6 AM)                            │
│  • Electrical inspection (Monthly)                           │
│  • HVAC maintenance (Quarterly)                              │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

### Step 7: Reporting & Logout

**URL:** `http://localhost:3001/reports`

**Module ID:** `reports`

**Visual Options:**
```
┌──────────────────────────────────────────────────────────────┐
│  REPORTS & ANALYTICS                                          │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  1. YARN BALANCE REPORT                                      │
│     ├─ Current Inventory: 5,200 kg                           │
│     ├─ Received This Month: 2,100 kg                         │
│     ├─ Used This Month: 1,800 kg                             │
│     └─ [ DOWNLOAD PDF ]                                      │
│                                                               │
│  2. YARN-TO-FABRIC CONVERSION                                │
│     ├─ Input Yarn: 1,800 kg                                  │
│     ├─ Output Fabric: 4,250 meters                           │
│     ├─ Conversion Rate: 42.5%                                │
│     └─ [ DOWNLOAD CSV ]                                      │
│                                                               │
│  3. PRODUCTION SUMMARY                                       │
│     ├─ Daily Average: 156 units                              │
│     ├─ Monthly Total: 4,250 units                            │
│     ├─ YTD Total: 18,500 units                               │
│     └─ [ VIEW CHART ]                                        │
│                                                               │
│  4. FINANCIAL SUMMARY                                        │
│     ├─ Revenue: $125,000                                     │
│     ├─ Expenses: $82,000                                     │
│     ├─ Net Profit: $43,000                                   │
│     └─ [ DOWNLOAD REPORT ]                                   │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

**Logout:**
```
USER MENU
─────────────
👤 admin
├─ My Profile
├─ Settings
└─ [ LOGOUT ]

→ Click LOGOUT
  ├─ Clear JWT from localStorage
  ├─ Redirect to /login
  └─ Session ends
```

---

## Journey 2: Manager Walkthrough

### Story: "Khurram - Operations Manager"

**Role:** Manager  
**Credentials:** `manager` / `manager123#`  
**Scenario:** Khurram oversees daily operations, reviews payroll, approves transactions, and tracks production.

---

### Step 1: Login & Dashboard

**Authentication:** Same flow as Admin (username/password JWT auth)

**Dashboard (Manager View):**
```
┌──────────────────────────────────────────────────────────────┐
│  TKT TEXTILES DASHBOARD                     👤 manager       │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  [ Dashboard | Transactions | Production | Yarn | Delivery ] │
│  [ Payroll | Reports | Maintenance ]                         │
│                                                               │
│  NOTE: No Settings tab (RBAC enforced - users module denied) │
│                                                               │
│  ┌─────────────────────┐  ┌──────────────────┐              │
│  │ TODAY'S PRODUCTION  │  │ PENDING APPROVALS│              │
│  │ ═══════════════════ │  │ ════════════════ │              │
│  │ Target: 200 units   │  │ • 3 Transactions │              │
│  │ Current: 142 units  │  │ • 2 Salary Entries│              │
│  │ Progress: 71%       │  │ • 1 Advance Req  │              │
│  └─────────────────────┘  └──────────────────┘              │
│                                                               │
│  MACHINE STATUS                                              │
│  • Loom A1: Running (98% uptime)                             │
│  • Loom B3: Maintenance (Scheduled Oil Change)               │
│  • Loom C2: Running (95% uptime)                             │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

**Key Differences from Admin:**
- ✗ No Settings/Users management link
- ✓ Pending approvals widget (transactions, payroll)
- ✓ Focus on operational metrics

---

### Step 2: Transactions Approval Workflow

**URL:** `http://localhost:3001/transactions`

**Create New Transaction:**

```
FORM: NEW TRANSACTION
─────────────────────────────────────
Date:          [2026-08-22         ]
Type:          [▼ Material Purchase]
Category:      [▼ Raw Materials    ]
Description:   [Yarn bulk order from supplier X]
Amount:        [$3,200.00          ]
Reference:     [INV-2026-0845      ]

Payment Method: [▼ Bank Transfer   ]
Account:       [▼ Main Account     ]

Status:        [Draft          ▼]  ← Manager creates as "Draft"
Approver:      [Admin (Auto)   ]   ← Routes to Admin

[SAVE AS DRAFT] [SUBMIT FOR APPROVAL]
```

**Save and Submit Flow:**
1. Manager completes form and clicks "SUBMIT FOR APPROVAL"
2. Transaction status changes to "Pending Admin Review"
3. Database INSERT: `INSERT INTO transaction VALUES (..., status='pending')`
4. Audit log created: `INSERT INTO audit_log (action, user_id, transaction_id, timestamp)`
5. Admin receives notification (in dashboard widget)
6. Admin reviews and approves/rejects
7. If approved → status = "Posted", financial dashboard updates
8. If rejected → status = "Rejected", reason stored in notes

---

### Step 3: Payroll Management

**URL:** `http://localhost:3001/transactions/monthly-salary-entry`

**Module ID:** `payroll`

**Visual Screen:**
```
┌──────────────────────────────────────────────────────────────┐
│  MONTHLY SALARY ENTRY                                         │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Month: [August 2026 ▼]  [Payroll Summary]                   │
│                                                               │
│  SALARY ENTRIES                                              │
│  ═════════════════════════════════════════════════════════════│
│                                                               │
│  Employee │ Role      │ Base Salary │ Bonus │ Deductions │   │
│  ──────────┼───────────┼─────────────┼───────┼────────────│   │
│  K. Hassan │ Manager   │ $2,000.00   │ $200  │ $50        │ ✓ │
│  I. Ahmed  │ Supervisor│ $1,500.00   │ $100  │ $50        │ ✓ │
│  H. Imam   │ Operator  │ $1,200.00   │ $50   │ $30        │   │
│  M. Khan   │ Operator  │ $1,200.00   │ $50   │ $30        │   │
│  A. Sharma │ Operator  │ $1,200.00   │ $0    │ $30        │   │
│                                                               │
│  TOTAL PAYROLL: $7,350.00                                    │
│  Monthly Budget: $8,000.00                                   │
│  Variance: -$650.00 (Under Budget ✓)                         │
│                                                               │
│  [GENERATE PAYROLL] [SUBMIT FOR APPROVAL] [EXPORT SLIPS]    │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

**Salary Entry Process:**
1. Manager views monthly salary entry page
2. System loads all active employees with base salary from masters
3. Manager can:
   - Add bonuses per employee
   - Add/modify deductions (taxes, insurance, loans)
   - Add notes
4. Click "GENERATE PAYROLL" → creates transaction records
5. Submit for Admin approval
6. Once approved, export salary slips (PDF)

---

### Step 4: Yarn Receipts & Daily Deliveries

**URL:** `http://localhost:3001/yarn-receipts`

**Add Yarn Receipt Form:**
```
FORM: NEW YARN RECEIPT
──────────────────────────────────────────
Receipt Date:    [2026-08-22        ]
Supplier:        [▼ Textile Mills Inc]
Receipt ID:      [REC-2026-0451     ]

Yarn Details:
  Type:          [▼ Cotton          ]
  Grade:         [▼ Premium         ]
  Quantity (kg): [2,500             ]
  Rate/kg:       [$0.85             ]
  Total Amount:  [$2,125.00         ]

Quality Check:
  Visual Inspection: [✓ Passed       ]
  Weight Variance:   [±0.2% (OK)    ]
  Color Uniformity:  [✓ Passed       ]

Notes: [Lorem ipsum dolor...        ]

[SAVE & RECORD] [SAVE & PRINT]
```

**Analytics Tab for Yarn Receipts:**
```
YARN RECEIPTS ANALYTICS
──────────────────────────────
Month: August 2026

Total Received: 8,500 kg
From Suppliers: 5 vendors
Average Cost: $0.82/kg
Quality Pass Rate: 99.2%

Top Suppliers:
1. Textile Mills Inc: 3,200 kg
2. Global Yarns: 2,800 kg
3. Premium Fibers: 1,800 kg
4. Standard Supply: 700 kg
```

**Daily Deliveries (Similar Interface):**
```
URL: /daily-deliveries

DAILY DELIVERIES TRACKING
──────────────────────────────
Today: 2026-08-22

Planned Deliveries: 12
Completed: 9
In Progress: 2
Delayed: 1

Delivery Log:
├─ Order #D-001: Delivered 08:30
├─ Order #D-002: Delivered 09:15
├─ Order #D-003: In Transit (ETA 10:30)
├─ Order #D-004: Delayed (waiting for QC)
└─ ...

[ADD DELIVERY] [PRINT MANIFEST]
```

---

### Step 5: Reports & Insights

**URL:** `http://localhost:3001/reports/yarn-balance`

**Yarn Balance Report:**
```
YARN BALANCE REPORT
═════════════════════════════════════════
Report Date: August 22, 2026

INVENTORY SUMMARY
─────────────────
Opening Balance: 5,800 kg
+ Receipts This Month: 8,500 kg
- Usage This Month: 7,800 kg
= Closing Balance: 6,500 kg

VARIANCE ANALYSIS
─────────────────
Expected: 6,200 kg
Actual: 6,500 kg
Variance: +300 kg (+4.8%) ← Better than expected!

YARN-TO-FABRIC CONVERSION (Detailed)
─────────────────────────────────
Input Yarn: 7,800 kg
Output Fabric: 18,750 meters
Conversion Rate: 2.4 meters per kg
Efficiency: 98.5% (vs. target 100%)

SUPPLIER PERFORMANCE
─────────────────────
Textile Mills Inc: 98% on-time delivery
Global Yarns: 95% on-time delivery
Premium Fibers: 100% on-time delivery

[EXPORT PDF] [EMAIL REPORT] [PRINT]
```

---

### Step 6: Advances & Loan Management

**URL:** `http://localhost:3001/transactions/advances`

**Advances List:**
```
ADVANCES MANAGEMENT
═════════════════════════════════════════

Active Advances:
┌──────────────────────────────────────┐
│ Employee │ Amount │ Start │ Status   │
│──────────┼────────┼───────┼──────────│
│ K. Hassan│ $200   │ 08-15 │ Active   │
│ I. Ahmed │ $150   │ 08-10 │ Active   │
│ A. Sharma│ $100   │ 08-01 │ Repaid   │
└──────────────────────────────────────┘

New Advance Request:
┌──────────────────────────────────────┐
│ Employee:  [▼ Select Employee     ]  │
│ Amount:    [$              ]        │
│ Duration:  [▼ 1 month           ]  │
│ Reason:    [Personal Emergency   ]  │
│ [REQUEST]  [CANCEL]                 │
└──────────────────────────────────────┘

Manager submits → Admin approves → Deducted from next salary
```

---

### Step 7: Logout

```
USER MENU
─────────────
👤 manager
├─ My Profile
├─ [ LOGOUT ]

→ Clear token, redirect to /login
```

---

## Journey 3: Supervisor Walkthrough

### Story: "Iftikhar - Production Supervisor"

**Role:** Supervisor  
**Credentials:** `supervisor` / `supervisor123#`  
**Scenario:** Amit records daily production, manages yarn receipts, tracks deliveries, and logs maintenance issues.

---

### Step 1: Login & Dashboard (Supervisor View)

**Restricted Features (Not Visible):**
- ✗ Transactions (financial records)
- ✗ Payroll
- ✗ Reports
- ✗ Settings

**Available Features:**
- ✓ Dashboard (read-only metrics)
- ✓ Daily Production (create/edit records)
- ✓ Yarn Receipts (create/view)
- ✓ Daily Deliveries (create/view)
- ✓ Maintenance (create/view)

**Dashboard (Supervisor View):**
```
┌──────────────────────────────────────────────────────────────┐
│  PRODUCTION DASHBOARD                   👤 supervisor        │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  [ Dashboard | Production | Yarn | Delivery | Maintenance ]  │
│                                                               │
│  NOTE: No Transactions, Payroll, Reports, Settings tabs      │
│                                                               │
│  TODAY'S TARGET: 200 UNITS                                   │
│  ╔═════════════════════════════════════╗                     │
│  ║ Current Production: 142 units  71%  ║ ← Live Progress Bar │
│  ╚═════════════════════════════════════╝                     │
│                                                               │
│  ACTIVE MACHINES                                             │
│  ┌─────────────────────────────────────┐                     │
│  │ Loom A1: Running (142 units today)  │ ✓ On Target        │
│  │ Loom A2: Running (95 units today)   │ ⚠ Slightly behind  │
│  │ Loom B3: Maintenance (Oil Change)   │ ⏸ Scheduled        │
│  │ Loom C2: Running (78 units today)   │ ✓ On Track         │
│  └─────────────────────────────────────┘                     │
│                                                               │
│  SHIFT INFORMATION                                           │
│  └─ Shift 1: 08:00-16:00 (In Progress)                       │
│     Supervisor: Iftikhar                                   │
│     Team Size: 8 workers                                     │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

### Step 2: Daily Production Recording

**URL:** `http://localhost:3001/daily-production`

**Module ID:** `dailyProduction`

**Add Production Record:**
```
FORM: RECORD DAILY PRODUCTION
──────────────────────────────────────────
Date:         [2026-08-22     ]
Shift:        [▼ Shift 1 (08:00-16:00)]
Machine:      [▼ Loom A1      ]
Operator:     [▼ Iftikhar   ]

Production Data:
  Units Produced: [142         ]
  Start Time:     [08:00       ]
  End Time:       [16:00       ]
  Break Time:     [01:00 (lunch)]
  Effective Hours: [7.0        ]
  Efficiency:     [98.5%       ]

Yarn Used:
  Type:    [▼ Cotton Premium]
  Qty (kg):[35.5           ]

Quality Issues:
  Defects Noted:  [None        ]
  Re-works:       [0 units     ]
  Inspector Sign: [____________]

[SAVE & NEXT] [SAVE & CLOSE]
```

**Backend Process:**
```
POST /api/daily-production
├─ Validate supervisor role (moduleId: dailyProduction)
├─ Validate machine exists & is active
├─ Validate date is today or past (no future entries)
├─ Validate production units > 0
├─ INSERT INTO daily_production (date, machine_id, units, efficiency, ...)
├─ UPDATE machines.total_units_produced += units
├─ Update yarn_inventory (deduct used quantity)
├─ Return created record
└─ Dashboard cache invalidates → refreshes
```

**Supervisor Can Edit Previous Entries:**
1. Click on production row from table
2. Modify units, efficiency, notes
3. Save → Audit log entry created
4. Manager/Admin can see edit history

---

### Step 3: Yarn Receipt Recording

**URL:** `http://localhost:3001/yarn-receipts`

**Simple Form (Supervisor):**
```
QUICK YARN RECEIPT
──────────────────────────────────────────
Date:       [2026-08-22     ]
Supplier:   [▼ Textile Mills]
Yarn Type:  [▼ Cotton       ]
Quantity:   [2,500 kg       ]

Quality Check (Visual):
  ☑ No visible defects
  ☑ Color uniform
  ☑ Weight acceptable

Receiving Person: [Iftikhar     ]
Time:            [10:30 AM       ]

[RECORD & CONFIRM]
```

**After Recording:**
- System creates receipt record (status: "Received")
- Supervisor can print receipt label for warehouse
- Amount is left blank (Manager/Admin finalizes pricing)
- Inventory updated immediately
- Report visible in analytics

---

### Step 4: Daily Delivery Tracking

**URL:** `http://localhost:3001/daily-deliveries`

**Add Delivery:**
```
FORM: RECORD DELIVERY
────────────────────────────────────
Date:       [2026-08-22         ]
Order ID:   [ORD-2026-1234      ]
Destination:[Customer Name/Ref  ]

Fabric Details:
  Type:     [▼ Cotton Twill    ]
  Quantity: [500 meters        ]
  Grade:    [▼ Premium         ]

Delivery Mode:  [▼ Truck        ]
Vehicle:       [▼ Truck-01      ]
Driver:        [▼ Rajesh Singh  ]

QC Sign-off:   [Supervisor: Iftikhar]

Status:  [☑ Ready for Dispatch]

[RECORD DELIVERY] [PRINT MANIFEST]
```

**Analytics View (Supervisor):**
```
DAILY DELIVERY SUMMARY
──────────────────────────────
Today (2026-08-22)

Planned: 12 deliveries
Completed: 9
In Progress: 2
Delayed: 1

Delivered Quantity: 4,500 meters
Remaining: 2,300 meters

[View Details] [Print Summary]
```

---

### Step 5: Maintenance Request Logging

**URL:** `http://localhost:3001/maintenance/machine`

**Report Machine Issue:**
```
FORM: REPORT MAINTENANCE ISSUE
──────────────────────────────────────────
Date:       [2026-08-22         ]
Time:       [14:30              ]
Machine:    [▼ Loom B2          ]

Issue Type: [▼ Belt Worn        ]
Severity:   [⭕ High / ⭕ Medium / ⭕ Low]
  Selected: High

Description:
  Belt showing signs of wear, causing slight vibration.
  Recommending replacement before next shift.
  [                              ]
  [                              ]

Photos:     [ + UPLOAD IMAGE ]

Reporter:   [Iftikhar         ]

[SUBMIT] [SAVE AS DRAFT]
```

**After Submission:**
- Status: "Reported by Supervisor"
- Visible to Managers & Admins
- Manager reviews and schedules maintenance
- Supervisor can track status

---

### Step 6: Attendance Tracking (Bonus)

**URL:** `http://localhost:3001/attendance`

**Module ID:** `dailyProduction` (grouped with production)

**Mark Attendance:**
```
ATTENDANCE SHEET - August 22, 2026 (Shift 1)
────────────────────────────────────────────
Supervisor: Iftikhar

Employee       │ Status    │ Time In │ Time Out │ Hours │ Notes
───────────────┼───────────┼─────────┼──────────┼───────┼──────
K. Singh       │ ✓ Present │ 08:00   │ 16:00    │ 8.0   │ —
R. Patel       │ ✓ Present │ 08:00   │ 16:00    │ 8.0   │ —
M. Khan        │ ⚠ Late    │ 08:20   │ 16:00    │ 7.75  │ Traffic
A. Sharma      │ ✓ Present │ 08:00   │ 16:00    │ 8.0   │ —
S. Verma       │ ⛔ Absent  │ —       │ —        │ —     │ Sick leave
J. Das         │ ✓ Present │ 08:00   │ 16:00    │ 8.0   │ —
L. Singh       │ ⚠ Early   │ 08:00   │ 15:30    │ 7.5   │ Doctor appt
P. Kumar       │ ✓ Present │ 08:00   │ 16:00    │ 8.0   │ —

[CONFIRM & SAVE] [PRINT SHEET]
```

---

### Step 7: View-Only Access to Higher-Level Data

**Supervisor Cannot Access But Can Request:**
- ✗ Cannot view Transactions or Payroll
- ✗ Cannot view Financial Reports
- ✗ Cannot modify user permissions

**But can request approval from Manager:**
```
CONTEXT MENU
──────────────────
• View My Profile
• Request Financial Info (if needed)
• Message Manager
• Attendance Summary (for self)
• [ LOGOUT ]
```

---

### Step 8: Logout

Same as other roles:
```
USER MENU → [ LOGOUT ]
├─ Clear JWT token
├─ Redirect to /login
└─ Session ends
```

---

## Core Features Breakdown

### 1. Authentication & Authorization

**Flow Chart:**
```
User visits /login
    ↓
Enter credentials
    ↓
POST /api/auth/login
    ↓
Backend validates
    ├─ Query user by username
    ├─ Verify password (argon2.verify)
    └─ If valid:
       ├─ Fetch user role
       ├─ Query role permissions
       ├─ Sign JWT (user ID + role + permissions)
       └─ Return token
    ├─ If invalid: Return 401
    ↓
Frontend stores JWT in localStorage
    ↓
Attach JWT to all API requests (Authorization header)
    ↓
Backend middleware validates JWT
    ├─ Decode JWT
    ├─ Verify signature
    ├─ Extract user ID + role + permissions
    └─ Attach to request context
    ↓
Per-route permission check: requirePermission(moduleId)
    ├─ If moduleId in user permissions: Allow
    └─ If not: Return 403 Forbidden
```

---

### 2. RBAC (Role-Based Access Control)

**Database Schema:**
```
┌─────────────────┐
│   role          │
├─────────────────┤
│ id (PK)         │
│ name (unique)   │ ← "Admin", "Manager", "Supervisor"
│ is_admin        │ ← Boolean flag for implicit all-access
│ created_at      │
└─────────────────┘

┌──────────────────────┐
│ role_permission      │
├──────────────────────┤
│ role_id (FK)         │ ← References role.id
│ module_id (PK, part) │ ← "dashboard", "transactions", etc.
└──────────────────────┘

┌─────────────────┐
│   app_user      │
├─────────────────┤
│ id (PK)         │
│ username        │
│ display_name    │
│ password_hash   │
│ role_id (FK)    │ ← References role.id
│ employee_id (FK)│ ← Optional link to HR data
│ is_active       │
│ created_at      │
│ updated_at      │
└─────────────────┘
```

**Permission Check Middleware:**
```typescript
// Backend middleware
const requirePermission = (moduleId: string) => {
  return async (req, res, next) => {
    const user = req.user; // From JWT decode
    
    // Admins bypass all checks
    if (user.roleData.isAdmin) return next();
    
    // Check if moduleId in user permissions
    const hasAccess = user.permissions.includes(moduleId);
    
    if (!hasAccess) {
      return res.status(403).json({
        error: "Access denied to module: " + moduleId
      });
    }
    
    next();
  };
};

// Route protection
router.get('/api/payroll', 
  authenticateJWT, 
  requirePermission('payroll'),
  getPayrollHandler
);
```

---

### 3. Data Validation & Audit

**Transaction Creation Validation:**
```
1. Extract request body
   └─ date, type, amount, description, etc.

2. Validate required fields
   └─ All fields present & non-empty?

3. Validate data types
   └─ amount is number > 0?
   └─ date is valid ISO string?

4. Validate business logic
   └─ Amount within reasonable range?
   └─ Transaction type exists in masters?
   └─ Category is valid?

5. Check permissions
   └─ User role has 'transactions' permission?

6. Insert into database with audit trail
   ├─ INSERT INTO transaction (...)
   └─ INSERT INTO audit_log (user_id, action, timestamp, record_id)

7. Invalidate cache & notify listeners
   ├─ Clear React Query cache (dashboard)
   └─ Return created record
```

**Audit Log Example:**
```sql
INSERT INTO audit_log (user_id, action, module_id, record_id, timestamp, details)
VALUES (
  2,                           -- manager user_id
  'CREATE_TRANSACTION',        -- action
  'transactions',              -- module
  'T-001',                     -- transaction ID
  NOW(),
  '{"amount": 3200, "type": "Material Purchase", "supplier": "Textile Mills"}'
);
```

---

### 4. Dashboard Data Aggregation

**API Response Structure:**
```json
{
  "summary": {
    "todayProduction": 142,
    "targetProduction": 200,
    "progressPercent": 71,
    "ytdProduction": 18500,
    "revenue": 125000,
    "expenses": 82000,
    "netProfit": 43000
  },
  "machines": [
    {
      "id": "loom_a1",
      "name": "Loom A1",
      "status": "running",
      "unitsToday": 142,
      "uptimePercent": 98.5
    }
  ],
  "pendingTasks": [
    {
      "id": "maint_1",
      "type": "Maintenance",
      "description": "Oil Change - Loom B2",
      "dueDate": "2026-08-22",
      "priority": "high"
    }
  ],
  "chartData": {
    "productionTrend": [
      {"date": "2026-08-01", "units": 180},
      ...
    ]
  }
}
```

---

## Data Flow Architecture

### Complete Transaction Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│                    USER INTERFACE (React)                   │
│                                                             │
│  Form: [Date] [Type] [Amount] [Description]                │
│  Button: [SUBMIT]                                           │
└────────────┬────────────────────────────────────────────────┘
             │ 1. User clicks SUBMIT
             │    Form validation (client-side)
             ↓
┌────────────────────────────────────────────────────────────┐
│              API CALL: POST /api/transactions               │
│  Headers: { Authorization: "Bearer <JWT>" }                │
│  Body: { date, type, amount, description, ... }            │
└────────────┬───────────────────────────────────────────────┘
             │ 2. HTTP Request sent over network
             ↓
┌────────────────────────────────────────────────────────────┐
│              BACKEND (Node.js + Express)                   │
│                                                             │
│  Route Handler: POST /api/transactions                     │
│  ├─ Parse request body                                     │
│  ├─ Extract JWT from Authorization header                  │
│  ├─ Verify JWT signature & decode                          │
│  └─ Attach user context to request                         │
└────────────┬───────────────────────────────────────────────┘
             │ 3. Middleware chain executes
             ↓
┌────────────────────────────────────────────────────────────┐
│              MIDDLEWARE: authenticateJWT                    │
│  ├─ Verify token is valid                                  │
│  ├─ Check token expiration                                 │
│  └─ Load user role & permissions from token                │
└────────────┬───────────────────────────────────────────────┘
             │ 4. Check permissions
             ↓
┌────────────────────────────────────────────────────────────┐
│           MIDDLEWARE: requirePermission('transactions')     │
│  ├─ Is user admin? → Allow                                 │
│  ├─ Check if 'transactions' in user.permissions            │
│  └─ If yes → next(); if no → 403 Forbidden                │
└────────────┬───────────────────────────────────────────────┘
             │ 5. Request reaches handler
             ↓
┌────────────────────────────────────────────────────────────┐
│            HANDLER: createTransactionHandler()             │
│  ├─ Extract & validate request body                        │
│  ├─ Check for required fields                              │
│  ├─ Validate data types & business rules                   │
│  └─ If validation fails → return 400 + error details       │
└────────────┬───────────────────────────────────────────────┘
             │ 6. Validation passed
             ↓
┌────────────────────────────────────────────────────────────┐
│                DATABASE OPERATIONS                         │
│                                                             │
│  INSERT transaction:                                       │
│  ├─ db.insert(transactionTable).values({                   │
│  │    date: req.body.date,                                 │
│  │    type: req.body.type,                                 │
│  │    amount: req.body.amount,                             │
│  │    status: 'pending',  ← Awaits approval                │
│  │    createdBy: req.user.id,                              │
│  │    createdAt: NOW()                                     │
│  │  })                                                      │
│  └─ Returns created record with auto-generated ID          │
│                                                             │
│  INSERT audit log:                                         │
│  ├─ db.insert(auditLogTable).values({                      │
│  │    userId: req.user.id,                                 │
│  │    action: 'CREATE_TRANSACTION',                        │
│  │    moduleId: 'transactions',                            │
│  │    recordId: transaction.id,                            │
│  │    timestamp: NOW(),                                    │
│  │    details: JSON.stringify(transaction)                 │
│  │  })                                                      │
│  └─ Creates audit trail for compliance                     │
└────────────┬───────────────────────────────────────────────┘
             │ 7. Database insert successful
             ↓
┌────────────────────────────────────────────────────────────┐
│            CACHE INVALIDATION & NOTIFICATIONS              │
│  ├─ Invalidate React Query cache key: "transactions"       │
│  ├─ Invalidate cache key: "dashboard"                      │
│  └─ Emit WebSocket event: "transaction:created"            │
│     (All connected clients receive real-time update)       │
└────────────┬───────────────────────────────────────────────┘
             │ 8. Response sent back
             ↓
┌────────────────────────────────────────────────────────────┐
│           RESPONSE: 201 Created                            │
│  {                                                          │
│    "id": "T-001",                                           │
│    "date": "2026-08-22",                                    │
│    "type": "Material Purchase",                            │
│    "amount": 3200,                                          │
│    "status": "pending",                                     │
│    "createdBy": "manager",                                  │
│    "createdAt": "2026-08-22T10:15:30Z"                     │
│  }                                                          │
└────────────┬───────────────────────────────────────────────┘
             │ 9. Frontend receives response
             ↓
┌────────────────────────────────────────────────────────────┐
│              FRONTEND: Handle Success                      │
│  ├─ Show success toast: "Transaction saved!"               │
│  ├─ Update local state                                     │
│  ├─ Redirect to list view or stay on form                  │
│  └─ Optionally invalidate React Query cache                │
└────────────┬───────────────────────────────────────────────┘
             │ 10. User sees updated UI
             ↓
┌────────────────────────────────────────────────────────────┐
│              ADMIN APPROVAL FLOW                           │
│  ├─ Admin logs in → dashboard widget shows                 │
│  │  "3 pending transactions for approval"                  │
│  ├─ Admin clicks "Transactions" → sees pending list        │
│  ├─ Admin clicks on transaction → review details           │
│  ├─ Admin clicks "APPROVE"                                 │
│  │  └─ POST /api/transactions/T-001/approve                │
│  │     └─ Updates status: 'pending' → 'posted'             │
│  │     └─ Audit log: "APPROVED_BY_ADMIN"                   │
│  │     └─ Invalidates all dashboards                       │
│  │     └─ Financial reports now include this transaction   │
│  └─ Transaction is now "Posted" and affects reports        │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Technical Components

### Frontend Stack
- **React 18** - UI library
- **Wouter** - Lightweight routing
- **React Query** - Server state management, caching
- **Shadcn UI** - Component library
- **Recharts** - Data visualization & charts
- **Zod** - Schema validation
- **TypeScript** - Type safety

### Backend Stack
- **Node.js 22** - Runtime
- **Express** - Web framework
- **Drizzle ORM** - Database abstraction & migrations
- **PostgreSQL 16** - Database
- **Argon2** - Password hashing
- **JWT (jsonwebtoken)** - Authentication
- **Pino** - Structured logging

### DevOps
- **Docker Compose** - Multi-service orchestration
- **PostgreSQL 16 Alpine** - Lightweight database
- **Vite** - Frontend build tool
- **npm** - Package management

---

## Security Layers

### 1. **Authentication**
- Username + password (Argon2 hashed)
- JWT tokens (signed with secret)
- Token expiration & refresh

### 2. **Authorization**
- Role-Based Access Control (RBAC)
- Per-route permission middleware
- Admin role flag for implicit all-access

### 3. **Data Validation**
- Zod schema validation (frontend & backend)
- Type checking with TypeScript
- SQL injection prevention via ORM

### 4. **Audit Trail**
- All create/update/delete operations logged
- User ID, timestamp, action, record ID captured
- Compliance & accountability

### 5. **Network Security**
- HTTPS ready (deployed with Nginx reverse proxy)
- CORS configured for allowed origins
- JWT in Authorization header (not cookies)

---

## Production Deployment Notes

When deploying to production:

1. **Environment Variables Required:**
   - `DATABASE_URL` - PostgreSQL connection string
   - `JWT_SECRET` - Strong random key (32+ chars)
   - `ALLOWED_ORIGINS` - CORS whitelist
   - `SEED_ADMIN_USERNAME` - Override default admin username
   - `SEED_ADMIN_PASSWORD` - Override default admin password

2. **Database Migrations:**
   - All schema changes via Drizzle migrations
   - Auto-run on backend startup
   - RBAC seed idempotent (safe to re-run)

3. **Logging & Monitoring:**
   - Pino structured logs (JSON format)
   - Collect via ELK or Splunk
   - Set log level to 'info' in production

4. **Performance:**
   - React Query caching (5-min stale time)
   - PostgreSQL connection pooling
   - Frontend lazy-loading (heavy components)
   - Nginx compression + caching headers

5. **Backup & Disaster Recovery:**
   - Daily PostgreSQL backups (pg_dump)
   - Test restore procedures monthly
   - Document runbooks for common incidents

---

## Conclusion

The TKT Textiles Knitting System provides a complete internal operations platform with:

✅ **Role-based access control** - Three distinct user tiers  
✅ **Production tracking** - Real-time machine & output monitoring  
✅ **Financial management** - Transactions, payroll, advances  
✅ **Inventory management** - Yarn receipts, deliveries, balance reports  
✅ **Audit trail** - All operations logged for compliance  
✅ **Responsive UI** - Works on desktop & tablet  
✅ **Type-safe codebase** - TypeScript throughout  
✅ **Production-ready** - Docker, PostgreSQL, scalable architecture  

**Total Modules:** 8 core features  
**Total Roles:** 3 (Admin, Manager, Supervisor)  
**Total Routes:** 20+ protected endpoints  
**Database Tables:** 50+ (including audit logs)  
**Lines of Code:** ~15,000+ (frontend + backend)

---

**Document Generated:** August 22, 2026  
**Last Updated:** —  
**Version:** 1.0 (Initial Release)

