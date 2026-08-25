# Authentication & Authorization Hardening System

## Overview

The Authentication & Authorization Hardening system provides enterprise-grade security features including user invitations, advanced session management, two-factor authentication, brute-force protection, and SSO-readiness.

## Database Schema

### user_invitations
User invitation management for team onboarding.

```sql
CREATE TABLE user_invitations (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER,
  invited_by INTEGER,           -- Admin who sent invitation
  email VARCHAR(255),
  role_name VARCHAR(100),
  invitation_code VARCHAR(255),
  invitation_token VARCHAR(500), -- JWT token for email link
  status VARCHAR(50),            -- pending, accepted, expired, cancelled
  accepted_at TIMESTAMP,
  expired_at TIMESTAMP,
  accepted_by_user_id INTEGER,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### user_sessions
Session management with device tracking.

```sql
CREATE TABLE user_sessions (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER,
  user_id INTEGER,
  session_token VARCHAR(500),
  refresh_token VARCHAR(500),
  device_name VARCHAR(255),
  device_type VARCHAR(50),       -- 'web', 'mobile', 'desktop'
  ip_address VARCHAR(45),
  user_agent TEXT,
  is_active BOOLEAN,
  last_activity_at TIMESTAMP,
  expires_at TIMESTAMP,
  two_factor_verified BOOLEAN,
  verified_at TIMESTAMP,
  created_at TIMESTAMP
);
```

### two_factor_auth
Two-factor authentication configuration per user.

```sql
CREATE TABLE two_factor_auth (
  id SERIAL PRIMARY KEY,
  user_id INTEGER UNIQUE,
  is_enabled BOOLEAN DEFAULT FALSE,
  is_verified BOOLEAN DEFAULT FALSE,
  totp_secret VARCHAR(255),      -- Google Authenticator secret
  phone_number VARCHAR(20),
  sms_enabled BOOLEAN,
  email_enabled BOOLEAN,
  recovery_codes_generated_at TIMESTAMP,
  recovery_codes_used_count INTEGER,
  last_verified_at TIMESTAMP,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### login_attempts
Brute-force attack detection and prevention.

```sql
CREATE TABLE login_attempts (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER,
  email VARCHAR(255),
  ip_address VARCHAR(45),
  attempt_count INTEGER,
  status VARCHAR(50),            -- 'success', 'failed'
  failure_reason VARCHAR(255),
  is_locked BOOLEAN,
  locked_until TIMESTAMP,        -- Lockout expiration
  lockout_reason VARCHAR(255),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### password_reset_tokens
Secure password reset with expiration.

```sql
CREATE TABLE password_reset_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER,
  reset_token VARCHAR(500) UNIQUE,
  email VARCHAR(255),
  is_used BOOLEAN DEFAULT FALSE,
  used_at TIMESTAMP,
  expires_at TIMESTAMP,          -- 1 hour default
  ip_address VARCHAR(45),
  created_at TIMESTAMP
);
```

### oauth_providers
OAuth2/SAML configuration for SSO.

```sql
CREATE TABLE oauth_providers (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER,
  provider_name VARCHAR(100),    -- 'google', 'microsoft', 'github'
  provider_type VARCHAR(50),     -- 'oauth2', 'saml'
  client_id VARCHAR(255),
  client_secret VARCHAR(255),
  redirect_uri VARCHAR(500),
  scope VARCHAR(500),
  is_enabled BOOLEAN DEFAULT FALSE,
  is_configured BOOLEAN DEFAULT FALSE,
  config_json JSONB,
  created_at TIMESTAMP
);
```

### user_oauth_accounts
Linked OAuth accounts per user.

```sql
CREATE TABLE user_oauth_accounts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER,
  provider_name VARCHAR(100),
  provider_user_id VARCHAR(255),
  access_token VARCHAR(500),
  refresh_token VARCHAR(500),
  token_expires_at TIMESTAMP,
  linked_at TIMESTAMP
);
```

### auth_audit
Complete authentication event tracking.

```sql
CREATE TABLE auth_audit (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER,
  user_id INTEGER,
  email VARCHAR(255),
  event_type VARCHAR(50),        -- 'login', 'logout', '2fa_setup', 'invite_sent'
  event_description VARCHAR(500),
  status VARCHAR(50),            -- 'success', 'failed'
  ip_address VARCHAR(45),
  user_agent TEXT,
  device_fingerprint VARCHAR(255),
  location_info VARCHAR(255),
  risk_level VARCHAR(50),        -- 'low', 'medium', 'high'
  suspicious_activity BOOLEAN,
  created_at TIMESTAMP
);
```

### session_settings
Tenant-specific session policies.

```sql
CREATE TABLE session_settings (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER UNIQUE,
  session_timeout_minutes INTEGER DEFAULT 30,
  remember_me_enabled BOOLEAN DEFAULT TRUE,
  remember_me_duration_days INTEGER DEFAULT 30,
  max_concurrent_sessions INTEGER DEFAULT 5,
  force_password_change_days INTEGER DEFAULT 90,
  password_expiry_enabled BOOLEAN DEFAULT FALSE,
  two_factor_required_for_admins BOOLEAN DEFAULT TRUE,
  two_factor_optional_for_users BOOLEAN DEFAULT FALSE,
  device_management_enabled BOOLEAN DEFAULT TRUE,
  max_devices_per_user INTEGER DEFAULT 5,
  ip_whitelist_enabled BOOLEAN DEFAULT FALSE,
  ip_whitelist VARCHAR(1000),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

## Backend Services

### AuthService (`services/auth-service.ts`)

```typescript
// User Invitations
const invitation = await authService.createUserInvitation(
  tenantId, 
  invitedByUserId, 
  'user@example.com', 
  'operator'
);
// Returns: { id, email, status, invitation_token, expired_at }

const pendingInvites = await authService.getPendingInvitations(tenantId);
await authService.resendInvitation(invitationId);
await authService.acceptInvitation(invitationId, userId);

// Session Management
const session = await authService.createSession(tenantId, userId, ipAddress, userAgent, 'Chrome Desktop');
const session = await authService.getSessionByToken(token);
await authService.updateSessionActivity(sessionId);
await authService.endSession(sessionId);
const sessions = await authService.getUserSessions(userId, onlyActive=true);
await authService.endAllUserSessions(userId);

// Two-Factor Authentication
const twoFa = await authService.setupTwoFactorAuth(tenantId, userId, 'totp');
await authService.enableTwoFactorAuth(userId);
await authService.disableTwoFactorAuth(userId);
const status = await authService.getTwoFactorAuth(userId);

// Login Security
await authService.recordLoginAttempt(tenantId, email, ipAddress, 'success');
const isLocked = await authService.isUserLockedOut(tenantId, email, ipAddress);
await authService.lockUserAccount(tenantId, email, ipAddress);

// Password Reset
const resetToken = await authService.createPasswordResetToken(tenantId, userId, email, ipAddress);
const token = await authService.verifyPasswordResetToken(token);
await authService.markResetTokenUsed(tokenId);

// Audit Trail
await authService.recordAuthAudit(tenantId, userId, email, 'login', 'success', ip, userAgent);
const audit = await authService.getAuthAudit(tenantId, { limit: 100, offset: 0 });

// Session Settings
const settings = await authService.getSessionSettings(tenantId);
await authService.updateSessionSettings(tenantId, { session_timeout_minutes: 20 });

// OAuth/SSO
const providers = await authService.getOAuthProviders(tenantId);
await authService.configureOAuthProvider(tenantId, 'google', config);
await authService.enableOAuthProvider(tenantId, 'google', true);
```

## API Endpoints

### User Invitations

**POST /api/v1/auth/invitations**
- Create user invitation
- Body: `{ email: string, role_name?: string }`
- Returns: `{ invitation_token, invitation_link }`

**GET /api/v1/auth/invitations**
- Get pending invitations (admin only)
- Returns: Array of pending invitations

**POST /api/v1/auth/invitations/:id/resend**
- Resend invitation email
- Returns: Updated invitation

**POST /api/v1/auth/invitations/accept** (public)
- Accept invitation and create user
- Body: `{ token: string, user_id: number }`
- Returns: Accepted invitation

### Session Management

**GET /api/v1/auth/sessions**
- List all active sessions for current user
- Returns: Array of sessions with device info

**DELETE /api/v1/auth/sessions/:sessionId**
- End specific session
- Returns: Success message

**POST /api/v1/auth/sessions/logout-all**
- End all sessions (logout all devices)
- Returns: Success message

### Two-Factor Authentication

**POST /api/v1/auth/2fa/setup**
- Initialize 2FA setup
- Body: `{ method: 'totp' | 'sms' | 'email' }`
- Returns: `{ totp_secret, methods }`

**POST /api/v1/auth/2fa/enable**
- Enable 2FA for user
- Returns: Success message

**POST /api/v1/auth/2fa/disable**
- Disable 2FA for user
- Returns: Success message

**GET /api/v1/auth/2fa/status**
- Get 2FA status
- Returns: `{ is_enabled, is_verified, methods }`

### Audit & Settings

**GET /api/v1/auth/audit**
- Get authentication audit trail
- Query params: `limit`, `offset`
- Returns: Array of audit events

**GET /api/v1/auth/session-settings**
- Get session policy for tenant
- Returns: SessionSettings object

**PUT /api/v1/auth/session-settings**
- Update session policy
- Body: Partial SessionSettings
- Returns: Updated settings

### OAuth/SSO

**GET /api/v1/auth/oauth-providers**
- List configured OAuth providers
- Returns: Array of providers

**POST /api/v1/auth/oauth-providers/:providerName/configure**
- Configure OAuth provider
- Body: `{ client_id, client_secret, redirect_uri, scope }`
- Returns: Provider configuration

**POST /api/v1/auth/oauth-providers/:providerName/enable**
- Enable/disable OAuth provider
- Body: `{ is_enabled: boolean }`
- Returns: Updated provider

## Frontend Integration

### useAuth Hook

```typescript
import { useAuth } from '@/hooks/useAuth';

function TeamManagement() {
  const { 
    invitations,
    sessions,
    twoFactorStatus,
    sessionSettings,
    loading,
    error,
    createInvitation,
    endSession,
    logoutAllDevices,
    enableTwoFactorAuth
  } = useAuth();

  // Invite team member
  const handleInvite = async (email: string) => {
    await createInvitation(email, 'operator');
  };

  // List active sessions
  return (
    <div>
      <h2>Active Sessions ({sessions.length})</h2>
      {sessions.map(session => (
        <div key={session.id}>
          <p>{session.device_name} - {session.ip_address}</p>
          <button onClick={() => endSession(session.id)}>End Session</button>
        </div>
      ))}

      <button onClick={logoutAllDevices}>Logout All Devices</button>

      {!twoFactorStatus?.is_enabled && (
        <button onClick={enableTwoFactorAuth}>Enable 2FA</button>
      )}
    </div>
  );
}
```

## User Invitation Flow

1. **Admin invites user**
   ```typescript
   const invite = await createInvitation('newuser@example.com', 'operator');
   // Email sent with link: /accept-invitation?token={token}
   ```

2. **User receives email** with invitation link

3. **User clicks link** and signs up
   ```typescript
   await acceptInvitation(token, newUserId);
   ```

4. **User assigned to tenant** with specified role

## Two-Factor Authentication Flow

1. **Setup 2FA**
   ```typescript
   const setup = await setupTwoFactorAuth('totp');
   // Shows QR code with totp_secret for scanning
   ```

2. **Verify 2FA**
   ```typescript
   await enableTwoFactorAuth(); // After scanning QR code
   ```

3. **Verify on Login**
   - User logs in with email/password
   - Server prompts for 2FA code
   - Validates TOTP/SMS/Email code
   - Issues session token

## Session Management Features

✅ **Device Tracking**
- Device name, type, IP address
- User agent capture

✅ **Concurrent Session Limits**
- Max 5 sessions per user (configurable)
- Oldest session ends when limit exceeded

✅ **Session Timeout**
- Configurable per tenant (default 30 min)
- Auto-logout on inactivity

✅ **Logout All Devices**
- End all sessions immediately
- Useful for password change or security concern

✅ **Remember Me**
- Optional persistent sessions
- 30-day default (configurable)

## Login Security

### Brute Force Protection

Track login attempts and lock account after failures:

```typescript
// Record attempt
await recordLoginAttempt(tenantId, email, ipAddress, 'failed', 'Invalid password');

// Check if locked
const isLocked = await isUserLockedOut(tenantId, email, ipAddress);

if (failedAttempts >= 5) {
  await lockUserAccount(tenantId, email, ipAddress);
  // Locked for 15 minutes (configurable)
}
```

### Password Reset

Secure password reset with expiring tokens:

```typescript
// Generate reset token (1 hour expiration)
const token = await createPasswordResetToken(tenantId, userId, email, ipAddress);
// Send email: /reset-password?token={token}

// Verify token before password change
const resetToken = await verifyPasswordResetToken(token);
if (resetToken) {
  // Allow password change
  await markResetTokenUsed(resetToken.id);
}
```

## OAuth/SSO Setup

### Configure Google OAuth

```typescript
await configureOAuthProvider(tenantId, 'google', {
  client_id: 'xxx.apps.googleusercontent.com',
  client_secret: 'xxx',
  redirect_uri: 'https://app.example.com/auth/google/callback',
  scope: 'openid email profile'
});

await enableOAuthProvider(tenantId, 'google', true);
```

### Supported Providers

- Google OAuth2
- Microsoft OAuth2 (Azure AD)
- GitHub OAuth2
- SAML 2.0 (enterprise)

## Audit Trail

Complete authentication event tracking:

```typescript
// Events logged:
// - login (success/failed)
// - logout
// - 2fa_setup
// - 2fa_verify
// - password_reset
// - invitation_sent
// - invitation_accepted
// - session_created
// - session_ended
// - oauth_linked

const audit = await getAuthAudit(tenantId, { limit: 100 });
// Returns: [
//   {
//     event_type: 'login',
//     status: 'success',
//     ip_address: '203.0.113.45',
//     user_agent: '...',
//     risk_level: 'low',
//     created_at: '2026-08-25T...'
//   }
// ]
```

## Security Best Practices

✅ **Session Security**
- Tokens stored securely (HttpOnly cookies)
- Token rotation on sensitive operations
- Refresh token separation

✅ **2FA Enforcement**
- Required for administrators
- Optional for regular users
- Multiple methods supported

✅ **Password Policy**
- Minimum 8 characters
- Uppercase, numbers, special chars
- 90-day expiration (optional)
- Reset tokens expire in 1 hour

✅ **IP Whitelisting**
- Optional per tenant
- Restrict access to known IPs

✅ **Audit Logging**
- All auth events logged
- IP, device, user agent captured
- Risk assessment per event

## Default Session Settings (Tenant 1)

- Session timeout: 30 minutes
- Remember me: Enabled (30 days)
- Max concurrent sessions: 5
- 2FA required for admins: Yes
- Device management: Enabled

## Testing Checklist

- [ ] Database migration applied
- [ ] User invitations working
- [ ] Session creation & management working
- [ ] 2FA setup & verification working
- [ ] Brute force lockout working
- [ ] Password reset token generation working
- [ ] Audit trail logging all events
- [ ] Session settings CRUD working
- [ ] OAuth provider configuration working
- [ ] All endpoints tested with proper auth

## Related Documentation

- [Multi-Tenancy Architecture](./MULTI_TENANCY.md)
- [Configuration System](./CONFIGURATION_SYSTEM.md)
- [API Documentation](./API.md)
- [Security Guidelines](./SECURITY.md)
