import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { auth, admin } from '@/middleware'

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const product = await prisma.product.findUnique({
      where: { id },
    })

    if (!product) {
      return NextResponse.json(
        { success: false, error: 'Product not found' },
        { status: 404 }
      )
    }

    return NextResponse.json({
      success: true,
      data: product,
    })
  } catch (error) {
    console.error('Error fetching product:', error)
    return NextResponse.json(
      { success: false, error: 'Failed to fetch product' },
      { status: 500 }
    )
  }
}

async function putHandler(
  request: NextRequest,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params
    const body = await request.json()
    const { name, description, dosage, category, price, imageUrl, quantity, supplier } = body

    // If name is being updated, check for duplicates
    if (name) {
      const trimmedName = name.trim()

      // Check if another product already has this name (case-insensitive)
      const existingProduct = await prisma.product.findFirst({
        where: {
          name: {
            equals: trimmedName,
            mode: 'insensitive',
          },
          NOT: {
            id: id, // Exclude the current product being updated
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
            error: `Product name '${existingProduct.name}' is already used by another product`,
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
    }

    const product = await prisma.product.update({
      where: { id },
      data: {
        name: name ? name.trim() : undefined,
        description,
        dosage,
        category,
        price: price ? parseFloat(price) : undefined,
        imageUrl,
        quantity: quantity ? parseInt(quantity) : undefined,
        supplier,
      },
    })

    return NextResponse.json({
      success: true,
      data: product,
    })
  } catch (error: any) {
    console.error('Error updating product:', error)
    
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
      { success: false, error: 'Failed to update product' },
      { status: 500 }
    )
  }
}

export async function PUT(
  request: NextRequest,
  context: { params: Promise<{ id: string }> }
) {
  return auth(admin(async (req) => {
    return putHandler(req, context)
  }))(request)
}

async function deleteHandler(
  request: NextRequest,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id} = await context.params
    console.log('🗑️ DELETE request for product ID:', id)
    
    // First check if product exists
    const existingProduct = await prisma.product.findUnique({
      where: { id },
    })

    if (!existingProduct) {
      console.log('❌ Product not found:', id)
      return NextResponse.json(
        { success: false, error: 'Product not found' },
        { status: 404 }
      )
    }

    console.log('✅ Product found, deleting:', existingProduct.name)
    
    await prisma.product.delete({
      where: { id },
    })

    console.log('✅ Product deleted successfully')
    
    return NextResponse.json({
      success: true,
      message: 'Product deleted',
    })
  } catch (error) {
    console.error('❌ Error deleting product:', error)
    return NextResponse.json(
      { success: false, error: `Failed to delete product: ${error}` },
      { status: 500 }
    )
  }
}

export async function DELETE(
  request: NextRequest,
  context: { params: Promise<{ id: string }> }
) {
  return auth(admin(async (req) => {
    return deleteHandler(req, context)
  }))(request)
}
