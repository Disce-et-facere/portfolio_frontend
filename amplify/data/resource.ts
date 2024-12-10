import { type ClientSchema, a, defineData, defineFunction } from '@aws-amplify/backend';
import {fetchDeviceShadow} from '../lambdas/fetchDeviceShadow/resource';

export const schema = a.schema({
  telemetry: a
    .model({
      device_id: a.string().required(),
      timestamp: a.timestamp().required(),
      ownerID: a.string().required(),
      deviceData: a.json().required(),
    })
    .identifier(['device_id', 'timestamp']) // Composite primary key
    .secondaryIndexes((index) => [
      index('ownerID') // Partition key
        .sortKeys(['timestamp']) // Sort key
        .name('OwnerIDIndex') // GSI name
        .queryField('listDevicesByOwnerID'), // Query field
    ])
    .authorization((rules) => [rules.authenticated('userPools')]),

  // Custom return type for the `fetchDeviceShadow` query
  FetchShadowResponse: a.customType({
    deviceId: a.string().required(),
    status: a.string(),
    deviceData: a.json(),
  }),

  // Define the custom query
  fetchDeviceShadow: a
    .query()
    .arguments({
      deviceId: a.string().required(),
    })
    .returns(a.ref('FetchShadowResponse')) // Return type
    .authorization((allow) => [allow.authenticated('userPools')]) // Authorization rules
    .handler(a.handler.function(fetchDeviceShadow)), // Link to the function handler
});

export type Schema = ClientSchema<typeof schema>;

export const tableSchema = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'userPool',
  },
});
