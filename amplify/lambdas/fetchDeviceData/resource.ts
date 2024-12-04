import { defineFunction, secret } from '@aws-amplify/backend';

// Define the Lambda function for fetching device data
export const fetchDeviceData = defineFunction({
  name: 'fetchDeviceData',
  environment: {
    DEVICE_TABLE_NAME: secret('DEVICE_TABLE_NAME'), // Dynamically updated post-deployment
  },
  entry: './handler.ts', // Link to the handler file
});
