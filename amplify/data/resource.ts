import { type ClientSchema, a, defineData } from '@aws-amplify/backend';

const schema = a.schema({
  Device: a
    .model({
      name: a.string(), // Device name
    })
    .authorization((rules) => [
      rules.owner(), // Apply default owner-based authorization
    ]),
});

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'userPool',
  },
});
