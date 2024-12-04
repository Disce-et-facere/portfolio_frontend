import AWS from 'aws-sdk';
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

const dynamoDb = new AWS.DynamoDB.DocumentClient();
const iot = new AWS.Iot();

const generateCORSHeaders = () => ({
  "Access-Control-Allow-Origin": process.env.WEB_APP_URL || "*", // Use environment variable or fallback
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Allow-Methods": "OPTIONS,DELETE",
});

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Handle OPTIONS preflight request
    if (event.httpMethod === "OPTIONS") {
      return {
        statusCode: 204,
        headers: generateCORSHeaders(),
        body: "",
      };
    }

    const { ownerId, deviceId } = JSON.parse(event.body || '{}');

    if (!ownerId || !deviceId) {
      return {
        statusCode: 400,
        headers: generateCORSHeaders(),
        body: JSON.stringify({ error: 'Both ownerId and deviceId are required' }),
      };
    }

    const tableName = process.env.DEVICE_TABLE_NAME;

    if (!tableName) {
      throw new Error('DynamoDB Table Name not set in environment variables.');
    }

    // Step 1: Remove all records from DynamoDB for the deviceId
    const queryParams = {
      TableName: tableName,
      KeyConditionExpression: 'device_id = :deviceId AND ownerID = :ownerId',
      ExpressionAttributeValues: {
        ':deviceId': deviceId,
        ':ownerId': ownerId,
      },
    };

    const queryResult = await dynamoDb.query(queryParams).promise();

    if (queryResult.Items) {
      const deletePromises = queryResult.Items.map((item) =>
        dynamoDb
          .delete({
            TableName: tableName,
            Key: { device_id: item.device_id, timestamp: item.timestamp },
          })
          .promise()
      );
      await Promise.all(deletePromises);
    }

    // Step 2: Remove the device from IoT Core
    await iot
      .deleteThing({
        thingName: deviceId,
      })
      .promise();

    console.log(`Device ${deviceId} removed from IoT Core and DynamoDB.`);

    return {
      statusCode: 200,
      headers: generateCORSHeaders(),
      body: JSON.stringify({ message: `Device ${deviceId} successfully deleted.` }),
    };
  } catch (error) {
    console.error('Error deleting device:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
    return {
      statusCode: 500,
      headers: generateCORSHeaders(),
      body: JSON.stringify({ error: errorMessage }),
    };
  }
};
