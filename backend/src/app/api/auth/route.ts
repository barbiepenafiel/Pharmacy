import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import bcrypt from 'bcrypt'
import jwt from 'jsonwebtoken'

const JWT_SECRET = process.env.JWT_SECRET || ''
const JWT_EXPIRATION = process.env.JWT_EXPIRATION || '24h'

if (!JWT_SECRET) {
  console.error('JWT_SECRET environment variable is not set!')
}

export async function POST(request: NextRequest) {
  try {
    const contentType = request.headers.get('content-type')
    if (!contentType || !contentType.includes('application/json')) {
      return NextResponse.json(
        { success: false, message: 'Content-Type must be application/json' },
        { status: 400 }
      )
    }

    const body = await request.json()
    const { action, email, password, fullName } = body

    if (!action) {
      return NextResponse.json(
        { success: false, message: 'Action is required' },
        { status: 400 }
      )
    }

    if (action === 'login') {
      if (!email || !password) {
        return NextResponse.json({
          success: false,
          message: 'Email and password are required',
        })
      }

      // Find user by email
      const user = await prisma.user.findUnique({
        where: { email },
      })

      if (!user) {
        return NextResponse.json({
          success: false,
          message: 'Invalid email or password',
        })
      }

      // Verify password with bcrypt
      const isValidPassword = await bcrypt.compare(password, user.password)
      
      if (!isValidPassword) {
        return NextResponse.json({
          success: false,
          message: 'Invalid email or password',
        })
      }

      // Generate JWT token
      if (!JWT_SECRET) {
        return NextResponse.json(
          { success: false, message: 'Server configuration error' },
          { status: 500 }
        )
      }

      const token = jwt.sign(
        {
          userId: user.id,
          email: user.email,
          role: user.role,
        } as object,
        JWT_SECRET,
        { expiresIn: JWT_EXPIRATION } as jwt.SignOptions
      )

      return NextResponse.json({
        success: true,
        message: 'Login successful',
        token,
        user: {
          id: user.id,
          email: user.email,
          fullName: user.name,
          isAdmin: user.role === 'admin',
        },
      })
    }

    if (action === 'register') {
      if (!fullName || !email || !password) {
        return NextResponse.json({
          success: false,
          message: 'All fields are required',
        })
      }

      // Check if user already exists
      const existingUser = await prisma.user.findUnique({
        where: { email },
      })

      if (existingUser) {
        return NextResponse.json({
          success: false,
          message: 'User with this email already exists',
        })
      }

      // Hash password with bcrypt (10 salt rounds)
      const hashedPassword = await bcrypt.hash(password, 10)

      // Create new user
      const user = await prisma.user.create({
        data: {
          name: fullName,
          email,
          password: hashedPassword,
          role: 'customer',
        },
      })

      return NextResponse.json({
        success: true,
        message: 'Registration successful. Please login.',
        user: {
          id: user.id,
          email: user.email,
          fullName: user.name,
          isAdmin: false,
        },
      })
    }

    return NextResponse.json({
      success: false,
      message: 'Invalid action',
    })
  } catch (error) {
    console.error('Auth error:', error)
    return NextResponse.json(
      {
        success: false,
        message: `Server error: ${error instanceof Error ? error.message : 'Unknown error'}`,
      },
      { status: 500 }
    )
  }
}