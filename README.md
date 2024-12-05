# Lightweight IoT Dashboard for Device Management

## 📖 Overview

This project is a **cheap and lightweight IoT dashboard** designed for customers to easily view and manage their devices and associated data. The dashboard displays device information, status, and collected data in a user-friendly way, making it simple for users to monitor their IoT ecosystem.

## 🚀 Features

- **Device Management**: View and manage IoT devices.
- **Data Visualization**: Display device data such as temperature, humidity, and more in a clean, intuitive interface.
- **Authentication**: Secure login and device association using Cognito.
- **Scalability**: Built on AWS services for cost-effective scalability and maintenance.

## 🛠️ Technologies Used

### AWS Services:
- **Amplify**: Simplifies the development workflow for frontend integration with AWS backend.
- **Lambda**: Handles serverless backend logic for API operations and data processing.
- **DynamoDB**: NoSQL database for storing device data and user associations.
- **Cognito**: Manages secure user authentication and authorization.
- **API Gateway**: Facilitates communication between frontend and backend services.
- **IAM**: Enforces security policies for AWS services.

### Frontend:
- **Flutter**: Cross-platform framework for creating a lightweight and responsive user interface.

## 📂 Project Structure

- **Frontend**: Built with Flutter, integrated with Amplify for seamless communication with AWS backend.
- **Backend**: Serverless architecture using AWS Lambda, DynamoDB, and API Gateway to handle device data and user management.
- **Authentication**: Cognito ensures secure and scalable user sign-in and sign-up flows.

## 🎯 Key Goals

1. **Cost Efficiency**: Minimize costs while leveraging AWS's robust infrastructure.
2. **Lightweight Design**: Ensure the application is easy to deploy and use without unnecessary complexity. (Was the idea, not really the case)
3. **Scalability**: Support growing numbers of devices and users without impacting performance and cost.

## 📈 Future Enhancements

- **Customizable Data Views**: Allow users to customize how device data is displayed on the dashboard. (Diffrent types of diagrams)
- **Notifications**: Add push notifications for device status updates or critical events. (Live message Board )
- **Mobile Optimization**: Refine mobile UX to ensure seamless performance on smaller screens. (automatic device installation with bluetooth)
- **Cold Storage**: Automatic Coldstorage intevals to releave the amount of  data in the database.

## 🚀 Getting Started

1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd <project-folder>
