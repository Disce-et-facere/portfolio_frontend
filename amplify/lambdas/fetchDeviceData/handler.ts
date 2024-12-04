import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import AWS from 'aws-sdk';

const dynamodb = new AWS.DynamoDB.DocumentClient();

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    // Extract deviceId from query parameters
    const deviceId = event.queryStringParameters?.deviceId;

    if (!deviceId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'deviceId is required' }),
      };
    }

    // Query DynamoDB for all data related to the specific device
    const params = {
      TableName: process.env.DEVICE_TABLE_NAME!,
      KeyConditionExpression: 'deviceID = :deviceId',
      ExpressionAttributeValues: {
        ':deviceId': deviceId,
      },
      ProjectionExpression: 'timestamp, data', // Retrieve only the necessary fields
    };

    const result = await dynamodb.query(params).promise();

    if (!result.Items || result.Items.length === 0) {
      return {
        statusCode: 200,
        body: JSON.stringify({ data: [] }),
      };
    }

    // Parse and return the results
    const data = result.Items.map((item: any) => ({
      timestamp: item.timestamp,
      data: item.data,
    }));

    return {
      statusCode: 200,
      body: JSON.stringify({ data }),
    };
  } catch (error) {
    console.error('Error fetching device data:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
    return {
      statusCode: 500,
      body: JSON.stringify({ error: errorMessage }),
    };
  }
};
