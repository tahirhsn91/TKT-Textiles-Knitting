import { db } from '../db/index.js';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';

/**
 * Authentication Service
 * Handles user invitations, sessions, 2FA, and SSO
 */

export interface UserInvitation {
  id: number;
  tenant_id: number;
  email: string;
  role_name?: string;
  status: 'pending' | 'accepted' | 'expired' | 'cancelled';
  accepted_at?: Date;
  created_at: Date;
}

export interface UserSession {
  id: number;
  user_id: number;
  session_token: string;
  device_name?: string;
  ip_address: string;
  is_active: boolean;
  two_factor_verified: boolean;
  last_activity_at?: Date;
  expires_at: Date;
  created_at: Date;
}

export interface TwoFactorAuth {
  id: number;
  user_id: number;
  is_enabled: boolean;
  is_verified: boolean;
  totp_secret?: string;
  phone_number?: string;
  sms_enabled: boolean;
  email_enabled: boolean;
}

class AuthService {
  /**
   * Create user invitation
   */
  async createUserInvitation(
    tenantId: number,
    invitedByUserId: number,
    email: string,
    roleName?: string
  ): Promise<UserInvitation> {
    const invitationCode = crypto.randomBytes(16).toString('hex');
    const invitationToken = jwt.sign(
      { email, tenantId, code: invitationCode },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );

    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

    const [invitation] = await db('user_invitations')
      .insert({
        tenant_id: tenantId,
        invited_by: invitedByUserId,
        email: email,
        role_name: roleName,
        invitation_code: invitationCode,
        invitation_token: invitationToken,
        status: 'pending',
        expired_at: expiresAt,
      })
      .returning('*');

    return invitation;
  }

  /**
   * Get invitation by token
   */
  async getInvitationByToken(token: string): Promise<UserInvitation | null> {
    return db('user_invitations')
      .where({ invitation_token: token })
      .first();
  }

  /**
   * Accept invitation
   */
  async acceptInvitation(invitationId: number, userId: number): Promise<UserInvitation> {
    const [updated] = await db('user_invitations')
      .where({ id: invitationId })
      .update({
        status: 'accepted',
        accepted_at: new Date(),
        accepted_by_user_id: userId,
      })
      .returning('*');

    return updated;
  }

  /**
   * Get pending invitations for tenant
   */
  async getPendingInvitations(tenantId: number): Promise<UserInvitation[]> {
    return db('user_invitations')
      .where({ tenant_id: tenantId, status: 'pending' })
      .whereRaw('expired_at > NOW()')
      .orderBy('created_at', 'desc');
  }

  /**
   * Resend invitation email
   */
  async resendInvitation(invitationId: number): Promise<UserInvitation> {
    const invitation = await db('user_invitations').where({ id: invitationId }).first();

    if (!invitation) {
      throw new Error('Invitation not found');
    }

    const newExpiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    const [updated] = await db('user_invitations')
      .where({ id: invitationId })
      .update({
        expired_at: newExpiresAt,
        updated_at: new Date(),
      })
      .returning('*');

    return updated;
  }

  /**
   * Create user session
   */
  async createSession(
    tenantId: number,
    userId: number,
    ipAddress: string,
    userAgent: string,
    deviceName?: string
  ): Promise<UserSession> {
    const sessionToken = crypto.randomBytes(32).toString('hex');
    const refreshToken = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 30 * 60 * 1000); // 30 minutes

    const [session] = await db('user_sessions')
      .insert({
        tenant_id: tenantId,
        user_id: userId,
        session_token: sessionToken,
        refresh_token: refreshToken,
        device_name: deviceName,
        ip_address: ipAddress,
        user_agent: userAgent,
        is_active: true,
        expires_at: expiresAt,
      })
      .returning('*');

    return session;
  }

  /**
   * Get session by token
   */
  async getSessionByToken(token: string): Promise<UserSession | null> {
    return db('user_sessions')
      .where({ session_token: token, is_active: true })
      .first();
  }

  /**
   * Update session last activity
   */
  async updateSessionActivity(sessionId: number): Promise<void> {
    await db('user_sessions')
      .where({ id: sessionId })
      .update({ last_activity_at: new Date() });
  }

  /**
   * End session
   */
  async endSession(sessionId: number): Promise<void> {
    await db('user_sessions')
      .where({ id: sessionId })
      .update({ is_active: false });
  }

  /**
   * Get user sessions
   */
  async getUserSessions(userId: number, onlyActive: boolean = true): Promise<UserSession[]> {
    let query = db('user_sessions').where({ user_id: userId });

    if (onlyActive) {
      query = query.where({ is_active: true });
    }

    return query.orderBy('created_at', 'desc');
  }

  /**
   * End all user sessions (logout all devices)
   */
  async endAllUserSessions(userId: number): Promise<void> {
    await db('user_sessions')
      .where({ user_id: userId })
      .update({ is_active: false });
  }

  /**
   * Setup 2FA for user
   */
  async setupTwoFactorAuth(tenantId: number, userId: number, method: string = 'totp'): Promise<TwoFactorAuth> {
    const existing = await db('two_factor_auth')
      .where({ user_id: userId })
      .first();

    if (existing) {
      return existing;
    }

    let totpSecret = '';
    if (method === 'totp') {
      totpSecret = crypto.randomBytes(16).toString('base64');
    }

    const [twoFa] = await db('two_factor_auth')
      .insert({
        tenant_id: tenantId,
        user_id: userId,
        is_enabled: false,
        is_verified: false,
        totp_secret: totpSecret,
        email_enabled: true,
      })
      .returning('*');

    return twoFa;
  }

  /**
   * Enable 2FA for user
   */
  async enableTwoFactorAuth(userId: number): Promise<TwoFactorAuth> {
    const [updated] = await db('two_factor_auth')
      .where({ user_id: userId })
      .update({
        is_enabled: true,
        is_verified: true,
        verified_at: new Date(),
      })
      .returning('*');

    return updated;
  }

  /**
   * Disable 2FA for user
   */
  async disableTwoFactorAuth(userId: number): Promise<TwoFactorAuth> {
    const [updated] = await db('two_factor_auth')
      .where({ user_id: userId })
      .update({
        is_enabled: false,
        is_verified: false,
        totp_secret: null,
      })
      .returning('*');

    return updated;
  }

  /**
   * Get 2FA settings for user
   */
  async getTwoFactorAuth(userId: number): Promise<TwoFactorAuth | null> {
    return db('two_factor_auth').where({ user_id: userId }).first();
  }

  /**
   * Record login attempt
   */
  async recordLoginAttempt(
    tenantId: number,
    email: string,
    ipAddress: string,
    status: 'success' | 'failed',
    reason?: string
  ): Promise<void> {
    await db('login_attempts')
      .insert({
        tenant_id: tenantId,
        email: email,
        ip_address: ipAddress,
        status: status,
        failure_reason: reason,
        attempt_count: 1,
      })
      .onConflict(['tenant_id', 'email', 'ip_address'])
      .merge();
  }

  /**
   * Check if user is locked out
   */
  async isUserLockedOut(tenantId: number, email: string, ipAddress: string): Promise<boolean> {
    const attempt = await db('login_attempts')
      .where({ tenant_id: tenantId, email, ip_address })
      .first();

    if (!attempt) {
      return false;
    }

    if (!attempt.is_locked) {
      return false;
    }

    // Check if lockout has expired
    if (attempt.locked_until && new Date() > new Date(attempt.locked_until)) {
      await db('login_attempts')
        .where({ id: attempt.id })
        .update({ is_locked: false, locked_until: null });

      return false;
    }

    return true;
  }

  /**
   * Lock user account temporarily
   */
  async lockUserAccount(tenantId: number, email: string, ipAddress: string): Promise<void> {
    const lockoutDuration = 15; // minutes (from system defaults)
    const lockedUntil = new Date(Date.now() + lockoutDuration * 60 * 1000);

    await db('login_attempts')
      .where({ tenant_id: tenantId, email, ip_address })
      .update({
        is_locked: true,
        locked_until: lockedUntil,
        lockout_reason: 'Max login attempts exceeded',
      });
  }

  /**
   * Create password reset token
   */
  async createPasswordResetToken(
    tenantId: number,
    userId: number,
    email: string,
    ipAddress: string
  ): Promise<string> {
    const resetToken = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 1 * 60 * 60 * 1000); // 1 hour

    await db('password_reset_tokens').insert({
      tenant_id: tenantId,
      user_id: userId,
      email: email,
      reset_token: resetToken,
      ip_address: ipAddress,
      expires_at: expiresAt,
    });

    return resetToken;
  }

  /**
   * Verify password reset token
   */
  async verifyPasswordResetToken(token: string): Promise<any | null> {
    const resetToken = await db('password_reset_tokens')
      .where({ reset_token: token, is_used: false })
      .whereRaw('expires_at > NOW()')
      .first();

    return resetToken;
  }

  /**
   * Mark password reset token as used
   */
  async markResetTokenUsed(tokenId: number): Promise<void> {
    await db('password_reset_tokens')
      .where({ id: tokenId })
      .update({ is_used: true, used_at: new Date() });
  }

  /**
   * Record authentication audit event
   */
  async recordAuthAudit(
    tenantId: number,
    userId: number | null,
    email: string | null,
    eventType: string,
    status: string,
    ipAddress: string,
    userAgent: string,
    description?: string
  ): Promise<void> {
    await db('auth_audit').insert({
      tenant_id: tenantId,
      user_id: userId,
      email: email,
      event_type: eventType,
      event_description: description,
      status: status,
      ip_address: ipAddress,
      user_agent: userAgent,
      risk_level: status === 'success' ? 'low' : 'medium',
    });
  }

  /**
   * Get authentication audit trail
   */
  async getAuthAudit(tenantId: number, options: { limit?: number; offset?: number } = {}): Promise<any[]> {
    const limit = options.limit || 100;
    const offset = options.offset || 0;

    return db('auth_audit')
      .where({ tenant_id: tenantId })
      .orderBy('created_at', 'desc')
      .limit(limit)
      .offset(offset);
  }

  /**
   * Get session settings for tenant
   */
  async getSessionSettings(tenantId: number): Promise<any | null> {
    return db('session_settings').where({ tenant_id: tenantId }).first();
  }

  /**
   * Update session settings
   */
  async updateSessionSettings(tenantId: number, settings: any): Promise<any> {
    const existing = await this.getSessionSettings(tenantId);

    if (!existing) {
      const [created] = await db('session_settings')
        .insert({ tenant_id: tenantId, ...settings })
        .returning('*');
      return created;
    }

    const [updated] = await db('session_settings')
      .where({ tenant_id: tenantId })
      .update({ ...settings, updated_at: new Date() })
      .returning('*');

    return updated;
  }

  /**
   * Get OAuth providers for tenant
   */
  async getOAuthProviders(tenantId: number): Promise<any[]> {
    return db('oauth_providers').where({ tenant_id: tenantId });
  }

  /**
   * Configure OAuth provider
   */
  async configureOAuthProvider(
    tenantId: number,
    providerName: string,
    config: any
  ): Promise<any> {
    const existing = await db('oauth_providers')
      .where({ tenant_id: tenantId, provider_name: providerName })
      .first();

    if (!existing) {
      const [created] = await db('oauth_providers')
        .insert({
          tenant_id: tenantId,
          provider_name: providerName,
          provider_type: 'oauth2',
          client_id: config.client_id,
          client_secret: config.client_secret,
          redirect_uri: config.redirect_uri,
          scope: config.scope,
          config_json: config,
          is_configured: true,
        })
        .returning('*');

      return created;
    }

    const [updated] = await db('oauth_providers')
      .where({ tenant_id: tenantId, provider_name: providerName })
      .update({
        client_id: config.client_id,
        client_secret: config.client_secret,
        redirect_uri: config.redirect_uri,
        scope: config.scope,
        config_json: config,
        is_configured: true,
      })
      .returning('*');

    return updated;
  }

  /**
   * Enable/disable OAuth provider
   */
  async enableOAuthProvider(tenantId: number, providerName: string, enabled: boolean): Promise<any> {
    const [updated] = await db('oauth_providers')
      .where({ tenant_id: tenantId, provider_name: providerName })
      .update({ is_enabled: enabled })
      .returning('*');

    return updated;
  }
}

export const authService = new AuthService();
