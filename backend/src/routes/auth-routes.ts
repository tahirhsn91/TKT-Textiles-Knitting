import express, { Router } from 'express';
import { TenantRequest, requireTenant } from '../middleware/tenant-context';
import { authService } from '../services/auth-service';

const router: Router = express.Router();

/**
 * POST /api/v1/auth/invitations
 * Create user invitation
 */
router.post('/invitations', requireTenant, async (req: TenantRequest, res) => {
  try {
    const { email, role_name } = req.body;

    if (!email) {
      return res.status(400).json({ error: 'email is required' });
    }

    const invitation = await authService.createUserInvitation(
      req.tenantId!,
      req.userId!,
      email,
      role_name
    );

    res.status(201).json({
      message: 'Invitation created successfully',
      data: invitation,
      invitation_link: `${process.env.APP_URL}/accept-invitation?token=${invitation.invitation_token}`,
    });
  } catch (error) {
    console.error('Error creating invitation:', error);
    res.status(500).json({ error: 'Failed to create invitation' });
  }
});

/**
 * GET /api/v1/auth/invitations
 * Get pending invitations for tenant
 */
router.get('/invitations', requireTenant, async (req: TenantRequest, res) => {
  try {
    const invitations = await authService.getPendingInvitations(req.tenantId!);

    res.json({
      total: invitations.length,
      invitations,
    });
  } catch (error) {
    console.error('Error fetching invitations:', error);
    res.status(500).json({ error: 'Failed to fetch invitations' });
  }
});

/**
 * POST /api/v1/auth/invitations/:invitationId/resend
 * Resend invitation email
 */
router.post('/invitations/:invitationId/resend', requireTenant, async (req: TenantRequest, res) => {
  try {
    const invitationId = parseInt(req.params.invitationId);
    const invitation = await authService.resendInvitation(invitationId);

    res.json({
      message: 'Invitation resent successfully',
      data: invitation,
    });
  } catch (error) {
    console.error('Error resending invitation:', error);
    res.status(500).json({ error: 'Failed to resend invitation' });
  }
});

/**
 * POST /api/v1/auth/invitations/accept
 * Accept invitation (public endpoint - used with token)
 */
router.post('/invitations/accept', async (req: TenantRequest, res) => {
  try {
    const { token, user_id } = req.body;

    if (!token || !user_id) {
      return res.status(400).json({ error: 'token and user_id are required' });
    }

    const invitation = await authService.getInvitationByToken(token);

    if (!invitation) {
      return res.status(404).json({ error: 'Invitation not found or expired' });
    }

    if (invitation.status !== 'pending') {
      return res.status(400).json({ error: 'Invitation already accepted or cancelled' });
    }

    const accepted = await authService.acceptInvitation(invitation.id, user_id);

    res.json({
      message: 'Invitation accepted successfully',
      data: accepted,
    });
  } catch (error) {
    console.error('Error accepting invitation:', error);
    res.status(500).json({ error: 'Failed to accept invitation' });
  }
});

/**
 * GET /api/v1/auth/sessions
 * Get user sessions
 */
router.get('/sessions', requireTenant, async (req: TenantRequest, res) => {
  try {
    const sessions = await authService.getUserSessions(req.userId!, true);

    res.json({
      total: sessions.length,
      sessions: sessions.map((s) => ({
        id: s.id,
        device_name: s.device_name,
        ip_address: s.ip_address,
        is_active: s.is_active,
        last_activity_at: s.last_activity_at,
        created_at: s.created_at,
      })),
    });
  } catch (error) {
    console.error('Error fetching sessions:', error);
    res.status(500).json({ error: 'Failed to fetch sessions' });
  }
});

/**
 * DELETE /api/v1/auth/sessions/:sessionId
 * End session
 */
router.delete('/sessions/:sessionId', requireTenant, async (req: TenantRequest, res) => {
  try {
    const sessionId = parseInt(req.params.sessionId);
    await authService.endSession(sessionId);

    res.json({ message: 'Session ended successfully' });
  } catch (error) {
    console.error('Error ending session:', error);
    res.status(500).json({ error: 'Failed to end session' });
  }
});

/**
 * POST /api/v1/auth/sessions/logout-all
 * End all user sessions
 */
router.post('/sessions/logout-all', requireTenant, async (req: TenantRequest, res) => {
  try {
    await authService.endAllUserSessions(req.userId!);

    res.json({ message: 'All sessions ended successfully' });
  } catch (error) {
    console.error('Error ending all sessions:', error);
    res.status(500).json({ error: 'Failed to end all sessions' });
  }
});

/**
 * POST /api/v1/auth/2fa/setup
 * Setup two-factor authentication
 */
router.post('/2fa/setup', requireTenant, async (req: TenantRequest, res) => {
  try {
    const { method } = req.body;

    const twoFa = await authService.setupTwoFactorAuth(req.tenantId!, req.userId!, method || 'totp');

    res.json({
      message: '2FA setup started',
      data: {
        is_enabled: twoFa.is_enabled,
        totp_secret: twoFa.totp_secret, // Share only during setup
        methods: ['totp', 'sms', 'email'],
      },
    });
  } catch (error) {
    console.error('Error setting up 2FA:', error);
    res.status(500).json({ error: 'Failed to setup 2FA' });
  }
});

/**
 * POST /api/v1/auth/2fa/enable
 * Enable two-factor authentication
 */
router.post('/2fa/enable', requireTenant, async (req: TenantRequest, res) => {
  try {
    const twoFa = await authService.enableTwoFactorAuth(req.userId!);

    res.json({
      message: '2FA enabled successfully',
      data: { is_enabled: twoFa.is_enabled },
    });
  } catch (error) {
    console.error('Error enabling 2FA:', error);
    res.status(500).json({ error: 'Failed to enable 2FA' });
  }
});

/**
 * POST /api/v1/auth/2fa/disable
 * Disable two-factor authentication
 */
router.post('/2fa/disable', requireTenant, async (req: TenantRequest, res) => {
  try {
    const twoFa = await authService.disableTwoFactorAuth(req.userId!);

    res.json({
      message: '2FA disabled successfully',
      data: { is_enabled: twoFa.is_enabled },
    });
  } catch (error) {
    console.error('Error disabling 2FA:', error);
    res.status(500).json({ error: 'Failed to disable 2FA' });
  }
});

/**
 * GET /api/v1/auth/2fa/status
 * Get 2FA status for current user
 */
router.get('/2fa/status', requireTenant, async (req: TenantRequest, res) => {
  try {
    const twoFa = await authService.getTwoFactorAuth(req.userId!);

    if (!twoFa) {
      return res.json({ is_enabled: false, methods: [] });
    }

    const methods = [];
    if (twoFa.totp_secret) methods.push('totp');
    if (twoFa.sms_enabled) methods.push('sms');
    if (twoFa.email_enabled) methods.push('email');

    res.json({
      is_enabled: twoFa.is_enabled,
      is_verified: twoFa.is_verified,
      methods,
      last_verified_at: twoFa.last_verified_at,
    });
  } catch (error) {
    console.error('Error fetching 2FA status:', error);
    res.status(500).json({ error: 'Failed to fetch 2FA status' });
  }
});

/**
 * GET /api/v1/auth/audit
 * Get authentication audit trail
 */
router.get('/audit', requireTenant, async (req: TenantRequest, res) => {
  try {
    const limit = parseInt(req.query.limit as string) || 100;
    const offset = parseInt(req.query.offset as string) || 0;

    const audit = await authService.getAuthAudit(req.tenantId!, { limit, offset });

    res.json({
      total: audit.length,
      limit,
      offset,
      audit,
    });
  } catch (error) {
    console.error('Error fetching audit trail:', error);
    res.status(500).json({ error: 'Failed to fetch audit trail' });
  }
});

/**
 * GET /api/v1/auth/session-settings
 * Get session settings for tenant
 */
router.get('/session-settings', requireTenant, async (req: TenantRequest, res) => {
  try {
    const settings = await authService.getSessionSettings(req.tenantId!);

    if (!settings) {
      return res.status(404).json({ error: 'Session settings not found' });
    }

    res.json(settings);
  } catch (error) {
    console.error('Error fetching session settings:', error);
    res.status(500).json({ error: 'Failed to fetch session settings' });
  }
});

/**
 * PUT /api/v1/auth/session-settings
 * Update session settings for tenant
 */
router.put('/session-settings', requireTenant, async (req: TenantRequest, res) => {
  try {
    const settings = await authService.updateSessionSettings(req.tenantId!, req.body);

    res.json({
      message: 'Session settings updated successfully',
      data: settings,
    });
  } catch (error) {
    console.error('Error updating session settings:', error);
    res.status(500).json({ error: 'Failed to update session settings' });
  }
});

/**
 * GET /api/v1/auth/oauth-providers
 * Get OAuth providers for tenant
 */
router.get('/oauth-providers', requireTenant, async (req: TenantRequest, res) => {
  try {
    const providers = await authService.getOAuthProviders(req.tenantId!);

    res.json({
      total: providers.length,
      providers: providers.map((p) => ({
        provider_name: p.provider_name,
        is_enabled: p.is_enabled,
        is_configured: p.is_configured,
      })),
    });
  } catch (error) {
    console.error('Error fetching OAuth providers:', error);
    res.status(500).json({ error: 'Failed to fetch OAuth providers' });
  }
});

/**
 * POST /api/v1/auth/oauth-providers/:providerName/configure
 * Configure OAuth provider
 */
router.post('/oauth-providers/:providerName/configure', requireTenant, async (req: TenantRequest, res) => {
  try {
    const providerName = req.params.providerName;
    const config = await authService.configureOAuthProvider(req.tenantId!, providerName, req.body);

    res.json({
      message: `${providerName} OAuth provider configured successfully`,
      data: config,
    });
  } catch (error) {
    console.error('Error configuring OAuth provider:', error);
    res.status(500).json({ error: 'Failed to configure OAuth provider' });
  }
});

/**
 * POST /api/v1/auth/oauth-providers/:providerName/enable
 * Enable/disable OAuth provider
 */
router.post('/oauth-providers/:providerName/enable', requireTenant, async (req: TenantRequest, res) => {
  try {
    const { is_enabled } = req.body;
    const providerName = req.params.providerName;

    const provider = await authService.enableOAuthProvider(req.tenantId!, providerName, is_enabled);

    res.json({
      message: `${providerName} OAuth provider ${is_enabled ? 'enabled' : 'disabled'} successfully`,
      data: provider,
    });
  } catch (error) {
    console.error('Error enabling OAuth provider:', error);
    res.status(500).json({ error: 'Failed to enable OAuth provider' });
  }
});

export default router;
