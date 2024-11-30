const AWS = require('aws-sdk'); // Use require for Lambda's pre-installed SDK
const https = require('https');
import { IncomingMessage } from 'http';
import type { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

const iot = new AWS.Iot();
const iotData = new AWS.IotData({ endpoint: process.env.IOT_ENDPOINT });

// AWS IoT CA Certificate URL
const CA_CERT_URL = 'https://www.amazontrust.com/repository/AmazonRootCA1.pem';

// Function to fetch CA certificate
function fetchCA(url: string): Promise<string> {
  return new Promise<string>((resolve, reject) => {
    https.get(url, (res: IncomingMessage) => {
      let data = '';

      res.on('data', (chunk: Buffer) => {
        data += chunk.toString();
      });

      res.on('end', () => resolve(data));

      res.on('error', (err: Error) => reject(err));
    }).on('error', (err: Error) => reject(err));
  });
}

// Helper function to generate CORS headers
const generateCORSHeaders = () => ({
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Allow-Methods": "OPTIONS,POST",
});

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    // Handle OPTIONS preflight request
    if (event.httpMethod === "OPTIONS") {
      return {
        statusCode: 204,
        headers: generateCORSHeaders(),
        body: "",
      };
    }

    const { deviceName } = JSON.parse(event.body || '{}');

    if (!deviceName) {
      return {
        statusCode: 400,
        headers: generateCORSHeaders(),
        body: JSON.stringify({ error: 'Device name is required' }),
      };
    }

    // Step 1: Create IoT Thing
    const thingResponse = await iot.createThing({ thingName: deviceName }).promise();
    const thingArn = thingResponse.thingArn;

    // Step 2: Generate IoT Certificates
    const certResponse = await iot.createKeysAndCertificate({ setAsActive: true }).promise();
    const { certificateArn, certificatePem, keyPair } = certResponse;

    if (!keyPair || !keyPair.PrivateKey || !keyPair.PublicKey) {
      throw new Error('Key pair generation failed');
    }

    // Step 3: Attach Certificate to Thing
    if (!certificateArn) {
      throw new Error('Certificate ARN is required');
    }

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

    // Step 5: Retrieve CA Certificate using fetchCA function
    const caCert = await fetchCA(CA_CERT_URL);
    console.log('Fetched CA Certificate:', caCert);

    // Step 6: Return IoT endpoint, certificates, and shadow details
    const iotEndpoint = (await iot.describeEndpoint({ endpointType: 'iot:Data-ATS' }).promise())
      .endpointAddress;

    return {
      statusCode: 200,
      headers: generateCORSHeaders(),
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
      headers: generateCORSHeaders(),
      body: JSON.stringify({ error: (error as Error).message }),
    };
  }
};
