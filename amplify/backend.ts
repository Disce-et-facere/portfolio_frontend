import { defineBackend } from '@aws-amplify/backend';
import { auth, tagCognitoResources } from './auth/resource';
import { tableSchema, tagDynamoDBTable } from './data/resource';
import { setupIoTCore } from './iotCore/resource';
import { setupAmpResources } from './amp/resource';
import { createDevice } from './lambdas/createDevice/resource';
import { fetchDevices } from './lambdas/fetchDevices/resource';
import { setupApiGateway } from './apiGateway/resource';
import { telemetryTroubleshootingHandler } from './lambdas/telemetry-troubleshooting/resource';

export const backend = defineBackend({
  auth,
  tableSchema, // Deploy DynamoDB schema
  createDevice, // CreateDevice depends on IoT Core
  fetchDevices, // FetchDevices depends on DynamoDB
  telemetryTroubleshootingHandler,
});

/**
 * Post-deployment: Apply resource tagging.
 */
export const postDeploy = async () => {
  await tagCognitoResources(); // Tag Cognito resources
  await tagDynamoDBTable(); // Tag DynamoDB table
  await setupIoTCore(); // Setup IoT Core rules and tagging
  await setupAmpResources(); // tag web app URL
  await setupApiGateway(); // Setup API Gateway with routes
};
