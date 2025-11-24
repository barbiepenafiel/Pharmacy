import { NextRequest, NextResponse } from 'next/server'
import jwt from 'jsonwebtoken'

const JWT_SECRET = process.env.JWT_SECRET || ''

export interface AuthenticatedRequest extends NextRequest {
  user?: {
    userId: string
    email: string
    role: string
  }
}

export type AuthHandler = (
  request: AuthenticatedRequest
) => Promise<NextResponse> | NextResponse

/**
 * Authentication middleware - validates JWT tokens
 * Extracts token from Authorization header, verifies signature and expiration
 * Attaches decoded user data to request object
 */
export function auth(handler: AuthHandler) {
  return async (request: NextRequest) => {
    try {
      // Extract token from Authorization header
      const authHeader = request.headers.get('authorization')
      
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return NextResponse.json(
          { success: false, error: 'Authentication required' },
          { status: 401 }
        )
      }

      const token = authHeader.replace('Bearer ', '')

      // Verify JWT_SECRET is configured
      if (!JWT_SECRET) {
        console.error('JWT_SECRET environment variable is not configured')
        return NextResponse.json(
          { success: false, error: 'Server configuration error' },
          { status: 500 }
        )
      }

      // Verify token signature and expiration
      let decoded
      try {
        decoded = jwt.verify(token, JWT_SECRET) as {
          userId: string
          email: string
          role: string
        }
      } catch (error) {
        if (error instanceof jwt.TokenExpiredError) {
          return NextResponse.json(
            { success: false, error: 'Token expired' },
            { status: 401 }
          )
        }
        return NextResponse.json(
          { success: false, error: 'Invalid token' },
          { status: 401 }
        )
      }

      // Attach user data to request
      const authenticatedRequest = request as AuthenticatedRequest
      authenticatedRequest.user = decoded

      // Call the handler with authenticated request
      return handler(authenticatedRequest)
    } catch (error) {
      console.error('Auth middleware error:', error)
      return NextResponse.json(
        { success: false, error: 'Authentication failed' },
        { status: 401 }
      )
    }
  }
}
