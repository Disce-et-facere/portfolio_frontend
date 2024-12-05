import { defineBackend } from '@aws-amplify/backend';
import * as iam from 'aws-cdk-lib/aws-iam';
import { auth} from './auth/resource';
import { tableSchema} from './data/resource';
import { createDevice } from './lambdas/createDevice/resource';
import { fetchDevices } from './lambdas/fetchDevices/resource';
import { deleteDevice } from './lambdas/deleteDevice/resource';
import {fetchDeviceData} from './lambdas/fetchDeviceData/resource'
//import { telemetryTroubleshootingHandler } from './lambdas/telemetry-troubleshooting/resource';

export const backend = defineBackend({
  auth,
  tableSchema, // Deploy DynamoDB schema
  createDevice, // CreateDevice depends on IoT Core
  fetchDevices, // FetchDevices depends on DynamoDB
  deleteDevice,
  fetchDeviceData,
  //telemetryTroubleshootingHandler,

});

//
//  PERMISSIONS
//
// Permissions for createDevice Lambda
const createDeviceLambda = backend.createDevice.resources.lambda;

const iotPolicyAdd = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: [
    'iot:CreateThing',
    'iot:AttachThingPrincipal',
    'iot:UpdateThingShadow',
  ],
  resources: ['arn:aws:iot:eu-central-1:891612540400:thing/*'], // Replace with your account and region
});

const certPolicy = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['iot:AttachThingPrincipal'],
  resources: ['arn:aws:iot:eu-central-1:891612540400:cert/*'], // Replace with your account and region
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
    'arn:aws:dynamodb:eu-central-1:891612540400:table/telemetry-a6dyastvzzaqjm7q7k6zsdbz3e-NONE',
    'arn:aws:dynamodb:eu-central-1:891612540400:table/telemetry-a6dyastvzzaqjm7q7k6zsdbz3e-NONE/index/OwnerIDIndex',
  ],
});

// Attach the policy to the fetchDevices Lambda
fetchDevicesLambda.addToRolePolicy(dynamoDbReadPolicy);

const deleteDevicesLambda = backend.deleteDevice.resources.lambda;

// Define IAM policy for DynamoDB
const dynamoDbPolicy = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['dynamodb:Query', 'dynamodb:DeleteItem'],
  resources: ['arn:aws:dynamodb:eu-central-1:891612540400:table/telemetry-a6dyastvzzaqjm7q7k6zsdbz3e-NONE'],
});

// permission for deleteDevice Lambda
const iotPolicyDelete = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: [
    'iot:DeleteThing',
    'iot:DetachThingPrincipal',
    'iot:DeleteCertificate',
  ],
  resources: ['*'],
});

deleteDevicesLambda.addToRolePolicy(dynamoDbPolicy);
deleteDevicesLambda.addToRolePolicy(iotPolicyDelete);

// permission for fetchDeviceData lambda
const fetchDeviceDataLambda = backend.fetchDeviceData.resources.lambda;

const dynamoDbFetchDeviceDataPolicy = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['dynamodb:Query', 'dynamodb:GetItem'],
  resources: [
    'arn:aws:dynamodb:eu-central-1:891612540400:table/telemetry-a6dyastvzzaqjm7q7k6zsdbz3e-NONE',
    'arn:aws:dynamodb:eu-central-1:891612540400:table/telemetry-a6dyastvzzaqjm7q7k6zsdbz3e-NONE/index/OwnerIDIndex',
  ],
});

fetchDeviceDataLambda.addToRolePolicy(dynamoDbFetchDeviceDataPolicy);
