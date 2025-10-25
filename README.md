# 🏆 Sports Event Management Application

## 📖 Overview
The **Sports Event Management System** is a comprehensive web and mobile application designed to manage and display results of school and college sports tournaments — including **intramural, extramural, state, and all-India level games**.

It simplifies how event organizers **store, manage, and retrieve** sports data while allowing students and selection committees to easily **view results, participants, and scores** in a user-friendly way.

---

![WhatsApp Image 2025-09-29 at 16 00 36_f0cb3981](https://github.com/user-attachments/assets/ae88135a-9721-405c-8160-45aff9cf48e6)
![WhatsApp Image 2025-09-29 at 16 00 52_b05ffd3c](https://github.com/user-attachments/assets/b15b80be-ab0d-481b-b548-11a61c1e886d)
![WhatsApp Image 2025-09-29 at 16 01 02_83c27290](https://github.com/user-attachments/assets/c3418fc9-1c59-486f-9aa5-9d1356d78f6a)
![WhatsApp Image 2025-09-29 at 16 01 23_bea0134a](https://github.com/user-attachments/assets/48e75543-9444-470f-9300-e212fe1a42da)




## ⚙️ Tech Stack

| Component | Technology Used |
|------------|----------------|
| **Frontend** | Flutter |
| **Backend** | Django REST Framework |
| **Database** | MySQL |
| **Cloud Hosting** | AWS |
| **API Communication** | REST APIs |
| **Data Export** | Excel (via backend) |

---

## 🎯 Key Features

### 👩‍🎓 Student Portal
- View winners, runners, and participants for each event.  
- Filter results by game type and tournament level (Intramurals, Extramurals, State, All-India).  
- No authentication required — open access for students.

### 🧑‍💼 Selection Committee Dashboard
- Secure login for event organizers and committee members.  
- Insert, update, and manage sports data.  
- Upload event result images and certificates.  
- Export reports to Excel format.  
- Receive notifications when new data or results are added.

### 🏅 Event Management
- Manage multiple games: Volleyball, Kabaddi, Football, Athletics, and more.  
- Record winners, runners, scores, and participation data.  
- Generate event-wise and player-wise reports.  

---

## 🧩 System Architecture

```
Flutter App (Frontend)
        │
        ▼
Django REST API (Backend)
        │
        ▼
MySQL Database (Data Storage)
        │
        ▼
AWS Cloud Server (Deployment)
```

---

## 📱 Application Flow

1. **Organizers Login** → Add tournament details and upload results.  
2. **Students View** → Browse sports results, participants, and achievements.  
3. **Selection Committee** → Retrieve and analyze player data for selections.  
4. **Data Export** → Generate Excel reports for records and analysis.  

---

## 💻 Installation & Setup

### 🧱 Backend (Django)
1. Clone the repository:
   ```bash
   git clone https://github.com/<your-username>/sports-management-app.git
   cd sports-management-app/backend
   ```

2. Create a virtual environment and install dependencies:
   ```bash
   python -m venv env
   source env/bin/activate   # On Windows: env\Scripts\activate
   pip install -r requirements.txt
   ```

3. Run migrations:
   ```bash
   python manage.py migrate
   ```

4. Start the Django server:
   ```bash
   python manage.py runserver
   ```

---

### 📲 Frontend (Flutter)
1. Navigate to the Flutter project folder:
   ```bash
   cd sports-management-app/flutter_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

4. Update API URLs in the Flutter app to match your backend endpoint hosted on AWS.

---

## ☁️ Deployment
- **Backend** hosted on **AWS EC2 / AWS Lambda (optional)**.  
- **Database** hosted on **AWS RDS (MySQL)**.  
- **Media files** (event images/results) stored on **AWS S3 Bucket**.  
- **Frontend** deployed via **AWS Amplify or APK distribution**.

---

## 📊 Sample Data Format

| Event | Level | Game | Winner | Runner | Score |
|--------|--------|-------|---------|---------|--------|
| Intramural | Volleyball | Boys | Team A | Team B | 25–20 |
| State | Football | Girls | Team C | Team D | 2–1 |

---

## 🚀 Future Enhancements
- AI-based player performance analysis.  
- Real-time score updates via IoT sensors.  
- Chatbot integration for event queries.  
- Role-based access control for different user levels.  

---

## 📸 Screenshots (Optional)
_Add app screenshots or GIFs here once available._

---

## 👨‍💻 Contributors
| Name | Role | Description |
|------|------|-------------|
| S. Chandu | Developer & Project Lead | Full-stack development, architecture design, and backend integration. |

---

## 📄 License
This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.

