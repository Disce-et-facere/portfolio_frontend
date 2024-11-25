import AWS from 'aws-sdk';
import fetch from 'node-fetch'; // Add fetch for HTTP requests
import type { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

const iot = new AWS.Iot();
const iotData = new AWS.IotData({ endpoint: process.env.IOT_ENDPOINT });
const dynamoDB = new AWS.DynamoDB.DocumentClient();

const METADATA_TABLE = process.env.METADATA_TABLE as string;

// AWS IoT CA Certificate URL
const CA_CERT_URL = 'https://www.amazontrust.com/repository/AmazonRootCA1.pem';

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    const { deviceName, alias, sensors } = JSON.parse(event.body || '{}');

    if (!deviceName) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Device name is required' }),
      };
    }

    // Step 1: Create IoT Thing
    const thingResponse = await iot.createThing({ thingName: deviceName }).promise();
    const thingArn = thingResponse.thingArn;

    // Step 2: Generate IoT Certificates
    const certResponse = await iot.createKeysAndCertificate({ setAsActive: true }).promise();
    const { certificateArn, certificatePem, keyPair } = certResponse;

    // Step 3: Attach Certificate to Thing
    await iot
      .attachThingPrincipal({
        thingName: deviceName,
        principal: certificateArn,
      })
      .promise();

    // Step 4: Set Shadow
    const shadowPayload = {
      state: {
        desired: { sendIntervalSeconds: 10 },
        reported: { sendIntervalSeconds: 10 },
      },
    };

    await iotData
      .updateThingShadow({
        thingName: deviceName,
        payload: JSON.stringify(shadowPayload),
      })
      .promise();

    // Step 5: Store Metadata in DynamoDB
    const metadata = {
      thingName: deviceName,
      alias: alias || null,
      sensors: sensors || [],
      certificateArn,
      createdAt: new Date().toISOString(),
    };

    await dynamoDB
      .put({
        TableName: METADATA_TABLE,
        Item: metadata,
      })
      .promise();

    // Step 6: Retrieve CA Certificate
    const caCertResponse = await fetch(CA_CERT_URL);
    const caCert = await caCertResponse.text();

    // Step 7: Return IoT endpoint, certificates, and shadow details
    const iotEndpoint = (await iot.describeEndpoint({ endpointType: 'iot:Data-ATS' }).promise())
      .endpointAddress;

    return {
      statusCode: 200,
      body: JSON.stringify({
        thingArn,
        iotEndpoint,
        certificates: {
          certificatePem, // Device Certificate
          privateKey: keyPair.PrivateKey, // Private Key
          publicKey: keyPair.PublicKey, // Public Key
          caCertificate: caCert, // Amazon Root CA1 Certificate
        },
        shadow: shadowPayload, // Shadow state
      }),
    };
  } catch (error) {
    console.error('Error creating device:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: (error as Error).message }),
    };
  }
};
