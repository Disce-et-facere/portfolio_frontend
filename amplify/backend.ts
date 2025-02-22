import { defineBackend} from '@aws-amplify/backend';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as iot from 'aws-cdk-lib/aws-iot';
import { auth} from './auth/resource';
import { tableSchema} from './data/resource';
import { createDevice } from './lambdas/createDevice/resource';
import { deleteDevice } from './lambdas/deleteDevice/resource';
import { fetchDeviceShadow } from './lambdas/fetchDeviceShadow/resource';

const ACCOUNT_ID = '891612540400';
const TABLE_NAME = 'telemetry-k7armjma5bftpm3nyvu5r4c7bu-NONE';
const REGION = 'eu-central-1';

export const backend = defineBackend({
  auth,
  tableSchema, 
  createDevice, 
  deleteDevice,
  fetchDeviceShadow,
});
//
//  PERMISSIONS
//
// Permissions for createDevice Lambda
const createDeviceLambda = backend.createDevice.resources.lambda;

// Define the IoT policy
const iotPolicy = new iot.CfnPolicy(createDeviceLambda, 'DevicePolicy', {
  policyName: 'DevicePolicy',
  policyDocument: {
    Version: '2012-10-17',
    Statement: [
      {
        Effect: 'Allow',
        Action: 'iot:Connect',
        Resource: 'arn:aws:iot:' + REGION + ':' + ACCOUNT_ID + ':client/${iot:ClientId}',
      },
      {
        Effect: 'Allow',
        Action: 'iot:Publish',
        Resource: 'arn:aws:iot:' + REGION + ':' + ACCOUNT_ID + ':topic/${iot:ClientId}/telemetry',
      },
      {
        Effect: 'Allow',
        Action: 'iot:Subscribe',
        Resource: 'arn:aws:iot:' + REGION + ':' + ACCOUNT_ID  + ':topicfilter/${iot:ClientId}/*',
      },
      {
        Effect: 'Allow',
        Action: 'iot:Receive',
        Resource: 'arn:aws:iot:' + REGION + ':' + ACCOUNT_ID + ':topic/${iot:ClientId}/*',
      },
    ],
  },
});

const iotPolicyAdd = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: [
    'iot:CreateThing',
    'iot:AttachThingPrincipal',
    'iot:UpdateThingShadow',
  ],
  resources: ['arn:aws:iot:' + REGION + ':' + ACCOUNT_ID + ':thing/*'],
});

const certPolicy = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['iot:AttachThingPrincipal'],
  resources: ['arn:aws:iot:' + REGION + ':' + ACCOUNT_ID + ':cert/*'],
});

const generalIotPolicy = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['iot:DescribeEndpoint', 'iot:CreateKeysAndCertificate'],
  resources: ['*'], // General IoT access
});

createDeviceLambda.addToRolePolicy(iotPolicyAdd);
createDeviceLambda.addToRolePolicy(certPolicy);
createDeviceLambda.addToRolePolicy(generalIotPolicy);

const deleteDevicesLambda = backend.deleteDevice.resources.lambda;

// Define IAM policy for DynamoDB
const dynamoDbPolicy = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['dynamodb:Query', 'dynamodb:DeleteItem'],
  resources: ['arn:aws:dynamodb:' + REGION + ':' + ACCOUNT_ID + ':' + TABLE_NAME],
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

//permission for fetchDeviceShadow
const fetchDeviceShadowLambda = backend.fetchDeviceShadow.resources.lambda;

const iotPolicyShadow = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: [
    'iot:GetThingShadow',
  ],
  resources: ['arn:aws:iot:' + REGION + ':' + ACCOUNT_ID + ':thing/*'],
});

fetchDeviceShadowLambda.addToRolePolicy(iotPolicyShadow);