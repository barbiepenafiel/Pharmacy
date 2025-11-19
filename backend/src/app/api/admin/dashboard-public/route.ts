import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  try {
    // Get counts
    const [userCount, orderCount, prescriptionCount, addressCount] = await Promise.all([
      prisma.user.count(),
      prisma.order.count(),
      prisma.prescription.count(),
      prisma.address.count(),
    ])

    // Get today's sales (sum of order totals from today)
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const todayOrders = await prisma.order.findMany({
      where: {
        createdAt: {
          gte: today,
        },
      },
    })
    const todaysSales = todayOrders.reduce((sum, order) => sum + (order.total || 0), 0)

    // Get prescriptions filled count
    const prescriptionsFilled = await prisma.prescription.count({
      where: {
        status: 'completed',
      },
    })

    // Get pending orders count
    const pendingOrders = await prisma.order.count({
      where: {
        status: 'pending',
      },
    })

    // Get top medications (prescriptions grouped by medication name)
    const topMedications = await prisma.prescription.groupBy({
      by: ['medication'],
      _count: {
        id: true,
      },
      take: 4,
      orderBy: {
        _count: {
          id: 'desc',
        },
      },
    })

    // Get recent orders with user info
    const recentOrders = await prisma.order.findMany({
      take: 3,
      orderBy: {
        createdAt: 'desc',
      },
      include: {
        user: {
          select: {
            name: true,
          },
        },
      },
    })

    return NextResponse.json({
      totalUsers: userCount,
      totalOrders: orderCount,
      totalPrescriptions: prescriptionCount,
      totalAddresses: addressCount,
      todaysSales: Number(todaysSales.toFixed(2)),
      prescriptionsFilled: prescriptionsFilled,
      pendingOrders: pendingOrders,
      topMedications: topMedications.map((med) => ({
        name: med.medication,
        count: med._count.id,
      })),
      recentOrders: recentOrders.map((order) => ({
        id: order.id,
        orderNumber: `Order #${order.id.substring(0, 5).toUpperCase()}`,
        customerName: order.user?.name || 'Unknown',
        status: order.status,
        createdAt: order.createdAt,
        total: order.total,
      })),
    })
  } catch (error) {
    console.error('Dashboard error:', error)
    return NextResponse.json({ error: 'Failed to fetch dashboard stats' }, { status: 500 })
  }
}