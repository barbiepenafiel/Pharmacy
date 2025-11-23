const { PrismaClient } = require('@prisma/client');

async function checkDuplicates() {
  const prisma = new PrismaClient();
  
  try {
    const duplicates = await prisma.$queryRaw`
      SELECT name, COUNT(*) as count, STRING_AGG(id::text, ', ') as product_ids
      FROM "Product"
      GROUP BY name
      HAVING COUNT(*) > 1
      ORDER BY count DESC
    `;
    
    console.log('Checking for duplicate product names...\n');
    
    if (duplicates.length === 0) {
      console.log('✅ No duplicate product names found!');
      console.log('   Safe to add unique constraint.\n');
    } else {
      console.log(`❌ Found ${duplicates.length} duplicate product name(s):\n`);
      duplicates.forEach(dup => {
        console.log(`   Name: "${dup.name}"`);
        console.log(`   Count: ${dup.count}`);
        console.log(`   Product IDs: ${dup.product_ids}\n`);
      });
      console.log('⚠️  Please resolve duplicates before adding unique constraint.');
    }
  } catch (error) {
    console.error('Error checking duplicates:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

checkDuplicates();
