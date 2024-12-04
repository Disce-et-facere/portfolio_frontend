import { defineFunction, secret } from '@aws-amplify/backend';

export const deleteDevice = defineFunction({
  name: 'deleteDevice',
  environment: {
    DEVICE_TABLE_NAME: secret('DEVICE_TABLE_NAME'),
    IOT_CORE_ENDPOINT: secret('IOT_CORE_ENDPOINT'),
  },
  entry: './handler.ts',
});