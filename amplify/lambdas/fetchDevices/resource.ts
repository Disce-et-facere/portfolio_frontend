import { defineFunction } from '@aws-amplify/backend';
import { addTag, getResourceArn } from '../../resource-discovery/helper';
import * as AWS from 'aws-sdk';

// Define the Lambda function for fetching devices
export const fetchDevices = defineFunction({
  name: 'fetchDevices',
  environment: {
    DEVICE_TABLE_NAME: 'placeholder', // Placeholder for the table name, updated post-deployment
  },
  entry: './handler.ts',
});

// Post-deployment configuration for updating environment variables
export const configureFetchDevices = async () => {
  const lambda = new AWS.Lambda();

  try {
    // Fetch the DynamoDB table ARN dynamically
    const tableArn = await getResourceArn('ResourceType', 'DynamoDBTable');
    if (!tableArn) {
      throw new Error('DynamoDB table ARN not found. Ensure the table has been provisioned.');
    }

    // Extract the table name from the ARN
    const tableName = tableArn.split('/').pop();
    if (!tableName) {
      throw new Error('Failed to extract table name from ARN.');
    }
    console.log(`DynamoDB Table Name: ${tableName}`);

    // Fetch the fetchDevices Lambda ARN
    const lambdaArn = await getResourceArn('ResourceType', 'FetchDevicesFunction');
    if (!lambdaArn) {
      throw new Error('FetchDevicesFunction ARN not found.');
    }

    // Update the Lambda's environment variables
    await lambda
      .updateFunctionConfiguration({
        FunctionName: lambdaArn,
        Environment: {
          Variables: {
            DEVICE_TABLE_NAME: tableName,
          },
        },
      })
      .promise();

    console.log('Environment variable DEVICE_TABLE_NAME set for fetchDevices.');

    // Tag the Lambda for future discovery
    await addTag(lambdaArn, 'ResourceType', 'FetchDevicesFunction');
  } catch (error) {
    console.error('Error configuring fetchDevices Lambda:', error);
    throw error;
  }
};
