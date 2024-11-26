import { defineBackend } from '@aws-amplify/backend';
import { auth } from './auth/resource';
import { data } from './data/resource';
import { createDeviceFunction } from './functions/createDeviceFunction/resource';
import { telemetryTroubleshootingHandler } from './functions/telemetry-troubleshooting/resource';

/**
 * @see https://docs.amplify.aws/react/build-a-backend/ to add storage, functions, and more
 */

defineBackend({
  auth,
  data,
  createDeviceFunction,
  telemetryTroubleshootingHandler,
});