# Lightweight IoT Dashboard for Device Management

## 📖 Overview

This project is a **scalable and lightweight IoT dashboard** designed for customers to easily view and manage their devices and associated data. The dashboard displays device information, status, and collected data in a user-friendly way, enabling efficient monitoring of the IoT ecosystem.

## 🚀 Features

- **Multi-Sensor Support**: Seamlessly manage devices equipped with multiple sensors, enabling comprehensive monitoring and data visualization.
- **Device Management**: View and manage IoT devices.
- **Data Visualization**: Display device data such as temperature, humidity, and more in a clean, intuitive interface.
- **Authentication**: Secure login and device association using Cognito.
- **Scalability**: Built entirely on AWS services with a focus on scalability, safety, and cost-effective maintenance.

## 🛠️ Technologies Used

### AWS Services:
- **Amplify**: Simplifies the development workflow for seamless frontend and AppSync backend integration.
- **AppSync**: Provides GraphQL APIs for secure and scalable communication between the frontend and backend.
- **DynamoDB**: NoSQL database for storing device data and user associations.
- **Cognito**: Manages secure user authentication and authorization.
- **IAM**: Enforces security policies for AWS services.

### Frontend:
- **Flutter**: Cross-platform framework for creating a lightweight and responsive user interface.

## 📂 Project Structure

- **Frontend**: Built with Flutter, integrated with Amplify and AppSync for seamless communication with the AWS backend.
- **Backend**: Serverless architecture using AppSync and DynamoDB to handle device data and user management.
- **Authentication**: Cognito ensures secure and scalable user sign-in and sign-up flows.

## 🎯 Key Goals

1. **Cost Efficiency**: Minimize costs while leveraging AWS's scalable and robust infrastructure.
2. **Lightweight Design**: Ensure the application is easy to deploy and use without unnecessary complexity.
3. **Scalability**: Support a growing number of devices and users without impacting performance and cost.

## 📈 Future Enhancements

- **Device Card View Options**: Enable users to switch the device card view between cards and a list view for better flexibility.
- **Graph Customization**: Allow users to select different graph types in the device detail view, tailored to their specific sensor data.
- **Customizable Data Views**: Allow users to customize how device data is displayed on the dashboard (e.g., different types of diagrams).
- **Notifications**: Add push notifications for device status updates or critical events (e.g., live message board).
- **Mobile Optimization**: Refine mobile UX to ensure seamless performance on smaller screens (e.g., automatic device installation with Bluetooth).
- **Cold Storage**: Implement automatic cold storage intervals to optimize database performance and reduce costs.

## 🚀 Getting Started

1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd <project-folder>
   ```

