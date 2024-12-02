import {defineBackend} from '@aws-amplify/backend'
import { type ClientSchema, a, defineData} from '@aws-amplify/backend';
import { addTag } from '../resource-discovery/helper';

export const schema = a.schema({
  telemetry: a
    .model({
      device_id: a.string().required(),
      timestamp: a.timestamp().required(),
      ownerID: a.string().required(),
      data: a.json().required(),
    })
    .identifier(['device_id', 'timestamp']) // Composite primary key
    .secondaryIndexes((index) => [
      index('ownerID')                // Partition key
        .sortKeys(['timestamp'])           // Sort key
        .name('OwnerIDIndex')              // GSI name
        .queryField('listDevicesByOwnerID') // Query field
    ])
    .authorization((rules) => [
      rules.authenticated('userPools'),
    ]),
});

export type Schema = ClientSchema<typeof schema>;

export const tableSchema = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'userPool',
  },
});

/**
 * Post-deployment tagging function for DynamoDB table.
 */
export const tagDynamoDBTable = async () => {
  const tableArn = process.env.AWS_DYNAMODB_TABLE_ARN; // ARN will be automatically set during deployment
  const tableName = process.env.AWS_DYNAMODB_TABLE_NAME; // Name will be set during deployment

  if (tableArn) {
    await addTag(tableArn, 'ResourceType', 'DynamoDBTable');
  }

  if (tableName) {
    await addTag(tableName, 'Output', 'TelemetryTableName');
  }
};