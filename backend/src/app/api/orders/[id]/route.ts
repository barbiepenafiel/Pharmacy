import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    console.log('GET /api/orders/[id] - Order ID:', id)
    
    const order = await prisma.order.findUnique({
      where: { id },
      include: { 
        user: {
          include: {
            addresses: true
          }
        },
        prescription: true 
      },
    })
    
    if (!order) {
      console.log('Order not found:', id)
      return NextResponse.json({ error: 'Order not found' }, { status: 404 })
    }
    
    console.log('Order found:', order)
    return NextResponse.json(order)
  } catch (error) {
    console.error('GET /api/orders/[id] error:', error)
    return NextResponse.json({ error: 'Failed to fetch order' }, { status: 500 })
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const body = await request.json()
    console.log('PUT /api/orders/[id] - Order ID:', id, 'Body:', body)
    
    const { prescriptionId, total, status } = body

    const order = await prisma.order.update({
      where: { id },
      data: {
        prescriptionId,
        total,
        status,
      },
      include: {
        user: {
          include: {
            addresses: true
          }
        },
        prescription: true
      }
    })
    
    console.log('Order updated:', order)
    return NextResponse.json(order)
  } catch (error) {
    console.error('PUT /api/orders/[id] error:', error)
    return NextResponse.json({ error: 'Failed to update order' }, { status: 500 })
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    console.log('DELETE /api/orders/[id] - Order ID:', id)
    
    // Check if order exists
    const existingOrder = await prisma.order.findUnique({
      where: { id }
    })
    
    if (!existingOrder) {
      console.log('Order not found for deletion:', id)
      return NextResponse.json({ error: 'Order not found' }, { status: 404 })
    }
    
    await prisma.order.delete({
      where: { id },
    })
    
    console.log('Order deleted successfully:', id)
    return NextResponse.json({ message: 'Order deleted successfully' })
  } catch (error) {
    console.error('DELETE /api/orders/[id] error:', error)
    return NextResponse.json({ error: 'Failed to delete order' }, { status: 500 })
  }
}