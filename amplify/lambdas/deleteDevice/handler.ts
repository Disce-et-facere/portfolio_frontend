import AWS from 'aws-sdk';
import { AppSyncResolverEvent } from 'aws-lambda';

const dynamoDb = new AWS.DynamoDB.DocumentClient();
const iot = new AWS.Iot();

export const handler = async (event: AppSyncResolverEvent<{ ownerId: string; deviceId: string }>) => {
  try {
    const { ownerId, deviceId } = event.arguments;

    if (!ownerId || !deviceId) {
      throw new Error('Both ownerId and deviceId are required.');
    }

    const tableName = process.env.DEVICE_TABLE_NAME;
    if (!tableName) {
      throw new Error('DynamoDB Table Name is not set in environment variables.');
    }

    // Query DynamoDB for all records with deviceId and ownerId
    const queryParams = {
      TableName: tableName,
      KeyConditionExpression: 'device_id = :deviceId AND ownerID = :ownerId',
      ExpressionAttributeValues: {
        ':deviceId': deviceId,
        ':ownerId': ownerId,
      },
    };

    const queryResult = await dynamoDb.query(queryParams).promise();

    if (queryResult.Items && queryResult.Items.length > 0) {
      const deletePromises = queryResult.Items.map((item) =>
        dynamoDb
          .delete({
            TableName: tableName,
            Key: { device_id: item.device_id, timestamp: item.timestamp },
          })
          .promise()
      );
      await Promise.all(deletePromises);
    } else {
      console.log(`No records found in DynamoDB for deviceId: ${deviceId} and ownerId: ${ownerId}`);
    }

    // Remove the device from IoT Core
    try {
      await iot.deleteThing({ thingName: deviceId }).promise();
      console.log(`Device ${deviceId} removed from IoT Core.`);
    } catch (error) {
      console.warn(`Failed to delete device from IoT Core. Device ${deviceId} may not exist.`);
    }

    return {
      message: `Device ${deviceId} successfully deleted.`,
    };
  } catch (error) {
    // Type narrowing for the error
    if (error instanceof Error) {
      console.error('Error deleting device:', error.message);
      throw new Error(error.message || 'Unknown error occurred.');
    } else {
      console.error('Error deleting device:', error);
      throw new Error('An unknown error occurred.');
    }
  }
};
