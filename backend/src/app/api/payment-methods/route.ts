import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const userId = searchParams.get('userId')

    const paymentMethods = await prisma.paymentMethod.findMany({
      where: userId ? { userId } : {},
      include: { user: true },
    })
    return NextResponse.json(paymentMethods)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch payment methods' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { userId, type, details } = body

    const paymentMethod = await prisma.paymentMethod.create({
      data: {
        userId,
        type,
        details,
      },
    })
    return NextResponse.json(paymentMethod, { status: 201 })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to create payment method' }, { status: 500 })
  }
}