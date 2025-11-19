const { prisma } = require('./src/lib/prisma')

async function main() {
  try {
    // Create admin user if it doesn't exist
    const adminUser = await prisma.user.upsert({
      where: { email: 'admin@pharmacy.com' },
      update: {},
      create: {
        email: 'admin@pharmacy.com',
        password: 'admin123', // In production, hash this
        name: 'Admin User',
        role: 'admin',
      },
    })

    console.log('Admin user created/updated:', adminUser)

    // Create a regular user for testing
    const regularUser = await prisma.user.upsert({
      where: { email: 'user@example.com' },
      update: {},
      create: {
        email: 'user@example.com',
        password: 'password123',
        name: 'Regular User',
        role: 'customer',
      },
    })

    console.log('Regular user created/updated:', regularUser)
  } catch (error) {
    console.error('Error seeding database:', error)
  } finally {
    await prisma.$disconnect()
  }
}

main()