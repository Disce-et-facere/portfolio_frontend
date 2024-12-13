import { defineBackend } from '@aws-amplify/backend';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as iot from 'aws-cdk-lib/aws-iot';
import { auth} from './auth/resource';
import { tableSchema} from './data/resource';
import { createDevice } from './lambdas/createDevice/resource';
import { deleteDevice } from './lambdas/deleteDevice/resource';
import { fetchDeviceShadow } from './lambdas/fetchDeviceShadow/resource';
import { Environment } from 'aws-cdk-lib/aws-appconfig';

const AWS_REGION = process.env.AWS_REGION || 'global'; // placeholders if value is not set
const AWS_ACCOUNT_ID = process.env.AWS_ACCOUNT_ID || '0000000000'; // placeholders if value is not set
const TABLE_NAME = process.env.DEVICE_TABLE_NAME || 'table-nameSomething'; // placeholders if value is not set

export const backend = defineBackend({
  auth,
  tableSchema, 
  createDevice, 
  deleteDevice,
  fetchDeviceShadow,
});

const ClientId: string = '${iot:ClientId}';

// Build ARN's from enviroment variables
const IOT_CLIENT_ARN = `arn:aws:iot:${AWS_REGION}:${AWS_ACCOUNT_ID}:client/${ClientId}`;
const IOT_TOPIC_ARN = `arn:aws:iot:${AWS_REGION}:${AWS_ACCOUNT_ID}:topic/${ClientId}/telemetry`;
const IOT_TOPIC_FILTER_ARN = `arn:aws:iot:${AWS_REGION}:${AWS_ACCOUNT_ID}:topicfilter/${ClientId}/*`;
const IOT_RECEIVE_ARN = `arn:aws:iot:${AWS_REGION}:${AWS_ACCOUNT_ID}:topic/${ClientId}/*`;
const IOT_THING_ARN = `arn:aws:iot:${AWS_REGION}:${AWS_ACCOUNT_ID}:thing/*`;
const IOT_CERT_ARN = `arn:aws:iot:${AWS_REGION}:${AWS_ACCOUNT_ID}:cert/*`;
const DYNAMODB_TABLE_ARN = `arn:aws:dynamodb:${AWS_REGION}${AWS_ACCOUNT_ID}:${TABLE_NAME}`;

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
        Resource: IOT_CLIENT_ARN,
      },
      {
        Effect: 'Allow',
        Action: 'iot:Publish',
        Resource: IOT_TOPIC_ARN,
      },
      {
        Effect: 'Allow',
        Action: 'iot:Subscribe',
        Resource: IOT_TOPIC_FILTER_ARN,
      },
      {
        Effect: 'Allow',
        Action: 'iot:Receive',
        Resource: IOT_RECEIVE_ARN,
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
  resources: [IOT_THING_ARN],
});

const certPolicy = new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['iot:AttachThingPrincipal'],
  resources: [IOT_CERT_ARN],
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
  resources: [DYNAMODB_TABLE_ARN],
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
  resources: [IOT_THING_ARN],
});

fetchDeviceShadowLambda.addToRolePolicy(iotPolicyShadow);