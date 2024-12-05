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
    if (event.httpMethod === 'OPTIONS') {
      return {
        statusCode: 204,
        headers: generateCORSHeaders(),
        body: '',
      };
    }

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
      TableName: 'telemetry-a6dyastvzzaqjm7q7k6zsdbz3e-NONE',
      IndexName: 'OwnerIDIndex', // Use the GSI
      KeyConditionExpression: 'ownerID = :ownerId',
      ExpressionAttributeNames: {
        '#ts': 'timestamp', // Alias 'timestamp'
        '#dt': 'data', // Alias for data
      },
      ExpressionAttributeValues: {
        ':ownerId': ownerId,
      },
      ProjectionExpression: 'device_id, #ts, #dt', // Use the alias here
    };

    const result = await dynamodb.query(params).promise();

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
