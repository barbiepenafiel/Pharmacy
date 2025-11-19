import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const body = await request.json()
    const { name, dosage, quantity, supplier, expiryDate, status } = body

    const inventory = await prisma.inventory.update({
      where: { id: params.id },
      data: {
        name,
        dosage,
        quantity,
        supplier,
        expiryDate: expiryDate ? new Date(expiryDate) : undefined,
        status: status || (quantity === 0 ? 'low_stock' : 'in_stock'),
      },
    })

    return NextResponse.json({
      success: true,
      data: inventory,
    })
  } catch (error) {
    console.error('Error updating inventory:', error)
    return NextResponse.json(
      { success: false, error: 'Failed to update inventory' },
      { status: 500 }
    )
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    await prisma.inventory.delete({
      where: { id: params.id },
    })

    return NextResponse.json({
      success: true,
      message: 'Inventory item deleted',
    })
  } catch (error) {
    console.error('Error deleting inventory:', error)
    return NextResponse.json(
      { success: false, error: 'Failed to delete inventory' },
      { status: 500 }
    )
  }
}
