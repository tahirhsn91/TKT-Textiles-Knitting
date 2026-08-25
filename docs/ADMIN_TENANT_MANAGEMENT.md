# Admin Tenant Management System

## Overview

Complete super-admin interface for managing all tenants in the SaaS platform. Super-admins can create new tenants, manage tenant configuration, switch between tenants, and assign/remove tenant admins.

## Features

### 1. Super-Admin Role
- New system-wide administrator role
- Access to all tenant management features
- Can create, update, and manage tenants
- Can switch between multiple tenants

### 2. Tenant Management API
All endpoints require `super-admin` role.

**List & Get Tenants:**
```
GET /api/admin/tenants                    # List all tenants (paginated)
GET /api/admin/tenants/:id                # Get specific tenant with configs
GET /api/admin/my-tenants                 # Get tenants managed by current admin
GET /api/admin/tenants/:id/stats          # Get tenant statistics
```

**Create & Update:**
```
POST /api/admin/tenants                   # Create new tenant with auto-seeding
PUT /api/admin/tenants/:id                # Update tenant info
PUT /api/admin/tenants/:id/status         # Update tenant status (active/suspended/inactive)
```

**Switch Tenant:**
```
POST /api/admin/switch-tenant/:id         # Switch tenant context (returns new JWT)
```

**Admin Management:**
```
GET /api/admin/tenants/:id/admins         # List admins for tenant
POST /api/admin/tenants/:id/assign-admin  # Assign admin to tenant
DELETE /api/admin/tenants/:id/admins/:userId # Remove admin from tenant
```

### 3. Tenant Switcher (Navbar)
**Location:** Top-right navbar, next to user profile  
**Visibility:** Super-admin only  
**Features:**
- Dropdown showing all managed tenants
- Shows tenant name, slug, and status badge
- Click to switch tenant context
- Current tenant has checkmark indicator
- Status indicators (green=active, yellow=suspended, gray=inactive)
- Mobile responsive
- Auto-reloads page on switch

### 4. Tenant Creation Flow
When super-admin creates new tenant via `POST /api/v1/admin/tenants`:

**Required Fields:**
- `name` - Tenant company name
- `slug` - URL-friendly identifier
- `industry` - Industry type
- `timezone` - Company timezone
- `currency` - Default currency (PKR, USD, etc.)
- `language` - Default language (ur, en, etc.)

**Auto-Seeded Configurations:**
1. **branding_config** - Default company branding
2. **tenant_settings** - Regional & business settings
3. **feature_flags** (10 defaults)
   - Core: invoicing, user_management, role_based_access, analytics
   - Enterprise: api_access, advanced_reporting, multi_warehouse, automated_workflows
   - Security: audit_logs, two_factor_auth
4. **theme_presets** (4 defaults)
   - Classic Blue, Modern Dark, Professional, Minimal Green
5. **session_settings** - Security policies
   - 30 min timeout, 5 max concurrent sessions, 2FA required for admins
6. **oauth_providers** (3 defaults, disabled)
   - Google, Microsoft, GitHub

### 5. Frontend Integration
**Tenant Switcher Component:**
```tsx
import TenantSwitcher from '@/components/TenantSwitcher';

// In navbar
<TenantSwitcher isSuperAdmin={userRole === 'super-admin'} />
```

**useAdmin Hook:**
```tsx
import { useAdmin } from '@/hooks/useAdmin';

const { 
  tenants, 
  createTenant, 
  switchTenant, 
  updateTenant 
} = useAdmin();

// Create new tenant
await createTenant({
  name: 'Acme Corp',
  slug: 'acme-corp',
  industry: 'Textile',
  timezone: 'Asia/Karachi',
  currency: 'PKR',
  language: 'ur'
});

// Switch tenant
const result = await switchTenant(tenantId);
// result.new_token is the JWT with new tenant_id
```

## Security

✅ **Role-Based Access Control**
- Super-admin middleware enforces authorization
- Only users with `super-admin` role can access admin endpoints
- Regular users cannot see any admin features

✅ **Token Refresh**
- Switching tenant issues new JWT with new tenant_id
- Old token becomes invalid for new tenant
- Prevents accidental cross-tenant data access

✅ **Tenant Isolation**
- All queries filtered by tenant_id
- Middleware validates tenant context on every request
- Admin can only operate within their assigned tenants

✅ **Audit Trail**
- Admin assignments tracked in `tenant_admin_assignments`
- Tenant creation logged with admin_user_id
- Status changes tracked with timestamps

## Backend Implementation

### AdminService
Complete service layer for tenant operations:
```typescript
// Create tenant with auto-seeding
const tenant = await adminService.createTenant(input, createdByAdminId);

// Get tenant details
const details = await adminService.getTenantDetails(tenantId);

// Update tenant
await adminService.updateTenant(tenantId, updates);

// Manage admins
await adminService.assignAdminToTenant(tenantId, adminUserId, assignedByAdminId);
await adminService.removeAdminFromTenant(tenantId, adminUserId);

// Get statistics
const stats = await adminService.getTenantStats(tenantId);
```

### SuperAdminMiddleware
Validates super-admin authorization:
```typescript
import { requireSuperAdmin } from '@/middleware/super-admin';

router.post('/admin/tenants', requireSuperAdmin, createTenant);
```

## Frontend Components

### TenantSwitcher Component
Rich dropdown for switching tenants:
- Shows all managed tenants
- Status badges (green/yellow/gray)
- Current tenant indicator (checkmark)
- Mobile responsive
- Auto-reload on switch

### Tenant Administration Menu
New menu option in account dropdown:
- Only visible to super-admins
- Links to `/admin/tenants`
- Managed via top-bar.tsx

## Usage Examples

### Creating a New Tenant
```bash
curl -X POST http://localhost:3000/api/admin/tenants \
  -H "Authorization: Bearer <super-admin-jwt>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Sunrise Textiles",
    "slug": "sunrise-textiles",
    "industry": "Textile & Knitting",
    "timezone": "Asia/Karachi",
    "currency": "PKR",
    "language": "ur"
  }'
```

### Switching Tenant Context
```bash
curl -X POST http://localhost:3000/api/admin/switch-tenant/2 \
  -H "Authorization: Bearer <super-admin-jwt>"
```
Response includes new JWT:
```json
{
  "message": "Switched to tenant: Sunrise Textiles",
  "tenant_id": 2,
  "tenant_name": "Sunrise Textiles",
  "new_token": "eyJhbGc..."
}
```

Store new token and use for subsequent requests.

## File Structure

```
backend/src/
├── services/
│   └── admin-service.ts (10.4KB)
├── middleware/
│   └── super-admin.ts (1.3KB)
└── routes/
    └── admin-routes.ts (8.4KB)

frontend/src/
├── hooks/
│   └── useAdmin.ts (5.6KB)
└── components/
    ├── TenantSwitcher.tsx (6.8KB)
    └── top-bar.tsx (updated)
```

## Testing

### Verify Super-Admin Functionality

1. **Assign super-admin role** to test user:
   ```sql
   UPDATE app_user SET role_id = (SELECT id FROM role WHERE name = 'super-admin')
   WHERE email = 'admin@example.com';
   ```

2. **Login** and verify:
   - Tenant Switcher appears in top-right navbar
   - "Tenant Administration" shows in account dropdown
   - Can create new tenants
   - Can switch between tenants
   - Token updates when switching

3. **Test creating tenant:**
   - Use UI or API
   - Verify auto-seeding (6 configurations created)
   - Verify tenant is immediately usable

4. **Test switching:**
   - Click tenant in switcher
   - Verify new JWT issued
   - Verify page reloads with new context
   - Verify data belongs to new tenant

## Troubleshooting

### Tenant Switcher Not Showing
- Verify user role is `super-admin`
- Check browser dev tools for errors
- Verify TenantSwitcher component is imported in top-bar.tsx

### Tenant Creation Fails
- Verify required fields (name, slug, industry, timezone, currency, language)
- Check JWT token is valid for super-admin
- Check database for duplicate slug

### Switch Tenant Returns Error
- Verify tenant exists
- Verify JWT token is fresh
- Check browser console for API errors

### Auto-Seeding Not Working
- Verify database tables exist (branding_config, feature_flags, etc.)
- Check migration 0026 applied successfully
- Review server logs for seed errors

## Related Documentation

- [Multi-Tenancy Architecture](./MULTI_TENANCY.md)
- [Configuration System](./CONFIGURATION_SYSTEM.md)
- [Authentication System](./AUTH_SYSTEM.md)
- [API Documentation](./API.md)
