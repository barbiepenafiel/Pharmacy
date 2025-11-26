# Production Deployment Checklist

This checklist ensures a smooth transition from development to production for both the Flutter app and Next.js backend.

---

## Backend Deployment

### Pre-Deployment

- [ ] **Environment Variables**
  - [ ] `DATABASE_URL` points to production database
  - [ ] `DIRECT_DATABASE_URL` configured for migrations
  - [ ] `NODE_ENV=production`
  - [ ] `JWT_SECRET` set to secure random value
  - [ ] `CORS_ORIGIN` set to frontend domain (if applicable)

- [ ] **Database**
  - [ ] Production database created (Neon, AWS RDS, etc.)
  - [ ] Connection pooling enabled
  - [ ] SSL/TLS configured
  - [ ] Migrations applied: `npx prisma migrate deploy`
  - [ ] Prisma client generated: `npx prisma generate`
  - [ ] Backup strategy in place

- [ ] **Code Review**
  - [ ] Remove console.log statements (or use proper logging)
  - [ ] Remove debug endpoints
  - [ ] Verify error messages don't expose sensitive info
  - [ ] Check for hardcoded secrets or API keys
  - [ ] Review API rate limiting

- [ ] **Testing**
  - [ ] All API endpoints tested
  - [ ] Authentication flow verified
  - [ ] Database queries optimized
  - [ ] Error handling tested
  - [ ] Load testing completed

### Deployment Platform Options

#### Option 1: Vercel (Recommended for Next.js)

**Advantages:**
- Zero-config deployment
- Automatic HTTPS
- Global CDN
- Free tier available

**Steps:**
```bash
# 1. Install Vercel CLI
npm install -g vercel

# 2. Login to Vercel
vercel login

# 3. Deploy from backend directory
cd backend
vercel

# 4. Set environment variables in Vercel dashboard
# Go to: Project Settings > Environment Variables
```

**Environment Variables to Add:**
```
DATABASE_URL=postgresql://...
DIRECT_DATABASE_URL=postgresql://...
NODE_ENV=production
```

- [ ] Vercel account created
- [ ] Project linked to GitHub repo (optional)
- [ ] Environment variables configured
- [ ] Custom domain configured (optional)
- [ ] Deployment successful
- [ ] Health check endpoint accessible: `https://your-domain.vercel.app/api/health`

#### Option 2: Railway

**Advantages:**
- Simple deployment
- Built-in PostgreSQL option
- Automatic HTTPS
- Easy GitHub integration

**Steps:**
1. [ ] Sign up at https://railway.app
2. [ ] Click "New Project" > "Deploy from GitHub"
3. [ ] Select your repository
4. [ ] Add environment variables in Railway dashboard
5. [ ] Deploy

#### Option 3: Heroku

**Steps:**
```bash
# 1. Install Heroku CLI
npm install -g heroku

# 2. Login
heroku login

# 3. Create app
cd backend
heroku create pharmacy-backend

# 4. Add PostgreSQL
heroku addons:create heroku-postgresql:hobby-dev

# 5. Set environment variables
heroku config:set NODE_ENV=production
heroku config:set DATABASE_URL=postgresql://...

# 6. Deploy
git push heroku main
```

- [ ] Heroku account created
- [ ] PostgreSQL add-on configured
- [ ] Environment variables set
- [ ] Deployment successful

### Post-Deployment

- [ ] **Verify Deployment**
  - [ ] Health check endpoint responds: `curl https://your-domain/api/health`
  - [ ] Database connection confirmed
  - [ ] Test login/register endpoints
  - [ ] Test product listing
  - [ ] Test order creation

- [ ] **Monitoring**
  - [ ] Set up error tracking (Sentry, LogRocket, etc.)
  - [ ] Configure uptime monitoring (UptimeRobot, Pingdom)
  - [ ] Set up log aggregation
  - [ ] Database performance monitoring

- [ ] **Security**
  - [ ] HTTPS enforced
  - [ ] CORS properly configured
  - [ ] Rate limiting enabled
  - [ ] Input validation on all endpoints
  - [ ] SQL injection prevention verified
  - [ ] XSS protection enabled

- [ ] **Documentation**
  - [ ] API documentation updated with production URLs
  - [ ] Team notified of new endpoints
  - [ ] Production environment variables documented

---

## Flutter App Deployment

### Pre-Deployment

- [ ] **Configuration**
  - [ ] Update `app_config.dart` production URL
  - [ ] Set `BackendEnvironment.current = BackendEnvironment.production`
  - [ ] Remove debug logs
  - [ ] Update app version in `pubspec.yaml`
  - [ ] Update app icon and splash screen

- [ ] **Testing**
  - [ ] All screens tested on physical devices
  - [ ] Test with production backend
  - [ ] Test offline behavior
  - [ ] Test error handling
  - [ ] Performance testing completed
  - [ ] Memory leak checks

- [ ] **Code Review**
  - [ ] Remove test credentials
  - [ ] Check for hardcoded API keys
  - [ ] Verify all API calls use AppConfig
  - [ ] Review permissions (AndroidManifest.xml, Info.plist)

### Android Build

#### Debug Build (Internal Testing)
```bash
flutter build apk --debug
```

- [ ] Debug APK built successfully
- [ ] Tested on multiple Android devices
- [ ] All features working

#### Release Build (Production)
```bash
# 1. Generate keystore (first time only)
keytool -genkey -v -keystore pharmacy-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pharmacy

# 2. Create key.properties in android/
# Add to android/key.properties:
storePassword=<password>
keyPassword=<password>
keyAlias=pharmacy
storeFile=../pharmacy-key.jks

# 3. Build release APK
flutter build apk --release

# Or build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

- [ ] Release keystore created and backed up
- [ ] `key.properties` configured
- [ ] Release build successful
- [ ] APK/AAB tested on physical devices
- [ ] File located at: `build/app/outputs/flutter-apk/app-release.apk`

#### Google Play Store Deployment

- [ ] Google Play Developer account created ($25 one-time fee)
- [ ] App listing created
  - [ ] App name and description
  - [ ] Screenshots (at least 2 per form factor)
  - [ ] App icon (512x512 PNG)
  - [ ] Feature graphic (1024x500 PNG)
  - [ ] Privacy policy URL
- [ ] Content rating questionnaire completed
- [ ] Target audience selected
- [ ] Pricing and distribution set
- [ ] App bundle uploaded: `build/app/outputs/bundle/release/app-release.aab`
- [ ] Internal testing track configured
- [ ] Beta testing completed
- [ ] Production release submitted for review

### iOS Build

#### Prerequisites
- [ ] Apple Developer account ($99/year)
- [ ] Xcode installed (Mac required)
- [ ] Provisioning profile created
- [ ] App ID registered

#### Release Build
```bash
# 1. Open Xcode
open ios/Runner.xcworkspace

# 2. Configure signing in Xcode
# Select Runner > Signing & Capabilities
# Enable "Automatically manage signing"
# Select your Team

# 3. Build release IPA
flutter build ipa --release
```

- [ ] Code signing configured
- [ ] Release build successful
- [ ] IPA tested on physical iOS device
- [ ] File located at: `build/ios/ipa/pharmacy_app.ipa`

#### App Store Deployment

- [ ] App Store Connect listing created
  - [ ] App name and subtitle
  - [ ] Description and keywords
  - [ ] Screenshots (required sizes)
  - [ ] App icon (1024x1024 PNG)
  - [ ] Privacy policy URL
  - [ ] Support URL
- [ ] Pricing and availability set
- [ ] Age rating completed
- [ ] IPA uploaded via Xcode or Transporter
- [ ] Test Flight testing completed
- [ ] App review information provided
- [ ] Submitted for App Store review

### Post-Deployment

- [ ] **Verification**
  - [ ] App connects to production backend
  - [ ] Test user registration and login
  - [ ] Test product browsing and ordering
  - [ ] Test prescription upload
  - [ ] Verify payment flow (if implemented)

- [ ] **Monitoring**
  - [ ] Firebase Crashlytics configured
  - [ ] Google Analytics or similar enabled
  - [ ] App performance monitoring
  - [ ] User feedback mechanism

- [ ] **Distribution**
  - [ ] App published on Google Play Store
  - [ ] App published on Apple App Store
  - [ ] Direct APK download link (if needed)
  - [ ] Beta testing group set up

---

## Environment Configuration Reference

### Development
```dart
// lib/config/app_config.dart
static BackendEnvironment current = BackendEnvironment.local;
```

### Staging (Optional)
```dart
static BackendEnvironment current = BackendEnvironment.custom;
// In custom case:
return 'https://staging-api.example.com';
```

### Production
```dart
static BackendEnvironment current = BackendEnvironment.production;
// In production case:
return 'https://pharmacy-api.vercel.app'; // Your deployed backend URL
```

---

## Rollback Plan

If production deployment fails:

### Backend Rollback
**Vercel:**
```bash
# View deployments
vercel list

# Rollback to previous
vercel rollback <deployment-url>
```

**Heroku:**
```bash
# View releases
heroku releases

# Rollback to previous
heroku rollback
```

### Flutter App Rollback
**Google Play:**
- Go to Play Console > Release Management
- Activate previous version
- Deactivate problematic version

**App Store:**
- Go to App Store Connect
- Select previous version
- Remove current version from sale

---

## Security Best Practices

### Backend
- [ ] Use HTTPS only (no HTTP in production)
- [ ] Implement rate limiting on API endpoints
- [ ] Validate and sanitize all user inputs
- [ ] Use parameterized queries (Prisma handles this)
- [ ] Set secure headers (helmet.js or Next.js config)
- [ ] Implement proper CORS policy
- [ ] Use strong JWT secrets
- [ ] Hash passwords with bcrypt (salt rounds >= 10)
- [ ] Implement request logging
- [ ] Set up Web Application Firewall (WAF)

### Flutter App
- [ ] Use HTTPS for all API calls
- [ ] Never store sensitive data in SharedPreferences unencrypted
- [ ] Use flutter_secure_storage for tokens
- [ ] Implement certificate pinning (optional, advanced)
- [ ] Obfuscate code in release builds
- [ ] Disable debug logging in production
- [ ] Validate server responses before using
- [ ] Implement timeout on all network requests

---

## Performance Optimization

### Backend
- [ ] Enable Prisma connection pooling
- [ ] Add database indexes on frequently queried fields
- [ ] Implement API response caching
- [ ] Use CDN for static assets
- [ ] Optimize database queries (use `select` to limit fields)
- [ ] Implement pagination for large datasets
- [ ] Enable gzip compression

### Flutter App
- [ ] Implement image caching (cached_network_image)
- [ ] Use lazy loading for lists
- [ ] Optimize asset sizes
- [ ] Use const constructors where possible
- [ ] Profile app performance with Flutter DevTools
- [ ] Implement pagination in product lists
- [ ] Cache API responses locally

---

## Launch Day Checklist

**24 Hours Before:**
- [ ] Final testing on production environment
- [ ] Notify team of deployment window
- [ ] Prepare rollback plan
- [ ] Backup production database

**Deployment Day:**
- [ ] Deploy backend first
- [ ] Verify backend health check
- [ ] Test critical API endpoints
- [ ] Deploy Flutter app (or submit for review)
- [ ] Monitor error logs for first hour
- [ ] Test user flows in production

**Post-Launch:**
- [ ] Monitor server metrics (CPU, memory, response times)
- [ ] Watch for error spikes
- [ ] Check user feedback
- [ ] Document any issues encountered
- [ ] Send launch announcement

---

## Maintenance Schedule

**Daily:**
- Check error logs
- Monitor uptime
- Review user feedback

**Weekly:**
- Review API usage statistics
- Check database performance
- Update dependencies (security patches)

**Monthly:**
- Full security audit
- Performance optimization review
- Backup verification
- Cost analysis

**Quarterly:**
- Major dependency updates
- Feature releases
- User survey
- Architecture review

---

## Support Resources

- **Backend Issues:** [Backend Troubleshooting](./backend/docs/TROUBLESHOOTING.md)
- **Flutter Configuration:** [Backend Configuration Guide](./docs/BACKEND_CONFIGURATION.md)
- **Next.js Deployment:** https://nextjs.org/docs/deployment
- **Flutter Deployment:** https://docs.flutter.dev/deployment
- **Vercel Docs:** https://vercel.com/docs
- **Google Play Console:** https://play.google.com/console
- **App Store Connect:** https://appstoreconnect.apple.com
