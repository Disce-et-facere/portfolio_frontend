import { type ClientSchema, a, defineData} from '@aws-amplify/backend';

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