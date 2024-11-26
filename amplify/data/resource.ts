import {
  type ClientSchema,
  a,
  defineData,
  defineFunction,
} from "@aws-amplify/backend";

// Custom handler for telemetry troubleshooting
const telemetryTroubleshootingHandler = defineFunction({
  entry: '../functions/telemetry-troubleshooting/handler.ts',
});

const schema = a.schema({
  telemetry: a
    .model({
      device_id: a.string().required(),      // Unique device identifier
      timestamp: a.timestamp().required(),  // Time of data capture
      ownerID: a.string().required(),       // User or device owner identifier
      data: a.json().required(),            // JSON object for storing arbitrary sensor data
    })
    .identifier(['device_id', 'timestamp']) // Composite key: device_id + timestamp
    .authorization((rules) => [
      rules.authenticated('userPools'),    // Allow only authenticated users from Cognito
      rules.publicApiKey(),               // Allow access via public API key
    ]),

  addTelemetry: a
    .mutation()
    .arguments({
      device_id: a.string().required(),
      timestamp: a.timestamp().required(),
      ownerID: a.string().required(),
      data: a.json().required(),          // Generic data payload
    })
    .returns(a.json())                    // Returns diagnostics or confirmation
    .authorization((rules) => [
      rules.authenticated('userPools'),   // Restrict access to authenticated users
      rules.publicApiKey(),              // Allow access via public API key
    ])
    .handler(a.handler.function(telemetryTroubleshootingHandler)),
});

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'userPool',    // Use Cognito for authentication
    apiKeyAuthorizationMode: {              // API key access (optional)
      expiresInDays: 365,                   // API key expires in 1 year
    },
  },
});
