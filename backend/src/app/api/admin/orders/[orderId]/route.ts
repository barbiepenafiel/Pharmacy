import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function PUT(
  request: NextRequest,
  { params }: { params: { orderId: string } }
) {
  try {
    const body = await request.json()
    const { status, total } = body

    const order = await prisma.order.update({
      where: { id: params.orderId },
      data: {
        status,
        total,
      },
    })
    return NextResponse.json(order)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to update order' }, { status: 500 })
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { orderId: string } }
) {
  try {
    await prisma.order.delete({
      where: { id: params.orderId },
    })
    return NextResponse.json({ message: 'Order deleted' })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to delete order' }, { status: 500 })
  }
}