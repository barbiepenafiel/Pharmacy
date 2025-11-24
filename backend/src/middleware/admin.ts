import { NextResponse } from 'next/server'
import { AuthenticatedRequest, AuthHandler } from './auth'

/**
 * Admin authorization middleware - checks if user has admin role
 * Must be composed with auth middleware: auth(admin(handler))
 * Returns 403 Forbidden if user is not an admin
 */
export function admin(handler: AuthHandler) {
  return async (request: AuthenticatedRequest) => {
    // Check if user exists (should be set by auth middleware)
    if (!request.user) {
      return NextResponse.json(
        { success: false, error: 'Authentication required' },
        { status: 401 }
      )
    }

    // Check if user has admin role
    if (request.user.role !== 'admin') {
      return NextResponse.json(
        { success: false, error: 'Admin access required' },
        { status: 403 }
      )
    }

    // User is admin, proceed to handler
    return handler(request)
  }
}
