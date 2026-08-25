import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

/**
 * Tenant context middleware
 * Extracts tenant_id from JWT token and attaches to request
 * Ensures all database queries are filtered by tenant
 */

export interface TenantRequest extends Request {
  tenantId?: number;
  userId?: number;
  user?: any;
}

export const tenantMiddleware = (req: TenantRequest, res: Response, next: NextFunction) => {
  try {
    // Extract token from Authorization header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      // Skip tenant validation for public routes
      return next();
    }

    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key') as any;

    // Extract tenant_id from token payload
    if (!decoded.tenantId) {
      return res.status(401).json({
        error: 'Invalid token: missing tenant_id',
      });
    }

    // Attach tenant context to request
    req.tenantId = decoded.tenantId;
    req.userId = decoded.sub || decoded.userId || decoded.id;
    req.user = decoded;

    next();
  } catch (error) {
    console.error('Tenant middleware error:', error);
    return res.status(401).json({
      error: 'Unauthorized: Invalid token',
    });
  }
};

/**
 * Require authenticated tenant
 * Middleware to ensure tenant_id is present
 */
export const requireTenant = (req: TenantRequest, res: Response, next: NextFunction) => {
  if (!req.tenantId) {
    return res.status(401).json({
      error: 'Unauthorized: Tenant context required',
    });
  }
  next();
};

/**
 * Get tenant-filtered query
 * Adds WHERE clause to filter by current tenant
 * Usage: db.select('*').from('users').where(getTenantFilter(req))
 */
export const getTenantFilter = (req: TenantRequest) => {
  if (!req.tenantId) {
    throw new Error('Tenant context not found in request');
  }
  return {
    tenant_id: req.tenantId,
  };
};

/**
 * Validate tenant ownership
 * Ensures user belongs to the requested tenant
 */
export const validateTenantOwnership = async (
  req: TenantRequest,
  userId: number,
  db: any
) => {
  if (!req.tenantId) {
    throw new Error('Tenant context required');
  }

  const user = await db('app_user')
    .where({
      id: userId,
      tenant_id: req.tenantId,
    })
    .first();

  if (!user) {
    throw new Error('User does not belong to this tenant');
  }

  return user;
};
