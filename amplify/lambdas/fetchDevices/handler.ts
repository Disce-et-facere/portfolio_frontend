import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import AWS from 'aws-sdk';

const dynamodb = new AWS.DynamoDB.DocumentClient();

const generateCORSHeaders = () => ({
  'Access-Control-Allow-Origin': process.env.WEB_APP_URL!, // Adjust to your frontend domain if needed
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Allow-Methods': 'OPTIONS,GET,POST',
});

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {

    if (event.httpMethod === 'OPTIONS') {
      return {
        statusCode: 204,
        headers: generateCORSHeaders(),
        body: '',
      };
    }

    // Extract ownerId from query parameters
    const ownerId = event.queryStringParameters?.ownerId;

    if (!ownerId) {
      return {
        statusCode: 400,
        headers: generateCORSHeaders(),
        body: JSON.stringify({ error: 'ownerId is required' }),
      };
    }

    const params = {
      TableName: process.env.DEVICE_TABLE_NAME!,
      IndexName: 'OwnerIDIndex', // Ensure this GSI is set up in the DynamoDB table
      KeyConditionExpression: 'ownerID = :ownerId',
      ExpressionAttributeValues: {
        ':ownerId': ownerId,
      },
      ProjectionExpression: 'device_id, timestamp, data',
    };

    const result = await dynamodb.query(params).promise();

    if (!result.Items || result.Items.length === 0) {
      return {
        statusCode: 200,
        headers: generateCORSHeaders(),
        body: JSON.stringify({
          message: 'No devices in Database',
          devices: [],
        }),
      };
    }

    const latestDevices = result.Items.reduce<Record<string, any>>((acc, item) => {
      const { device_id, timestamp } = item;

      if (!acc[device_id] || acc[device_id].timestamp < timestamp) {
        acc[device_id] = item;
      }

      return acc;
    }, {});

    const devices = Object.values(latestDevices).map((item: any) => ({
      deviceId: item.device_id,
      timestamp: item.timestamp,
      data: item.data,
    }));

    return {
      statusCode: 200,
      body: JSON.stringify({ devices }),
    };
  } catch (error) {
    console.error('Error fetching devices:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
    return {
      statusCode: 500,
      headers: generateCORSHeaders(),
      body: JSON.stringify({ error: errorMessage }),
    };
  }
};
