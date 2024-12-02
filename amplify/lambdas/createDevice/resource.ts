import { defineFunction } from '@aws-amplify/backend';
import { addTag, getResourceArn } from '../../resource-discovery/helper';
import AWS from 'aws-sdk';

// Define the Lambda function for creating devices
export const createDevice = defineFunction({
  name: 'createDevice',
  environment: {
    IOT_CORE_ENDPOINT: 'placeholder', // Placeholder for dynamic IoT Core endpoint
    WEB_APP_URL: 'placeholder',       // Placeholder for dynamic web app URL
  },
  entry: './handler.ts',
});

// Post-deployment configuration for setting environment variables
export const configureCreateDevice = async () => {
  const iot = new AWS.Iot();
  const lambda = new AWS.Lambda();

  try {
    // Fetch IoT Core Endpoint
    const iotEndpointResponse = await iot.describeEndpoint({ endpointType: 'iot:Data-ATS' }).promise();
    const iotCoreEndpoint = iotEndpointResponse.endpointAddress;

    if (!iotCoreEndpoint) {
      throw new Error('Failed to retrieve IoT Core endpoint.');
    }
    console.log(`IoT Core Endpoint: ${iotCoreEndpoint}`);

    // Fetch Web App URL
    const webAppUrl = await getResourceArn('ResourceType', 'WebAppURL');
    if (!webAppUrl) {
      throw new Error('Web App URL not found. Ensure the hosting setup is complete.');
    }
    console.log(`Web App URL: ${webAppUrl}`);

    // Fetch the Lambda ARN
    const lambdaArn = await getResourceArn('ResourceType', 'CreateDeviceFunction');
    if (!lambdaArn) {
      throw new Error('CreateDeviceFunction ARN not found.');
    }

    // Update Lambda environment variables
    await lambda
      .updateFunctionConfiguration({
        FunctionName: lambdaArn,
        Environment: {
          Variables: {
            IOT_CORE_ENDPOINT: iotCoreEndpoint,
            WEB_APP_URL: webAppUrl,
          },
        },
      })
      .promise();

    console.log('Environment variables updated for createDevice.');

    // Tag the Lambda for future discovery
    await addTag(lambdaArn, 'ResourceType', 'CreateDeviceFunction');
  } catch (error) {
    console.error('Error configuring createDevice Lambda:', error);
    throw error;
  }
};
