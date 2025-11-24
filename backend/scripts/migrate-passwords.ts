/**
 * Password Migration Script
 * 
 * Converts plain-text passwords to bcrypt hashes for all users in the database.
 * This script is idempotent - it can be run multiple times safely.
 * 
 * Usage: npx tsx backend/scripts/migrate-passwords.ts
 */

import dotenv from 'dotenv'
import { resolve } from 'path'
import bcrypt from 'bcrypt'
import { PrismaClient } from '@prisma/client'

// Load environment variables from backend/.env
dotenv.config({ path: resolve(__dirname, '../.env') })

const prisma = new PrismaClient()
const SALT_ROUNDS = 10

// Plain-text passwords are typically short (<60 chars)
// Bcrypt hashes are exactly 60 characters
const HASHED_PASSWORD_LENGTH = 60

async function migratePasswords() {
  console.log('🔐 Starting password migration...\n')

  try {
    // Find all users with plain-text passwords (length < 60)
    const users = await prisma.user.findMany({
      select: {
        id: true,
        email: true,
        password: true,
      },
    })

    console.log(`📊 Found ${users.length} total users in database\n`)

    let successCount = 0
    let failureCount = 0
    let skippedCount = 0
    const failures: Array<{ email: string; error: string }> = []

    for (const user of users) {
      try {
        // Skip if password is already hashed (bcrypt hashes are 60 chars starting with $2b$)
        if (user.password.length === HASHED_PASSWORD_LENGTH && user.password.startsWith('$2b$')) {
          console.log(`⏭️  Skipping ${user.email} - already hashed`)
          skippedCount++
          continue
        }

        // Skip if password is null or empty
        if (!user.password || user.password.trim() === '') {
          console.log(`⚠️  Skipping ${user.email} - null or empty password`)
          failures.push({ email: user.email, error: 'Null or empty password' })
          failureCount++
          continue
        }

        // Hash the plain-text password
        const hashedPassword = await bcrypt.hash(user.password, SALT_ROUNDS)

        // Update user record with hashed password
        await prisma.user.update({
          where: { id: user.id },
          data: { password: hashedPassword },
        })

        console.log(`✅ Successfully hashed password for ${user.email}`)
        successCount++
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error'
        console.error(`❌ Failed to hash password for ${user.email}: ${errorMessage}`)
        failures.push({ email: user.email, error: errorMessage })
        failureCount++
      }
    }

    // Print summary
    console.log('\n' + '='.repeat(50))
    console.log('📋 Migration Summary')
    console.log('='.repeat(50))
    console.log(`✅ Successfully migrated: ${successCount} users`)
    console.log(`⏭️  Already hashed (skipped): ${skippedCount} users`)
    console.log(`❌ Failed: ${failureCount} users`)
    console.log(`📊 Total processed: ${users.length} users`)

    if (failures.length > 0) {
      console.log('\n⚠️  Failed migrations:')
      failures.forEach(({ email, error }) => {
        console.log(`   - ${email}: ${error}`)
      })
      console.log('\n⚠️  Please review and manually fix failed migrations.')
    }

    if (successCount > 0) {
      console.log('\n✅ Migration completed successfully!')
      console.log('🔐 All passwords are now securely hashed with bcrypt.')
    } else if (skippedCount === users.length) {
      console.log('\n✅ All passwords are already hashed. No migration needed.')
    } else {
      console.log('\n⚠️  Migration completed with some failures. Please review above.')
    }
  } catch (error) {
    console.error('\n❌ Migration failed with error:', error)
    process.exit(1)
  } finally {
    await prisma.$disconnect()
  }
}

// Run migration
migratePasswords()
  .then(() => {
    console.log('\n✅ Migration script completed.')
    process.exit(0)
  })
  .catch((error) => {
    console.error('\n❌ Migration script failed:', error)
    process.exit(1)
  })
