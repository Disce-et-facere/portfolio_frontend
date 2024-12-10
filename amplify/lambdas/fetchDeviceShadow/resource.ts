import { defineFunction, secret } from '@aws-amplify/backend';

export const fetchDeviceShadow = defineFunction({
  name: 'fetchDeviceShadow',
  environment: {
    IOT_CORE_ENDPOINT: secret('IOT_CORE_ENDPOINT'),
  },
  entry: './handler.ts',
});