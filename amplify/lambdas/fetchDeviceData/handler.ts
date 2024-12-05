import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import AWS from 'aws-sdk';

const dynamodb = new AWS.DynamoDB.DocumentClient();

const generateCORSHeaders = () => ({
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Allow-Methods': 'OPTIONS,POST',
});

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    // Handle preflight requests
    if (event.httpMethod === 'OPTIONS') {
      return {
        statusCode: 204,
        headers: generateCORSHeaders(),
        body: '',
      };
    }

    const deviceId = event.queryStringParameters?.deviceId;
    const ownerId = event.queryStringParameters?.ownerId;

    if (!deviceId || !ownerId) {
      return {
        statusCode: 400,
        headers: generateCORSHeaders(),
        body: JSON.stringify({ error: 'Both deviceId and ownerId are required' }),
      };
    }

    // Query DynamoDB using the GSI
    const params = {
      TableName: process.env.DEVICE_TABLE_NAME!,
      IndexName: 'OwnerIDIndex', // Use the GSI
      KeyConditionExpression: 'ownerID = :ownerId',
      ExpressionAttributeValues: {
        ':ownerId': ownerId,
      },
      ProjectionExpression: 'device_id, #ts, data',
      ExpressionAttributeNames: {
        '#ts': 'timestamp', // Alias 'timestamp' since it's reserved
        '#data': 'data',    // Alias 'data' if it's reserved (double-check this)
      },
    };

    const result = await dynamodb.query(params).promise();

    if (!result.Items || result.Items.length === 0) {
      return {
        statusCode: 200,
        headers: generateCORSHeaders(),
        body: JSON.stringify({
          message: 'No data available for this device',
          data: [],
        }),
      };
    }

    // Parse and return the results
    const data = result.Items.map((item: any) => ({
      timestamp: item.timestamp,
      data: item.data,
    }));

    return {
      statusCode: 200,
      headers: generateCORSHeaders(),
      body: JSON.stringify({ data }),
    };
  } catch (error) {
    console.error('Error fetching device data:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
    return {
      statusCode: 500,
      headers: generateCORSHeaders(),
      body: JSON.stringify({ error: errorMessage }),
    };
  }
};
