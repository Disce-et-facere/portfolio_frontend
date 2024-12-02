import { defineFunction } from '@aws-amplify/backend';
import { getEnvironmentVariables } from './environment';

export const resourceDiscovery = defineFunction({
  name: 'resourceDiscovery',
  environment: await getEnvironmentVariables(), // Dynamically fetch and pass environment variables
});
