# Pharmacy App# Pharmacy App



A beautiful and modern Flutter mobile application for an online pharmacy powered by **Firebase**. The app features a clean, user-friendly interface with real-time product browsing, shopping cart, prescription management, and a comprehensive admin dashboard.A beautiful and modern Flutter mobile application for an online pharmacy with a Next.js backend API. The app features a clean, user-friendly interface with product browsing, shopping cart, prescription management, and admin dashboard.



## 🎉 Architecture: 100% Firebase## Features



This app uses **Firebase Realtime Database**, **Firebase Authentication**, and **Firebase Storage** for a completely serverless, real-time backend. No Node.js server required!### 🛍️ Customer Features

- **Product Browsing**: Browse products by category with search and barcode scanning

## Features- **Shopping Cart**: Add products, manage quantities, and checkout

- **Prescription Upload**: Upload and track prescription orders

### 🛍️ Customer Features- **Order History**: View past orders with detailed tracking

- **Real-time Product Browsing**: Browse products by category with instant updates- **User Authentication**: Secure login and registration

- **Barcode Scanner**: Scan product barcodes for quick lookup- **Profile Management**: Update personal information and settings

- **Shopping Cart**: Add products, manage quantities, and checkout

- **Prescription Upload**: Upload prescriptions to Firebase Storage### 👨‍💼 Admin Features

- **Order Tracking**: View order status with real-time updates- **Admin Dashboard**: Overview of sales, orders, and inventory

- **User Authentication**: Secure Firebase Authentication (email/password)- **Product Management**: Add, edit, and delete products

- **Profile Management**: Update personal information and settings- **Order Management**: Process and track customer orders

- **Offline Support**: 10MB local cache for offline functionality- **User Management**: View and manage customer accounts

- **Inventory Control**: Monitor stock levels and low inventory alerts

### 👨‍💼 Admin Features- **Prescription Review**: Approve or reject prescription orders

- **Real-time Dashboard**: Live statistics (sales, orders, users, prescriptions)

- **Product Management**: CRUD operations with instant sync### 🎨 UI/UX

- **Order Management**: Process orders with real-time status updates- **Material Design 3**: Modern, clean interface

- **User Management**: View and manage customer accounts- **Responsive Layout**: Optimized for all screen sizes

- **Prescription Review**: Approve/reject prescriptions with live notifications- **Theme Support**: Light mode with teal accent colors

- **Inventory Monitoring**: Real-time stock level tracking- **Smooth Navigation**: Bottom navigation with intuitive flow



### 🎨 UI/UX## Tech Stack

- **Material Design 3**: Modern, clean interface

- **Responsive Layout**: Optimized for all screen sizes### Frontend (Flutter)

- **Theme Support**: Light mode with teal accent colors- **Flutter 3.9.2**: Cross-platform mobile framework

- **Smooth Navigation**: Bottom navigation with intuitive flow- **Dart**: Programming language

- **Real-time Updates**: Live data sync across all screens- **http**: RESTful API communication

- **Material Design 3**: UI components

## Tech Stack

### Backend (Next.js)

### Frontend- **Next.js 16.0.3**: React-based API framework

- **Flutter 3.9.2+**: Cross-platform mobile framework- **TypeScript**: Type-safe development

- **Dart**: Programming language- **Prisma 6.19.0**: Database ORM

- **Material Design 3**: UI components- **PostgreSQL (Neon)**: Cloud-hosted database

- **bcrypt**: Password hashing

### Backend (Firebase)- **JWT**: Authentication tokens

- **Firebase Realtime Database**: Real-time NoSQL database

- **Firebase Authentication**: User authentication and authorization## Quick Start

- **Firebase Storage**: Prescription image storage

- **Firebase Security Rules**: Data access control### 1. Backend Setup



### Key PackagesNavigate to backend directory:

- `firebase_core`: Firebase SDK initialization```bash

- `firebase_database`: Real-time database operationscd backend

- `firebase_auth`: Authentication services```

- `firebase_storage`: File upload/download

- `image_picker`: Prescription photo captureInstall dependencies:

- `mobile_scanner`: Barcode scanning```bash

- `camera`: Camera access for prescriptionsnpm install

```

## Quick Start

Create `.env` file with database credentials:

### Prerequisites```env

DATABASE_URL="postgresql://user:password@host.neon.tech/db?sslmode=require&channel_binding=require"

1. **Flutter SDK** (3.9.2 or higher)DIRECT_DATABASE_URL="postgresql://user:password@host.neon.tech/db?sslmode=require"

   ```bashNODE_ENV="development"

   flutter --version```

   ```

Generate Prisma client and start server:

2. **Firebase Project** (already configured)```bash

   - Project: `pharmacy-app-67eab`npx prisma generate

   - Region: `asia-southeast1`npm run dev

   - Database URL: `https://pharmacy-app-67eab-default-rtdb.asia-southeast1.firebasedatabase.app/````



### Installation**📖 Full backend setup guide:** [backend/README.md](backend/README.md)



1. **Clone the repository**:### 2. Flutter App Setup

   ```bash

   git clone <repository-url>Install Flutter dependencies:

   cd Pharmacy```bash

   ```flutter pub get

```

2. **Install Flutter dependencies**:

   ```bashConfigure backend URL in `lib/config/app_config.dart`:

   flutter pub get```dart

   ```// Find your computer's IP address

// Windows: ipconfig

3. **Run the app**:// Mac/Linux: ifconfig

   ```bash

   flutter runstatic BackendEnvironment current = BackendEnvironment.local;

   ```

case BackendEnvironment.local:

That's it! The app is pre-configured with Firebase credentials.  return 'http://YOUR_LOCAL_IP:3000'; // Replace with your IP

```

### Firebase Configuration

Run the app:

The app is already configured with Firebase. The configuration files are:```bash

flutter run

- **Android**: `android/app/google-services.json````

- **iOS**: `ios/Runner/GoogleService-Info.plist`

- **Web**: `web/index.html` (Firebase JS SDK)**📖 Full configuration guide:** [docs/BACKEND_CONFIGURATION.md](docs/BACKEND_CONFIGURATION.md)



**No additional Firebase setup required!** The app connects automatically.## Documentation



## Project Structure### Setup & Configuration

- **[Backend Setup Guide](backend/README.md)** - Complete backend installation and API documentation

```- **[Backend Configuration](docs/BACKEND_CONFIGURATION.md)** - Flutter app backend URL configuration

Pharmacy/- **[Troubleshooting Guide](backend/docs/TROUBLESHOOTING.md)** - Common issues and solutions

├── lib/                        # Flutter application code

│   ├── main.dart              # App entry point### Development

│   ├── models/                # Data models- **[OpenSpec Project Overview](openspec/project.md)** - Project architecture and conventions

│   │   └── user.dart         # User model- **[Recent Changes](openspec/changes/fix-product-fetching-and-connectivity/)** - Latest implementation details

│   ├── screens/               # UI screens

│   │   ├── login_screen.dart### Deployment

│   │   ├── products_screen.dart- **[Deployment Checklist](docs/DEPLOYMENT_CHECKLIST.md)** - Production deployment guide

│   │   ├── cart_screen.dart- **[Production Setup](PRODUCTION_SETUP.md)** - Production environment configuration

│   │   ├── admin_dashboard_screen.dart

│   │   ├── prescriptions_screen.dart## Project Structure

│   │   └── ...

│   └── services/              # Firebase services```

│       ├── auth_service.dart        # AuthenticationPharmacy/

│       └── firebase_service.dart    # Database & Storage├── lib/                        # Flutter application code

││   ├── main.dart              # App entry point

├── assets/                    # Images and resources│   ├── config/                # Configuration files

│   └── images/│   │   └── app_config.dart   # Backend URL configuration

││   ├── models/                # Data models (User, Product, Order, etc.)

├── android/                   # Android platform files│   ├── screens/               # UI screens

│   └── app/│   │   ├── home_screen.dart

│       └── google-services.json  # Firebase Android config│   │   ├── products_screen.dart

││   │   ├── cart_screen.dart

├── ios/                       # iOS platform files│   │   ├── admin_dashboard_screen.dart

│   └── Runner/│   │   └── ...

│       └── GoogleService-Info.plist  # Firebase iOS config│   └── services/              # API services

││       ├── auth_service.dart

├── firebase-database-rules.json  # Database security rules│       └── ...

││

└── docs/                      # Documentation├── backend/                   # Next.js backend API

    └── ...│   ├── prisma/               # Database schema and migrations

```│   │   └── schema.prisma

│   ├── src/

## Firebase Data Structure│   │   ├── app/api/          # API routes

│   │   │   ├── health/       # Health check endpoint

```│   │   │   ├── products/     # Product CRUD

pharmacy-app-67eab-default-rtdb/│   │   │   ├── orders/       # Order management

├── users/│   │   │   ├── auth/         # Authentication

│   └── {userId}/│   │   │   └── ...

│       ├── id│   │   └── lib/              # Shared utilities

│       ├── email│   │       └── prisma.ts     # Database client

│       ├── fullName│   └── docs/

│       ├── role (customer/admin)│       └── TROUBLESHOOTING.md

│       ├── createdAt│

│       └── active├── docs/                      # Documentation

├── products/│   ├── BACKEND_CONFIGURATION.md

│   └── {productId}/│   └── DEPLOYMENT_CHECKLIST.md

│       ├── id│

│       ├── name└── openspec/                  # OpenSpec proposals and tracking

│       ├── description    ├── project.md

│       ├── dosage    └── changes/

│       ├── category```

│       ├── price

│       ├── imageUrl## API Endpoints

│       ├── quantity

│       ├── supplier### Health & Status

│       └── active- `GET /api/health` - Check server and database status

├── orders/

│   └── {orderId}/### Authentication

│       ├── id- `POST /api/auth?action=login` - User login

│       ├── userId- `POST /api/auth?action=register` - User registration

│       ├── total

│       ├── status (pending/processing/shipped/delivered/cancelled)### Products

│       ├── deliveryAddress- `GET /api/products` - List all products

│       ├── items[] (array of order items)- `POST /api/products` - Create product (admin)

│       └── createdAt- `GET /api/products/[id]` - Get single product

├── prescriptions/- `PUT /api/products/[id]` - Update product (admin)

│   └── {prescriptionId}/- `DELETE /api/products/[id]` - Delete product (admin)

│       ├── id

│       ├── userId### Orders

│       ├── doctorName- `GET /api/orders` - List orders

│       ├── medication- `POST /api/orders` - Create order

│       ├── status (pending/approved/rejected)- `GET /api/orders/[id]` - Get order details

│       ├── imageUrl (Firebase Storage path)- `PUT /api/orders/[id]` - Update order status

│       └── createdAt

├── addresses/### Prescriptions

│   └── {addressId}/- `GET /api/prescriptions` - List prescriptions

│       ├── userId- `POST /api/prescriptions` - Upload prescription

│       ├── street, city, state, zip, country- `PUT /api/prescriptions/[id]` - Update status (admin)

│       └── isDefault

└── paymentMethods/**📖 Full API documentation:** [backend/README.md#api-endpoints](backend/README.md#api-endpoints)

    └── {paymentMethodId}/

        ├── userId## Configuration

        ├── type

        └── details### Backend URL Environments

```

The app supports four backend environments:

## Authentication

1. **Local Network** (same WiFi)

### Firebase Authentication Setup   ```dart

   static BackendEnvironment current = BackendEnvironment.local;

The app uses **Firebase Authentication** with email/password provider.   ```



**Default Admin Account**:2. **Ngrok Tunnel** (external access)

- **Email**: `admin@pharmacy.com`   ```bash

- **Password**: `Admin123!`   ngrok http 3000

   ```

**Creating New Users**:   ```dart

1. Open the app   static BackendEnvironment current = BackendEnvironment.ngrok;

2. Click "Sign Up" on login screen   ```

3. Enter email, name, and password

4. Account is created automatically3. **Production** (deployed backend)

   ```dart

**Admin Privileges**:   static BackendEnvironment current = BackendEnvironment.production;

- Admin users have custom claim: `{ admin: true }`   ```

- Set via Firebase Console → Authentication → Users → Edit user → Custom claims

4. **Custom** (temporary URL)

## Firebase Security Rules   ```dart

   static BackendEnvironment current = BackendEnvironment.custom;

Security rules are defined in `firebase-database-rules.json`:   ```



### Key Rules:**📖 Full configuration guide:** [docs/BACKEND_CONFIGURATION.md](docs/BACKEND_CONFIGURATION.md)

- **Authentication Required**: All operations require login

- **Admin Access**: Admins can read/write all data## Testing

- **User Data**: Users can only read/write their own data

- **Product Access**: Customers can read products, admins can modify### Backend Tests

- **Order Security**: Users can only see their own orders```bash

- **Prescription Privacy**: Users can only access their own prescriptionscd backend

npm test

**Deploying Rules**:```

```bash

# Install Firebase CLI### Flutter Tests

npm install -g firebase-tools```bash

flutter test

# Login```

firebase login

### Manual Testing

# Deploy rules```bash

firebase deploy --only database:rules# Test backend health

```curl http://localhost:3000/api/health



## Real-time Features# Or in PowerShell

Invoke-RestMethod http://localhost:3000/api/health

### Real-time Sync```

The app uses Firebase Realtime Database streams for instant updates:

## Building for Release

- **Product List**: Auto-updates when products are added/edited/deleted

- **Order Status**: Live order tracking### Android APK

- **Admin Dashboard**: Real-time statistics```bash

- **Cart Sync**: (Future) Sync cart across devicesflutter build apk --release

- **Prescription Status**: Live approval notifications```



### Offline Support### Android App Bundle (Google Play)

- **10MB Local Cache**: Firebase persistence enabled```bash

- **Offline Reads**: Access cached data without internetflutter build appbundle --release

- **Automatic Sync**: Changes sync when connection restored```



## Development### iOS

```bash

### Running the Appflutter build ipa --release

```

**Development Mode**:

```bash**📖 Full deployment guide:** [docs/DEPLOYMENT_CHECKLIST.md](docs/DEPLOYMENT_CHECKLIST.md)

flutter run

```## Troubleshooting



**Hot Reload**: Press `r` in terminal to hot reload  ### Backend Not Accessible

**Hot Restart**: Press `R` in terminal to hot restart  - Verify server is running: `npm run dev`

**Quit**: Press `q` to quit- Check health endpoint: `curl http://localhost:3000/api/health`

- Ensure firewall allows port 3000

### Debugging- Use correct local IP (not 127.0.0.1 or localhost)



**Flutter DevTools**:### Flutter App Can't Connect

```bash- Update IP in `lib/config/app_config.dart`

flutter pub global activate devtools- Ensure device on same WiFi network

flutter pub global run devtools- Rebuild app after config changes: `flutter run`

```

### Database Connection Errors

**Firebase Console**:- Verify `DATABASE_URL` in `.env` file

- View data: https://console.firebase.google.com/- Check Neon database status

- Monitor auth: Authentication → Users- Ensure SSL parameters in connection string

- Check database: Realtime Database → Data

- View storage: Storage → Files**📖 Complete troubleshooting guide:** [backend/docs/TROUBLESHOOTING.md](backend/docs/TROUBLESHOOTING.md)



### Adding Test Data## Default Admin Credentials



**Via Firebase Console**:**Email:** `admin@pharmacy.com`  

1. Go to Realtime Database**Password:** `admin123`

2. Click on node (e.g., `products`)

3. Click `+` to add child⚠️ **Change these credentials before production deployment!**

4. Enter data and save

## Development Workflow

**Via Admin Dashboard**:

1. Login as admin1. Start backend server: `cd backend && npm run dev`

2. Go to Admin Dashboard2. Configure Flutter app: Update `lib/config/app_config.dart`

3. Add products, manage users, etc.3. Run Flutter app: `flutter run`

4. Make changes and hot reload with `r` key

## Building for Release5. Test on physical device for full network testing



### Android## Contributing



**APK (for testing)**:1. Follow OpenSpec proposal process for major changes

```bash2. Update documentation for new features

flutter build apk --release3. Write tests for new functionality

```4. Follow existing code style and conventions

Output: `build/app/outputs/flutter-apk/app-release.apk`

## Recent Updates

**App Bundle (for Google Play)**:

```bash### November 2024: Database Connectivity & Network Fix

flutter build appbundle --release- ✅ Fixed product fetching from Neon database

```- ✅ Configured backend for external device access

Output: `build/app/outputs/bundle/release/app-release.aab`- ✅ Centralized backend URL configuration

- ✅ Added retry logic with exponential backoff

### iOS- ✅ Enhanced error handling and user feedback

- ✅ Comprehensive documentation

```bash

flutter build ipa --release**📖 Implementation details:** [openspec/changes/fix-product-fetching-and-connectivity/](openspec/changes/fix-product-fetching-and-connectivity/)

```

Output: `build/ios/ipa/`## License



### Configuration for ReleaseThis project is open source and available under the MIT License.



1. **Update `pubspec.yaml` version**:## Support

   ```yaml

   version: 1.0.0+1  # Change as needed- **Issues:** Create an issue in the project repository

   ```- **Documentation:** Check the [docs/](docs/) directory

- **Troubleshooting:** See [backend/docs/TROUBLESHOOTING.md](backend/docs/TROUBLESHOOTING.md)

2. **Generate app icons** (if changed):
   ```bash
   flutter pub run flutter_launcher_icons
   ```

3. **Update Firebase config** for production (if different)

## Testing

### Run Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

### Integration Tests
```bash
flutter test integration_test/
```

## Troubleshooting

### Firebase Connection Issues

**Problem**: App can't connect to Firebase

**Solutions**:
1. Check internet connection
2. Verify Firebase project is active
3. Check Firebase Console for service status
4. Ensure `google-services.json` is in `android/app/`
5. Run `flutter clean` and rebuild

### Authentication Errors

**Problem**: Login/signup fails

**Solutions**:
1. Check Firebase Console → Authentication → Sign-in method
2. Ensure Email/Password provider is enabled
3. Check user credentials are correct
4. Look for error messages in console

### Image Upload Failures

**Problem**: Prescription images won't upload

**Solutions**:
1. Check Firebase Storage rules allow authenticated uploads
2. Verify storage bucket name is correct
3. Check device permissions for camera/gallery
4. Check file size (limit: 5MB per file)

### Offline Mode Issues

**Problem**: Data not syncing when back online

**Solutions**:
1. Check Firebase persistence is enabled (it is by default)
2. Restart the app
3. Check network connectivity
4. Clear app cache if needed

### "Permission Denied" Errors

**Problem**: Database operations fail with permission errors

**Solutions**:
1. Check Firebase Security Rules
2. Ensure user is authenticated
3. Verify user has correct role (admin vs customer)
4. Check custom claims for admin users

## Performance Optimization

### Database Optimization
- **Indexes**: Firebase auto-indexes, but add custom indexes if needed
- **Query Limits**: Use `limitToFirst()` and `limitToLast()` for large datasets
- **Offline Persistence**: Enabled by default (10MB cache)

### Image Optimization
- **Max Upload Size**: 5MB per prescription image
- **Compression**: Images auto-compressed before upload
- **Caching**: Firebase Storage caches images locally

### App Performance
- **Build Size**: ~50MB (Android APK)
- **Memory Usage**: ~150MB average
- **Startup Time**: ~2 seconds cold start

## Firebase Costs

### Free Tier Limits (Spark Plan)
- **Realtime Database**: 1GB storage, 10GB/month download
- **Authentication**: Unlimited users
- **Storage**: 5GB total storage
- **Functions**: 125K invocations/month (if added later)

### Monitoring Usage
- Firebase Console → Usage and Billing
- Set up budget alerts
- Monitor in real-time

**Current Usage**: Well within free tier limits 🎉

## Deployment Checklist

### Pre-Deployment
- [ ] Update version in `pubspec.yaml`
- [ ] Test all features thoroughly
- [ ] Verify Firebase rules are secure
- [ ] Change default admin password
- [ ] Test offline functionality
- [ ] Build release version
- [ ] Test release build on physical device

### Post-Deployment
- [ ] Monitor Firebase Console for errors
- [ ] Check user feedback
- [ ] Monitor database usage
- [ ] Set up Firebase Analytics (optional)
- [ ] Configure crash reporting (optional)

## Advanced Features (Future Enhancements)

### Planned Features
- 🔔 **Push Notifications**: Firebase Cloud Messaging
- 📊 **Analytics**: Firebase Analytics integration
- 💳 **Payment Gateway**: Stripe/PayPal integration
- 🌐 **Multi-language**: i18n support
- 🌙 **Dark Mode**: Theme switching
- 📱 **Web Version**: Flutter web support
- 🤖 **Chatbot**: Customer support bot

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

### Documentation
- **Setup Guide**: This README
- **Firebase Docs**: https://firebase.google.com/docs
- **Flutter Docs**: https://docs.flutter.dev

### Getting Help
- **Issues**: Open an issue in the repository
- **Firebase Console**: https://console.firebase.google.com/
- **Flutter Community**: https://flutter.dev/community

## Acknowledgments

- **Firebase**: For the amazing backend-as-a-service
- **Flutter Team**: For the incredible framework
- **Material Design**: For the beautiful UI components

---

**Built with ❤️ using Flutter and Firebase**

Last Updated: November 26, 2025
