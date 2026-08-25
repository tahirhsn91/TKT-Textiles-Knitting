import { useState, useEffect } from 'react';
import axios from 'axios';

/**
 * useAuth Hook
 * Manages authentication, sessions, invitations, and 2FA
 */

export interface UserInvitation {
  id: number;
  email: string;
  role_name?: string;
  status: 'pending' | 'accepted' | 'expired';
  created_at: string;
}

export interface UserSession {
  id: number;
  device_name?: string;
  ip_address: string;
  is_active: boolean;
  last_activity_at?: string;
  created_at: string;
}

export interface TwoFactorAuthStatus {
  is_enabled: boolean;
  is_verified: boolean;
  methods: string[];
  last_verified_at?: string;
}

export interface SessionSettings {
  session_timeout_minutes: number;
  max_concurrent_sessions: number;
  two_factor_required_for_admins: boolean;
  two_factor_optional_for_users: boolean;
  device_management_enabled: boolean;
}

interface UseAuthReturn {
  invitations: UserInvitation[];
  sessions: UserSession[];
  twoFactorStatus: TwoFactorAuthStatus | null;
  sessionSettings: SessionSettings | null;
  loading: boolean;
  error: string | null;
  createInvitation: (email: string, roleName?: string) => Promise<void>;
  resendInvitation: (invitationId: number) => Promise<void>;
  acceptInvitation: (token: string, userId: number) => Promise<void>;
  getSessions: () => Promise<void>;
  endSession: (sessionId: number) => Promise<void>;
  logoutAllDevices: () => Promise<void>;
  setupTwoFactorAuth: (method?: string) => Promise<any>;
  enableTwoFactorAuth: () => Promise<void>;
  disableTwoFactorAuth: () => Promise<void>;
  getTwoFactorStatus: () => Promise<void>;
  updateSessionSettings: (settings: Partial<SessionSettings>) => Promise<void>;
  refreshAuth: () => Promise<void>;
}

export const useAuth = (): UseAuthReturn => {
  const [invitations, setInvitations] = useState<UserInvitation[]>([]);
  const [sessions, setSessions] = useState<UserSession[]>([]);
  const [twoFactorStatus, setTwoFactorStatus] = useState<TwoFactorAuthStatus | null>(null);
  const [sessionSettings, setSessionSettings] = useState<SessionSettings | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchAuthData();
  }, []);

  const fetchAuthData = async () => {
    try {
      setLoading(true);
      setError(null);

      const [invitationsRes, sessionsRes, twoFactorRes, settingsRes] = await Promise.all([
        axios.get('/api/v1/auth/invitations').catch(() => ({ data: { invitations: [] } })),
        axios.get('/api/v1/auth/sessions').catch(() => ({ data: { sessions: [] } })),
        axios.get('/api/v1/auth/2fa/status').catch(() => ({ data: { is_enabled: false, methods: [] } })),
        axios.get('/api/v1/auth/session-settings').catch(() => ({ data: {} })),
      ]);

      setInvitations(invitationsRes.data.invitations || []);
      setSessions(sessionsRes.data.sessions || []);
      setTwoFactorStatus(twoFactorRes.data);
      setSessionSettings(settingsRes.data);
    } catch (err) {
      console.error('Error fetching auth data:', err);
      setError('Failed to load authentication data');
    } finally {
      setLoading(false);
    }
  };

  const createInvitation = async (email: string, roleName?: string) => {
    try {
      setLoading(true);
      await axios.post('/api/v1/auth/invitations', { email, role_name: roleName });
      await fetchAuthData();
    } catch (err) {
      console.error('Error creating invitation:', err);
      setError('Failed to create invitation');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const resendInvitation = async (invitationId: number) => {
    try {
      setLoading(true);
      await axios.post(`/api/v1/auth/invitations/${invitationId}/resend`);
      await fetchAuthData();
    } catch (err) {
      console.error('Error resending invitation:', err);
      setError('Failed to resend invitation');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const acceptInvitation = async (token: string, userId: number) => {
    try {
      setLoading(true);
      await axios.post('/api/v1/auth/invitations/accept', { token, user_id: userId });
    } catch (err) {
      console.error('Error accepting invitation:', err);
      setError('Failed to accept invitation');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const getSessions = async () => {
    try {
      setLoading(true);
      const response = await axios.get('/api/v1/auth/sessions');
      setSessions(response.data.sessions);
    } catch (err) {
      console.error('Error fetching sessions:', err);
      setError('Failed to fetch sessions');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const endSession = async (sessionId: number) => {
    try {
      setLoading(true);
      await axios.delete(`/api/v1/auth/sessions/${sessionId}`);
      await getSessions();
    } catch (err) {
      console.error('Error ending session:', err);
      setError('Failed to end session');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const logoutAllDevices = async () => {
    try {
      setLoading(true);
      await axios.post('/api/v1/auth/sessions/logout-all');
      setSessions([]);
    } catch (err) {
      console.error('Error logging out all devices:', err);
      setError('Failed to logout from all devices');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const setupTwoFactorAuth = async (method?: string) => {
    try {
      setLoading(true);
      const response = await axios.post('/api/v1/auth/2fa/setup', { method: method || 'totp' });
      return response.data.data;
    } catch (err) {
      console.error('Error setting up 2FA:', err);
      setError('Failed to setup 2FA');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const enableTwoFactorAuth = async () => {
    try {
      setLoading(true);
      await axios.post('/api/v1/auth/2fa/enable');
      await getTwoFactorStatus();
    } catch (err) {
      console.error('Error enabling 2FA:', err);
      setError('Failed to enable 2FA');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const disableTwoFactorAuth = async () => {
    try {
      setLoading(true);
      await axios.post('/api/v1/auth/2fa/disable');
      await getTwoFactorStatus();
    } catch (err) {
      console.error('Error disabling 2FA:', err);
      setError('Failed to disable 2FA');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const getTwoFactorStatus = async () => {
    try {
      const response = await axios.get('/api/v1/auth/2fa/status');
      setTwoFactorStatus(response.data);
    } catch (err) {
      console.error('Error fetching 2FA status:', err);
    }
  };

  const updateSessionSettings = async (settings: Partial<SessionSettings>) => {
    try {
      setLoading(true);
      const response = await axios.put('/api/v1/auth/session-settings', settings);
      setSessionSettings(response.data.data);
    } catch (err) {
      console.error('Error updating session settings:', err);
      setError('Failed to update session settings');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return {
    invitations,
    sessions,
    twoFactorStatus,
    sessionSettings,
    loading,
    error,
    createInvitation,
    resendInvitation,
    acceptInvitation,
    getSessions,
    endSession,
    logoutAllDevices,
    setupTwoFactorAuth,
    enableTwoFactorAuth,
    disableTwoFactorAuth,
    getTwoFactorStatus,
    updateSessionSettings,
    refreshAuth: fetchAuthData,
  };
};
