import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(request: NextRequest) {
  try {
    const inventory = await prisma.inventory.findMany({
      orderBy: { createdAt: 'desc' },
    })

    return NextResponse.json({
      success: true,
      data: inventory,
    })
  } catch (error) {
    console.error('Error fetching inventory:', error)
    return NextResponse.json(
      { success: false, error: 'Failed to fetch inventory' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { name, dosage, quantity, supplier, expiryDate } = body

    if (!name || !dosage || quantity === undefined || !supplier || !expiryDate) {
      return NextResponse.json(
        { success: false, error: 'Missing required fields' },
        { status: 400 }
      )
    }

    const inventory = await prisma.inventory.create({
      data: {
        name,
        dosage,
        quantity,
        supplier,
        expiryDate: new Date(expiryDate),
        status: quantity === 0 ? 'low_stock' : 'in_stock',
      },
    })

    return NextResponse.json({
      success: true,
      data: inventory,
    })
  } catch (error) {
    console.error('Error creating inventory item:', error)
    return NextResponse.json(
      { success: false, error: 'Failed to create inventory item' },
      { status: 500 }
    )
  }
}
