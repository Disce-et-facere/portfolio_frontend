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

    // Hardcoded device ID for simplicity
    const deviceId = 'C2DD576A79F8';

    const params = {
      TableName: 'telemetry-a6dyastvzzaqjm7q7k6zsdbz3e-NONE',
      KeyConditionExpression: 'device_id = :deviceId',
      ExpressionAttributeValues: {
        ':deviceId': deviceId,
      },
      ProjectionExpression: 'timestamp, data',
      ScanIndexForward: false, // Order by descending timestamp
      Limit: 1, // Fetch only the latest value
    };

    const result = await dynamodb.query(params).promise();

    if (!result.Items || result.Items.length === 0) {
      return {
        statusCode: 404,
        headers: generateCORSHeaders(),
        body: JSON.stringify({
          error: 'No data found for the given device ID',
        }),
      };
    }

    const latestDevice = result.Items[0]; // Since we limited to 1, this is the latest

    return {
      statusCode: 200,
      headers: generateCORSHeaders(),
      body: JSON.stringify({
        deviceId,
        latestValue: {
          timestamp: latestDevice.timestamp,
          data: latestDevice.data,
        },
      }),
    };
  } catch (error) {
    console.error('Error fetching latest device data:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
    return {
      statusCode: 500,
      headers: generateCORSHeaders(),
      body: JSON.stringify({ error: errorMessage }),
    };
  }
};
