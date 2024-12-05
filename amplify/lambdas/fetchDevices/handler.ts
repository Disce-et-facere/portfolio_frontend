import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import AWS from 'aws-sdk';

const dynamodb = new AWS.DynamoDB.DocumentClient();

const generateCORSHeaders = () => ({
  'Access-Control-Allow-Origin': process.env.WEB_APP_URL || '*',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Allow-Methods': 'OPTIONS,POST',
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

    // Log incoming request for debugging
    console.log('Incoming Event:', JSON.stringify(event, null, 2));

    const body = JSON.parse(event.body || '{}');
    const ownerId = body.ownerID;

    if (!ownerId) {
      return {
        statusCode: 400,
        headers: generateCORSHeaders(),
        body: JSON.stringify({ error: 'ownerID is required' }),
      };
    }

    const params = {
      TableName: process.env.DEVICE_TABLE_NAME!,
      IndexName: 'OwnerIDIndex', // Use the GSI
      KeyConditionExpression: 'OwnerID = :ownerId',
      ExpressionAttributeValues: {
        ':ownerId': ownerId,
      },
      ProjectionExpression: 'device_id, timestamp, data',
    };

    console.log('DynamoDB Query Params:', JSON.stringify(params, null, 2));

    const result = await dynamodb.query(params).promise();

    console.log('DynamoDB Query Result:', JSON.stringify(result, null, 2));

    if (!result.Items || result.Items.length === 0) {
      return {
        statusCode: 404,
        headers: generateCORSHeaders(),
        body: JSON.stringify({
          error: 'No devices found for the given ownerID',
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
      headers: generateCORSHeaders(),
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
