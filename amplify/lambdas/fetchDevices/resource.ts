import { defineFunction, secret } from '@aws-amplify/backend';

// Define the Lambda function for fetching devices
export const fetchDevices = defineFunction({
  name: 'fetchDevices',
  environment: {
    DEVICE_TABLE_NAME: secret('DEVICE_TABLE_NAME'), // Placeholder for the table name, updated post-deployment
  },
  entry: './handler.ts',
});