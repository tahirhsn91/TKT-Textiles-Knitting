import { Request, Response, NextFunction } from 'express';
import { db } from '../db/connection';

/**
 * Super Admin Middleware
 * Validates that user is a super-admin
 */

export interface SuperAdminRequest extends Request {
  userId?: number;
  user?: any;
}

export const requireSuperAdmin = async (req: SuperAdminRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized: User not authenticated' });
    }

    // Get user and check if they have super-admin role
    const user = await db('app_user')
      .join('role', 'app_user.role_id', '=', 'role.id')
      .where({ 'app_user.id': req.userId })
      .select('app_user.id', 'app_user.email', 'role.name', 'role.is_admin')
      .first();

    if (!user) {
      return res.status(401).json({ error: 'Unauthorized: User not found' });
    }

    if (user.name !== 'super-admin') {
      return res.status(403).json({
        error: 'Forbidden: Super-admin access required',
        message: 'You do not have permission to access this resource',
      });
    }

    // Attach user info to request
    req.user = user;
    next();
  } catch (error) {
    console.error('Super admin middleware error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
