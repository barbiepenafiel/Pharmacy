import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const userId = searchParams.get('userId')
    
    console.log('GET /api/orders - userId:', userId)

    const orders = await prisma.order.findMany({
      where: userId ? { userId } : {},
      include: { 
        user: {
          include: {
            addresses: true
          }
        },
        prescription: true 
      },
      orderBy: {
        createdAt: 'desc'
      }
    })
    
    console.log('Orders found:', orders.length)
    return NextResponse.json(orders)
  } catch (error) {
    console.error('GET /api/orders error:', error)
    return NextResponse.json({ error: 'Failed to fetch orders' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { userId, prescriptionId, total, status } = body

    const order = await prisma.order.create({
      data: {
        userId,
        prescriptionId,
        total,
        status: status || 'pending',
      },
    })
    return NextResponse.json(order, { status: 201 })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to create order' }, { status: 500 })
  }
}