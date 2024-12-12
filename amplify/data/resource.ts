import { a, defineData, defineFunction, type ClientSchema } from '@aws-amplify/backend';
import { fetchDeviceShadow } from '../lambdas/fetchDeviceShadow/resource';
import { deleteDevice } from '../lambdas/deleteDevice/resource';
import { createDevice } from '../lambdas/createDevice/resource'; // Import the createDevice Lambda handler

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
      index('ownerID')
        .sortKeys(['device_id'])
        .name('OwnerIDDeviceIDIndex')
        .queryField('listTelemetryByOwnerAndDevice'),
    ])
    .authorization((rules) => [rules.authenticated('userPools')]),

  // Fetch Device Shadow Mutation Response
  FetchShadowResponse: a.customType({
    deviceId: a.string().required(),
    status: a.string(),
    deviceData: a.json(),
  }),

  // Fetch Device Shadow Mutation
  fetchDeviceShadow: a
    .query()
    .arguments({
      deviceId: a.string().required(),
    })
    .returns(a.ref('FetchShadowResponse'))
    .authorization((allow) => [allow.authenticated('userPools')])
    .handler(a.handler.function(fetchDeviceShadow)),

  // Delete Device Mutation Response
  DeleteDeviceResponse: a.customType({
    message: a.string().required(),
  }),

  // Delete Device Mutation
  deleteDevice: a
    .mutation()
    .arguments({
      deviceId: a.string().required(),
      ownerId: a.string().required(),
    })
    .returns(a.ref('DeleteDeviceResponse'))
    .authorization((allow) => [allow.authenticated('userPools')])
    .handler(a.handler.function(deleteDevice)),

  // Create Device Mutation Response
  CreateDeviceResponse: a.customType({
    thingArn: a.string().required(),
    iotEndpoint: a.string().required(),
    certificates: a.json().required(),
    shadow: a.json().required(),
  }),

  // Create Device Mutation
  createDevice: a
    .mutation()
    .arguments({
      deviceName: a.string().required(),
      updatePeriod: a.integer().required(),
    })
    .returns(a.ref('CreateDeviceResponse'))
    .authorization((allow) => [allow.authenticated('userPools')])
    .handler(a.handler.function(createDevice)), // Link to the createDevice Lambda handler
});

export type Schema = ClientSchema<typeof schema>;

export const tableSchema = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'userPool',
  },
});
