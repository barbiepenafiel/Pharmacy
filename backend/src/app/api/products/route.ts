import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(request: NextRequest) {
  try {
    const products = await prisma.product.findMany({
      orderBy: { createdAt: 'desc' },
    })

    return NextResponse.json({
      success: true,
      data: products,
    })
  } catch (error) {
    console.error('Error fetching products:', error)
    return NextResponse.json(
      { success: false, error: 'Failed to fetch products' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { name, description, dosage, category, price, imageUrl, quantity, supplier } = body

    if (!name || !category || price === undefined) {
      return NextResponse.json(
        { success: false, error: 'Missing required fields: name, category, price' },
        { status: 400 }
      )
    }

    const product = await prisma.product.create({
      data: {
        name,
        description,
        dosage,
        category,
        price: parseFloat(price),
        imageUrl,
        quantity: quantity ? parseInt(quantity) : 0,
        supplier,
      },
    })

    return NextResponse.json({
      success: true,
      data: product,
    })
  } catch (error) {
    console.error('Error creating product:', error)
    return NextResponse.json(
      { success: false, error: 'Failed to create product' },
      { status: 500 }
    )
  }
}
