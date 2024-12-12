import AWS from 'aws-sdk';
import https from 'https';
import { IncomingMessage } from 'http';
import { APIGatewayProxyEvent } from 'aws-lambda';

// AWS IoT and IoTData instances
const iot = new AWS.Iot();
const iotData = new AWS.IotData({ endpoint: process.env.IOT_CORE_ENDPOINT });

const CA_CERT_URL = 'https://www.amazontrust.com/repository/AmazonRootCA1.pem';
const BASE_ARN = process.env.AWS_BASE_ARN || '';
const IOT_POLICY_ARN = `${BASE_ARN}:policy/DevicePolicy`;

// Function to fetch CA certificate
async function fetchCA(url: string): Promise<string> {
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

export const handler = async (event: any) => {
  try {
    const { deviceName, updatePeriod } = event.arguments;

    if (!deviceName || !updatePeriod) {
      throw new Error('Device name and update period are required.');
    }

    // Step 1: Create IoT Thing
    const thingResponse = await iot.createThing({ thingName: deviceName }).promise();
    const thingArn = thingResponse.thingArn;

    // Step 2: Generate IoT Certificates
    const certResponse = await iot.createKeysAndCertificate({ setAsActive: true }).promise();
    const { certificateArn, certificatePem, keyPair } = certResponse;

    if (!keyPair?.PrivateKey || !keyPair.PublicKey) {
      throw new Error('Key pair generation failed.');
    }

    // Step 3: Attach Certificate to Thing
    if (!certificateArn || !thingArn) {
      throw new Error('Certificate ARN or Thing ARN is missing.');
    }

    await iot
      .attachThingPrincipal({
        thingName: deviceName, // Must be a non-undefined string
        principal: certificateArn,
      })
      .promise();

    // Step 4: Attach Policy to Certificate
    if (!IOT_POLICY_ARN) {
      throw new Error('IoT policy ARN is not defined in the environment variables.');
    }

    await iot
      .attachPolicy({
        policyName: IOT_POLICY_ARN.split('/').pop() as string, // Extract policy name
        target: certificateArn,
      })
      .promise();

    // Step 5: Update Shadow
    const shadowPayload = {
      state: {
        desired: {
          sendIntervalSeconds: updatePeriod,
          status: 'connected',
          deviceData: {},
        },
        reported: {
          sendIntervalSeconds: updatePeriod,
          status: 'disconnected',
          deviceData: {},
        },
      },
    };

    await iotData
      .updateThingShadow({
        thingName: deviceName,
        payload: JSON.stringify(shadowPayload),
      })
      .promise();

    // Step 6: Fetch CA Certificate
    const caCert = await fetchCA(CA_CERT_URL);

    // Step 7: Return response
    const iotEndpoint = (
      await iot.describeEndpoint({ endpointType: 'iot:Data-ATS' }).promise()
    ).endpointAddress;

    return {
      thingArn,
      iotEndpoint,
      certificates: {
        certificatePem,
        privateKey: keyPair.PrivateKey,
        publicKey: keyPair.PublicKey,
        caCertificate: caCert,
      },
      shadow: shadowPayload,
    };
  } catch (error) {
    console.error('Error in createDevice handler:', error);
    throw new Error(error instanceof Error ? error.message : 'Unknown error occurred.');
  }
};
