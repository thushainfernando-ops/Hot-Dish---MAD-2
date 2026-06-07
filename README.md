# Hot Dish Mobile App

An authentic Sri Lankan cuisine food delivery app built with Flutter.

## Features

- **User Authentication**: Secure login and registration with Firebase
- **Menu Browsing**: Browse menu items by category with detailed product information
- **Shopping Cart**: Add items to cart, update quantities, and manage orders
- **Order Management**: Place orders with delivery information and payment details
- **Offline Support**: App works offline with local caching of menu and user data
- **User Profile**: Manage profile information, favorites, and order history
- **Location Services**: Get current location and calculate delivery estimates
- **Dark Mode**: Full support for light and dark themes
- **Contact Support**: Get in touch with the restaurant team

## Prerequisites

- Flutter SDK (3.29.x or higher)
- Android SDK with emulator or a connected device
- `google-services.json` for Firebase (place in `android/app/`)

## Setup & Installation

```bash
flutter pub get
flutter run
```

## Screens

1. **Home**: Welcome screen with restaurant information and testimonials
2. **Menu**: Browse all menu items with category filtering and search
3. **Cart**: View and manage items in your cart
4. **Contact**: Send messages to the restaurant
5. **Profile**: View profile, favorites, order history, and device information

## Testing

```bash
flutter analyze    # Check for lint issues
flutter test       # Run unit and widget tests
```

