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
      TableName: process.env.DEVICE_TABLE_NAME!,
      KeyConditionExpression: 'device_id = :deviceId',
      ExpressionAttributeValues: {
        ':deviceId': deviceId,
      },
      ExpressionAttributeNames: {
        '#ts': 'timestamp', // Alias for reserved keyword
        '#data': 'data',    // Alias for reserved keyword
      },
      ProjectionExpression: 'device_id, #ts, #data',
    };

    const result = await dynamodb.query(params).promise();

    if (!result.Items || result.Items.length === 0) {
      return {
        statusCode: 404,
        headers: generateCORSHeaders(),
        body: JSON.stringify({
          error: 'No data available for this device',
        }),
      };
    }

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
