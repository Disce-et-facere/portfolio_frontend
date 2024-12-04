import { defineFunction, secret } from '@aws-amplify/backend';

// Define the Lambda function for creating devices
export const createDevice = defineFunction({
  name: 'createDevice',
  environment: {
    IOT_CORE_ENDPOINT: secret('IOT_CORE_ENDPOINT'),
    WEB_APP_URL: secret('WEB_APP_URL'), 
  },
  entry: './handler.ts', // Lambda handler file
});