import { defineFunction, secret } from '@aws-amplify/backend';

export const createDeviceFunction = defineFunction({
  name: 'createDeviceFunction',
  environment: {
    IOT_ENDPOINT: secret('CreateDeviceEndPoint'),
  },
  entry: './handler.ts',
});