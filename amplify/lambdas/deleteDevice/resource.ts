import { defineFunction } from '@aws-amplify/backend';

export const deleteDevice = defineFunction({
  name: 'deleteDevice',
  environment: {
    DEVICE_TABLE_NAME: process.env.DEVICE_TABLE_NAME!,
    IOT_CORE_ENDPOINT: process.env.IOT_CORE_ENDPOINT!,
  },
  entry: './handler.ts',
});