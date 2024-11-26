import { defineFunction } from '@aws-amplify/backend';

export const telemetryTroubleshootingHandler = defineFunction({
  name: 'telemetryTroubleshooting',
  environment: {
    DEVICES_TABLE: 'DevicesTable',
  },
  entry: './handler.ts', 
});