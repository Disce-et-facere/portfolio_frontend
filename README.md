# Lightweight IoT Dashboard for Device Management

## 📖 Overview

This project is a **scalable and lightweight IoT dashboard** designed for customers to easily view and manage their devices and associated data. The dashboard displays device information, status, and collected data in a user-friendly way, enabling efficient monitoring of the IoT ecosystem.

## 🚀 Features

- **Device Management**: View and manage IoT devices.
- **Device Addition and Deletion**: Add and remove devices as needed for dynamic management.
- **Data Visualization**: Display device data such as temperature, humidity, and more in a clean, intuitive interface.
- **Multi-Sensor Support**: Seamlessly manage devices equipped with multiple sensors, enabling comprehensive monitoring and data visualization.
- **Authentication**: Secure login and device association using Cognito.
- **Scalability**: Built entirely on AWS services with a focus on scalability, safety, and cost-effective maintenance.

## 🛠️ Technologies Used

![service-diagram](https://github.com/user-attachments/assets/9464c142-bfda-44bd-bb34-2b9e51457514)

### AWS Services:
- **IoT Core**: Manages communication and data routing for connected IoT devices.
- **Amplify**: Simplifies the development workflow for seamless frontend and AppSync backend integration.
- **AppSync**: Provides GraphQL APIs for secure and scalable communication between the frontend and backend.
- **Lambda**: Executes backend logic for data processing and device management.
- **DynamoDB**: NoSQL database for storing device data and user associations.
- **Cognito**: Manages secure user authentication and authorization.
- **IAM**: Enforces security policies for AWS services.

### Frontend:
- **Flutter**: Cross-platform framework for creating a lightweight and responsive user interface.

## 📂 Project Structure

- **Frontend**: Built with Flutter, integrated with Amplify and AppSync for seamless communication with the AWS backend.
- **Backend**: Serverless architecture using AppSync, Lambda and DynamoDB to handle device data and user management.
- **Authentication**: Cognito ensures secure and scalable user sign-in and sign-up flows.

## 🎯 Key Goals

1. **Cost Efficiency**: Minimize costs while leveraging AWS's scalable and robust infrastructure.
2. **Lightweight Design**: Ensure the application is easy to deploy and use without unnecessary complexity.
3. **Scalability**: Support a growing number of devices and users without impacting performance and cost.

## 📈 Future Enhancements

- **Device Card View Options**: Enable users to switch the device card view between cards and a list view for better flexibility.
- **Graph Customization**: Allow users to select different graph types in the device detail view, tailored to their specific sensor data.
- **Notifications**: Add push notifications for device status updates or critical events (e.g., live message board).
- **Mobile App**: Provide an application for automatic device setup using Bluetooth and portable data surveillance.
- **Cold Storage**: Implement automatic cold storage intervals to optimize database performance and reduce costs.

## 🚀 Getting Started

1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd <project-folder>
   ```

2. **Deploy the App in Amplify**:
   Follow the Amplify documentation to deploy the app.

3. **Add Secrets in Amplify/Secrets**:
   Add the following secrets:
   - `AWS_BASE_ARN`
   - `DEVICE_TABLE_NAME`
   - `IOT_CORE_ENDPOINT`

   **Where to Find Them**:
   - `AWS_BASE_ARN`: Available in your AWS account under resource information.
   - `DEVICE_TABLE_NAME`: Name of the DynamoDB table for storing device data.
   - `IOT_CORE_ENDPOINT`: Found in the AWS IoT Core settings.

4. **Setup Message Route Rule in IoT Core**:
   Configure a rule in IoT Core with the following SQL and point it towards the dynamoDB table:
   ```sql
   SELECT *, 
   clientid() AS device_id, 
   floor(timestamp() / 1000) AS timestamp, 
   floor(timestamp() / 1000) AS createdAt, 
   floor(timestamp() / 1000) AS updatedAt FROM '+/telemetry'
   ```
5. **Adjust policy ARNs due to time constraints and the need to maintain sanity**:
   
   Some arn need to be adjusted after your aws account arn in project file: amplify/backend.ts 
   Ex. "Resource: 'arn:aws:iot:{your-region}:{account-id}:client/${iot:ClientId}',

7. **Redeploy the App in Amplify**:
   
   After configuring the secrets and message route rule, redeploy the app in Amplify to apply changes.

## 🔗 Device Code

The device-side code for connecting to this dashboard is hosted in a separate repository. You can find it here:

[Device Code Repository](<link-to-device-code-repo>)

## 📝 Final Thoughts

For the love of all that is sacred, avoid using the Flutter-Amplify combination until the developers have implemented all features and ensured the documentation is up to date. This will save you countless hours (or even days) of troubleshooting, frustration, and confusion.

I'll give this combo a 2 out of 5 🍞—only because it’s been informative!
