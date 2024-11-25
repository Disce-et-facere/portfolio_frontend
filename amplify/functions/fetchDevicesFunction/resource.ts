import { defineFunction, secret } from '@aws-amplify/backend';

export const createDeviceFunction = defineFunction({
  name: 'createDeviceFunction',
  environment: {
    METADATA_TABLE: '<YOUR_METADATA_TABLE_NAME>',
    IOT_ENDPOINT: secret('AWS_IOT_ENDPOINT'),
  },
  entry: './handler.ts',
});