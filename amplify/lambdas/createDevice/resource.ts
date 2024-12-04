import { defineFunction, secret } from '@aws-amplify/backend';

// Define the Lambda function for creating devices
export const createDevice = defineFunction({
  name: 'createDevice',
  environment: {
    IOT_CORE_ENDPOINT: secret('IOT_CORE_ENDPOINT'), // Placeholder for dynamic IoT Core endpoint
    WEB_APP_URL: secret('WEB_APP_URL'),       // Placeholder for dynamic web app URL
  },
  entry: './handler.ts', // Lambda handler file
});