# Women Safety App

A comprehensive women safety application built with Flutter (mobile) and Node.js (backend) that provides real-time location tracking, SOS alerts, and emergency communication features.

## 🚀 Features

### Mobile App (Flutter)
- **Real-time Location Tracking**: GPS-based location sharing with family/guardians
- **SOS Emergency Alerts**: Quick emergency button with instant notifications
- **Audio Recording**: Voice message recording and sharing capabilities
- **Google Maps Integration**: Interactive maps with route planning
- **Secure Authentication**: JWT-based user authentication
- **Real-time Communication**: Socket.io integration for instant messaging
- **Emergency Contacts**: Quick dial emergency contacts
- **Offline Support**: Local storage for critical data

### Backend (Node.js)
- **RESTful API**: Complete API for user management and safety features
- **Real-time Socket Communication**: WebSocket support for live updates
- **MongoDB Database**: Secure data storage with Mongoose ODM
- **AWS S3 Integration**: File storage for audio recordings and media
- **Twilio Integration**: SMS notifications for emergency alerts
- **Redis Caching**: Performance optimization with Redis
- **JWT Authentication**: Secure token-based authentication
- **File Upload Support**: Multer integration for media uploads

## 🏗️ Project Structure

```
├── Backend/                    # Node.js Express Server
│   ├── src/
│   │   ├── config/            # Database and service configurations
│   │   ├── controllers/       # API route controllers
│   │   ├── middleware/        # Authentication and upload middleware
│   │   ├── models/           # MongoDB data models
│   │   ├── routes/           # API route definitions
│   │   └── services/         # External service integrations
│   ├── server.js             # Main server entry point
│   └── package.json          # Backend dependencies
│
└── women_safety_user/         # Flutter Mobile Application
    ├── lib/
    │   ├── src/
    │   │   ├── models/       # Data models
    │   │   ├── providers/    # State management
    │   │   ├── screens/      # UI screens
    │   │   ├── services/     # API and external services
    │   │   ├── utils/        # Utility functions
    │   │   └── widgets/      # Reusable UI components
    │   └── main.dart         # App entry point
    └── pubspec.yaml          # Flutter dependencies
```

## 🛠️ Technology Stack

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose ODM
- **Real-time**: Socket.io
- **Authentication**: JWT (jsonwebtoken)
- **SMS Service**: Twilio
- **Caching**: Redis (ioredis)
- **Security**: bcrypt for password hashing

### Mobile App
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Maps**: Google Maps Flutter
- **Location**: Geolocator & Location packages
- **Real-time**: Socket.io Client
- **Storage**: Flutter Secure Storage & Shared Preferences
- **Audio**: Flutter Sound, Record, Audioplayers
- **HTTP**: Dio & HTTP packages
- **UI**: Material Design with Google Fonts

## 📋 Prerequisites

### Backend Requirements
- Node.js (v14 or higher)
- MongoDB (local or cloud instance)
- Redis server
- AWS S3 account (for file storage)
- Twilio account (for SMS services)

### Mobile App Requirements
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / Xcode for mobile development


## 🚀 Installation & Setup

### Backend Setup

1. Navigate to the backend directory:
```bash
cd Backend
```

2. Install dependencies:
```bash
npm install
```

3. Create environment file:
```bash
cp .env.example .env
```

4. Configure environment variables in `.env`:
```env
PORT=5000
MONGO_URI=mongodb://localhost:27017/women_safety
JWT_SECRET=your_jwt_secret_key
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=your_twilio_phone_number
FRONTEND_URL=http://localhost:3000
```

5. Start the server:
```bash
npm start
```

### Mobile App Setup

1. Navigate to the Flutter app directory:
```bash
cd women_safety_user
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Configure Google Maps API:
   - Add your Google Maps API key to `android/app/src/main/AndroidManifest.xml`
   - Add your API key to `ios/Runner/AppDelegate.swift`

4. Run the app:
```bash
flutter run
```

## 🔧 Configuration

### Google Maps Setup
1. Enable Google Maps SDK for Android/iOS in Google Cloud Console
2. Create API credentials and restrict them appropriately
3. Add the API key to your platform-specific configuration files

### AWS S3 Setup
1. Create an S3 bucket for file storage
2. Configure IAM user with appropriate S3 permissions
3. Add credentials to backend environment variables

### Twilio Setup
1. Create a Twilio account and get Account SID and Auth Token
2. Purchase a phone number for SMS services
3. Configure webhook URLs for message handling

## 📱 API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh` - Refresh JWT token

### User Management
- `GET /api/user/profile` - Get user profile
- `PUT /api/user/profile` - Update user profile
- `POST /api/user/upload-avatar` - Upload profile picture

### Location Services
- `POST /api/location/update` - Update user location
- `GET /api/location/history` - Get location history
- `GET /api/location/current/:userId` - Get current location

### SOS Services
- `POST /api/sos/alert` - Send SOS alert
- `GET /api/sos/history` - Get SOS history
- `POST /api/sos/audio` - Upload audio recording

## 🔐 Security Features

- JWT-based authentication with refresh tokens
- Password hashing using bcrypt
- Input validation and sanitization
- CORS configuration for cross-origin requests
- Secure file upload with type validation
- Rate limiting for API endpoints

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the ISC License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the GitHub repository
- Contact the development team

## 🔄 Version History

- **v1.0.0** - Initial release with core safety features
  - Real-time location tracking
  - SOS alert system
  - Audio recording capabilities
  - User authentication and profile management

---

**Note**: This application is designed for safety purposes. Always ensure you have proper permissions and follow local laws regarding location tracking and emergency services.