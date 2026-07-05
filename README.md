# 🚑 ATS - Ambulance Traffic System

An intelligent Ambulance Traffic System designed to reduce ambulance response time by providing real-time ambulance tracking, secure authentication, and communication between ambulance drivers and traffic police.

The project consists of a **Spring Boot REST API backend** and a **Flutter mobile application** with real-time updates using WebSockets.

---

## 📌 Features

### 🔐 Authentication
- JWT Authentication
- Role-based Authorization
- User Registration & Login
- Secure Password Encryption

### 🚑 Ambulance Module
- Register Ambulance
- Update Live Location
- Track Ambulance
- Ambulance Status Management

### 🚓 Traffic Police Module
- View Nearby Ambulances
- Receive Traffic Alerts
- Monitor Live Ambulance Locations

### 🗺 Maps & Navigation
- Google Maps Integration
- Route Calculation
- Real-time Location Tracking

### ⚡ Real-Time Communication
- WebSocket (STOMP)
- Instant Traffic Alerts
- Live Location Updates

---

# 🛠 Tech Stack

## Backend

- Java 21
- Spring Boot
- Spring Security
- Spring Data MongoDB
- JWT Authentication
- WebSocket (STOMP)
- Maven

## Frontend

- Flutter
- Dart
- Google Maps Flutter
- WebSocket Client

## Database

- MongoDB Atlas

---

# 📁 Project Structure

```
ATS
│
├── Backend (Spring Boot)
│   ├── controller
│   ├── service
│   ├── repository
│   ├── model
│   ├── dto
│   ├── config
│   └── resources
│
├── Frontend (Flutter)
│   ├── lib
│   ├── assets
│   ├── android
│   └── pubspec.yaml
│
└── README.md
```

---

# ⚙ Backend Setup

## Clone Repository

```bash
git clone https://github.com/PavanBobade01/ATS_01.git
```

Move into project

```bash
cd ATS_01
```

Install dependencies

```bash
mvn clean install
```

Run

```bash
mvn spring-boot:run
```

---

# 📱 Flutter Setup

Move to Flutter project

```bash
flutter pub get
```

Run

```bash
flutter run
```

---

# 🔑 Environment Configuration

Create

```
application-local.properties
```

Example

```properties
spring.data.mongodb.uri=YOUR_MONGODB_URI

jwt.secret.key=YOUR_SECRET_KEY

google.maps.api.key=YOUR_GOOGLE_MAPS_API_KEY
```

Never commit this file.

---

# 🔒 Security

Sensitive information is excluded from GitHub.

Examples include:

- MongoDB URI
- JWT Secret
- Google Maps API Key
- Secret Keys

---

# 📡 API Modules

### Authentication

- Register User
- Login User

### Ambulance

- Register Ambulance
- Update Location
- Get Ambulance Details

### Traffic

- Send Traffic Alert
- Receive Live Updates

### Location

- Update GPS Coordinates
- Calculate Route



# 🚀 Future Enhancements

- Push Notifications
- SOS Button
- AI-based Route Optimization
- Hospital Integration
- Admin Dashboard
- Kubernetes Deployment
- Docker Support
- CI/CD Pipeline
- AWS Deployment


# 👨‍💻 Author

**Pavan Bobade**

Java Backend Developer

LinkedIn:
https://www.linkedin.com/in/pavanbobade01

GitHub:
https://github.com/PavanBobade01

---

# ⭐ Support

If you found this project helpful, consider giving it a ⭐ on GitHub.
