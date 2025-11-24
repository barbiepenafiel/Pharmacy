import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { auth, admin } from '@/middleware'

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

export const POST = auth(admin(async (request: NextRequest) => {
  try {
    const body = await request.json()
    const { name, description, dosage, category, price, imageUrl, quantity, supplier } = body

    if (!name || !category || price === undefined) {
      return NextResponse.json(
        { success: false, error: 'Missing required fields: name, category, price' },
        { status: 400 }
      )
    }

    // Trim the name to handle whitespace
    const trimmedName = name.trim()

    // Check for duplicate product name (case-insensitive)
    const existingProduct = await prisma.product.findFirst({
      where: {
        name: {
          equals: trimmedName,
          mode: 'insensitive',
        },
      },
      select: {
        id: true,
        name: true,
        category: true,
      },
    })

    if (existingProduct) {
      return NextResponse.json(
        {
          success: false,
          error: `Product name '${existingProduct.name}' already exists`,
          code: 'DUPLICATE_NAME',
          existingProduct: {
            id: existingProduct.id,
            name: existingProduct.name,
            category: existingProduct.category,
          },
        },
        { status: 409 }
      )
    }

    const product = await prisma.product.create({
      data: {
        name: trimmedName,
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
  } catch (error: any) {
    console.error('Error creating product:', error)
    
    // Handle Prisma unique constraint violation
    if (error.code === 'P2002') {
      return NextResponse.json(
        {
          success: false,
          error: 'Product name already exists',
          code: 'DUPLICATE_NAME',
        },
        { status: 409 }
      )
    }

    return NextResponse.json(
      { success: false, error: 'Failed to create product' },
      { status: 500 }
    )
  }
}))
