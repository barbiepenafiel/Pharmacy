# Pharmacy App

A beautiful and modern Flutter mobile application for an online pharmacy. The app features a clean, user-friendly interface with product browsing, categories, promotions, and user profile management.

## Features

✅ **Home Screen**
- User greeting with profile section
- Promotional banner with discount offer
- Popular product categories (Medicine, Devices, Skin Care, Wellness)
- New products showcase
- Scrollable category and product lists

✅ **User Profile Screen**
- User profile information
- Profile menu with options for:
  - My Orders
  - Prescriptions
  - Saved Addresses
  - Payment Methods
  - Settings
  - Help & Support
- Logout functionality

✅ **Navigation**
- Bottom navigation bar with Home, Orders, and Account tabs
- Smooth screen transitions

## Design

- **Color Scheme**: Teal primary color with warm accent colors
- **Material Design 3**: Modern Material Design implementation
- **Responsive Layout**: Works across different screen sizes
- **Icons**: Comprehensive Material Icons usage

## Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Dart SDK
- iOS or Android development environment

### Installation

1. Navigate to the project directory:
```bash
cd c:\src\Pharmacy
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart           # Main app entry point with all screens
    ├── PharmacyApp    # Root widget
    ├── HomePage       # Main navigation hub
    ├── HomeScreen     # Products and categories display
    └── ProfileScreen  # User profile screen
```

## Running Tests

Run widget tests with:
```bash
flutter test
```

## Building for Release

### Android
```bash
flutter build apk
```

### iOS
```bash
flutter build ios
```

## Customization

You can easily customize:
- **Colors**: Change the primary color in `PharmacyApp` theme
- **Product Data**: Modify the product lists in `HomeScreen`
- **User Info**: Update the user details in the header and profile screens
- **Categories**: Add or remove categories from the `_buildCategoryItem` widgets

## Future Enhancements

- Product detail pages
- Shopping cart functionality
- Checkout and payment integration
- Order history
- Product search and filters
- User authentication
- Prescription upload feature
- Reviews and ratings
- Wishlist functionality

## License

This project is open source and available under the MIT License.

## Support

For support and questions, please create an issue in the project repository.
