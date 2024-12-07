const AWS = require('aws-sdk');
const https = require('https');
import { IncomingMessage } from 'http';
import type { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

const iot = new AWS.Iot();
const iotData = new AWS.IotData({ endpoint: process.env.IOT_CORE_ENDPOINT });

// AWS IoT CA Certificate URL
const CA_CERT_URL = 'https://www.amazontrust.com/repository/AmazonRootCA1.pem';

// Policy ARN for IoT device permissions
const IOT_POLICY_ARN = `${process.env.AWS_BASE_ARN}:policy/DevicePolicy`;

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
  "Access-Control-Allow-Origin": process.env.WEB_APP_URL!,
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

    const { deviceName, updatePeriod } = JSON.parse(event.body || '{}');

    if (!deviceName || !updatePeriod) {
      return {
        statusCode: 400,
        headers: generateCORSHeaders(),
        body: JSON.stringify({ error: 'Device name and update period are required' }),
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

    // Step 4: Attach Policy to Certificate
    if (!IOT_POLICY_ARN) {
      throw new Error('IoT policy ARN is not defined in the environment variables');
    }

    await iot
      .attachPolicy({
        policyName: IOT_POLICY_ARN.split('/').pop()!, // Extract policy name from ARN
        target: certificateArn,
      })
      .promise();
    console.log('Policy attached to certificate:', IOT_POLICY_ARN);

    // Step 5: Set Shadow with status and update period
    const shadowPayload = {
      state: {
        desired: {
          sendIntervalSeconds: updatePeriod,
          status: 'connected', // Initial status
          deviceData: {} // Placeholder for device data
        },
        reported: {
          sendIntervalSeconds: updatePeriod,
          status: 'disconnected', // Device defaults to disconnected
          deviceData: {} // Placeholder for device data
        },
      },
    };

    await iotData
      .updateThingShadow({
        thingName: deviceName,
        payload: JSON.stringify(shadowPayload),
      })
      .promise();

    console.log('Shadow updated:', shadowPayload);

    // Step 6: Retrieve CA Certificate using fetchCA function
    const caCert = await fetchCA(CA_CERT_URL);
    console.log('Fetched CA Certificate:', caCert);

    // Step 7: Return IoT endpoint, certificates, and shadow details
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
    const envValues = {
      IOT_CORE_ENDPOINT: process.env.IOT_CORE_ENDPOINT || null,
      WEB_APP_URL: process.env.WEB_APP_URL || null,
    };
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
    return {
      statusCode: 500,
      headers: generateCORSHeaders(),
      body: JSON.stringify({ error: errorMessage, environment: envValues }),
    };
  }
};
