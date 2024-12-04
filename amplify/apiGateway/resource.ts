import { defineFunction, secret } from '@aws-amplify/backend';

export const setupApiGateway = defineFunction({
  name: 'setupApiGateway',
  environment: {
    WEB_APP_URL: secret('WEB_APP_URL'), // Placeholder for dynamic URL
    CREATE_DEVICE_LAMBDA_ARN: secret('CREATE_DEVICE_LAMBDA_ARN'),
    FETCH_DEVICES_LAMBDA_ARN: secret('FETCH_DEVICES_LAMBDA_ARN'),
    COGNITO_ISSUER_URL: secret('COGNITO_ISSUER_URL'),
    COGNITO_APP_CLIENT_ID: secret('COGNITO_APP_CLIENT_ID'),
  },
  entry: './handler.ts', // Handler will perform the API Gateway setup
});