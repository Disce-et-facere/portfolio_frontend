import { type ClientSchema, a, defineData, defineFunction } from '@aws-amplify/backend';
import { fetchDeviceShadow } from '../lambdas/fetchDeviceShadow/resource';

export const schema = a.schema({
  telemetry: a
    .model({
      device_id: a.string().required(),
      timestamp: a.timestamp().required(),
      ownerID: a.string().required(),
      deviceData: a.json().required(),
      createdAt: a.timestamp().required(),
      updatedAt: a.timestamp().required(),
    })
    .identifier(['device_id', 'timestamp'])
    .secondaryIndexes((index) => [
      index('ownerID')
        .sortKeys(['timestamp']) 
        .name('OwnerIDIndex')
        .queryField('listDevicesByOwnerID'),
    ])
    .authorization((rules) => [rules.authenticated('userPools')]),

  // fetch device shadow
  FetchShadowResponse: a.customType({
    deviceId: a.string().required(),
    status: a.string(),
    deviceData: a.json(),
  }),

  fetchDeviceShadow: a
    .query()
    .arguments({
      deviceId: a.string().required(),
    })
    .returns(a.ref('FetchShadowResponse'))
    .authorization((allow) => [allow.authenticated('userPools')])
    .handler(a.handler.function(fetchDeviceShadow)),
});

export type Schema = ClientSchema<typeof schema>;

export const tableSchema = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'userPool',
  },
});
