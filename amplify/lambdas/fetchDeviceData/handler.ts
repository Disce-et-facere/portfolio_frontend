import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import AWS from 'aws-sdk';

const dynamodb = new AWS.DynamoDB.DocumentClient();

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    const deviceId = event.queryStringParameters?.deviceId;
    const ownerId = event.queryStringParameters?.ownerId;

    if (!deviceId || !ownerId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Both deviceId and ownerId are required' }),
      };
    }

    // Query DynamoDB using the GSI
    const params = {
      TableName: process.env.DEVICE_TABLE_NAME!,
      IndexName: 'OwnerIDIndex', // Use the GSI
      KeyConditionExpression: 'ownerID = :ownerID AND device_id = :deviceID',
      ExpressionAttributeValues: {
        ':ownerID': ownerId,
        ':deviceID': deviceId,
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
