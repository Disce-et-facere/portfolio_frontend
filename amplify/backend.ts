import { defineBackend } from '@aws-amplify/backend';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as iot from 'aws-cdk-lib/aws-iot';
import { auth } from './auth/resource';
import { tableSchema } from './data/resource';
import { createDevice } from './lambdas/createDevice/resource';
import { fetchDevices } from './lambdas/fetchDevices/resource';
import { deleteDevice } from './lambdas/deleteDevice/resource';
import { fetchDeviceData } from './lambdas/fetchDeviceData/resource';

const AWS_BASE_ARN = process.env.AWS_BASE_ARN!; // Ensure this is defined in your environment variables

export const backend = defineBackend({
  auth,
  tableSchema,
  createDevice,
  fetchDevices,
  deleteDevice,
  fetchDeviceData,
});

//
// PERMISSIONS
//

// Permissions for createDevice Lambda
const createDeviceLambda = backend.createDevice.resources.lambda;

// Define the IoT policy dynamically using AWS_BASE_ARN
const iotPolicy = new iot.CfnPolicy(createDeviceLambda, 'DevicePolicy', {
  policyName: 'DevicePolicy',
  policyDocument: {
    Version: '2012-10-17',
    Statement: [
      {
        Effect: 'Allow',
        Action: 'iot:Connect',
        Resource: `${AWS_BASE_ARN}:client/\${iot:ClientId}`,
      },
      {
        Effect: 'Allow',
        Action: 'iot:Publish',
        Resource: `${AWS_BASE_ARN}:topic/\${iot:ClientId}/telemetry`,
      },
      {
        Effect: 'Allow',
        Action: 'iot:Subscribe',
        Resource: `${AWS_BASE_ARN}:topicfilter/\${iot:ClientId}/*`,
      },
      {
        Effect: 'Allow',
        Action: 'iot:Receive',
        Resource: `${AWS_BASE_ARN}:topic/\${iot:ClientId}/*`,
      },
    ],
  },
});

// Define other policies dynamically
const iotPolicyAdd = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['iot:CreateThing', 'iot:AttachThingPrincipal', 'iot:UpdateThingShadow'],
  resources: [`${AWS_BASE_ARN}:thing/*`],
});

const certPolicy = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['iot:AttachThingPrincipal'],
  resources: [`${AWS_BASE_ARN}:cert/*`],
});

const generalIotPolicy = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['iot:DescribeEndpoint', 'iot:CreateKeysAndCertificate'],
  resources: ['*'], // General IoT access
});

createDeviceLambda.addToRolePolicy(iotPolicyAdd);
createDeviceLambda.addToRolePolicy(certPolicy);
createDeviceLambda.addToRolePolicy(generalIotPolicy);

// Permissions for fetchDevices Lambda
const fetchDevicesLambda = backend.fetchDevices.resources.lambda;

const dynamoDbReadPolicy = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['dynamodb:Query', 'dynamodb:GetItem'],
  resources: [
    `${AWS_BASE_ARN}:table/telemetry-a6dyastvzzaqjm7q7k6zsdbz3e-NONE`,
    `${AWS_BASE_ARN}:table/telemetry-a6dyastvzzaqjm7q7k6zsdbz3e-NONE/index/OwnerIDIndex`,
  ],
});

// Attach the policy to the fetchDevices Lambda
fetchDevicesLambda.addToRolePolicy(dynamoDbReadPolicy);

const deleteDevicesLambda = backend.deleteDevice.resources.lambda;

const dynamoDbPolicy = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['dynamodb:Query', 'dynamodb:DeleteItem'],
  resources: [`${AWS_BASE_ARN}:table/telemetry-a6dyastvzzaqjm7q7k6zsdbz3e-NONE`],
});

const iotPolicyDelete = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['iot:DeleteThing', 'iot:DetachThingPrincipal', 'iot:DeleteCertificate'],
  resources: ['*'], // IoT actions on all resources
});

deleteDevicesLambda.addToRolePolicy(dynamoDbPolicy);
deleteDevicesLambda.addToRolePolicy(iotPolicyDelete);

// Permissions for fetchDeviceData Lambda
const fetchDeviceDataLambda = backend.fetchDeviceData.resources.lambda;

const dynamoDbFetchDeviceDataPolicy = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['dynamodb:Query', 'dynamodb:GetItem'],
  resources: [
    `${AWS_BASE_ARN}:table/telemetry-a6dyastvzzaqjm7q7k6zsdbz3e-NONE`,
    `${AWS_BASE_ARN}:table/telemetry-a6dyastvzzaqjm7q7k6zsdbz3e-NONE/index/OwnerIDIndex`,
  ],
});

fetchDeviceDataLambda.addToRolePolicy(dynamoDbFetchDeviceDataPolicy);
