import { defineFunction, secret } from '@aws-amplify/backend';

export const createDeviceFunction = defineFunction({
  name: 'createDeviceFunction',
  environment: {
    IOT_ENDPOINT: secret('IOT_ENDPOINT_URL'),
  },
  entry: './handler.ts',
});