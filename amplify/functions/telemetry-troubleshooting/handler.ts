const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

export const handler = async (event: any) => {
  try {
    const { device_id, timestamp, ownerID, data } = event.arguments;

    // Validate required fields
    if (!device_id || !timestamp || !ownerID || !data) {
      return {
        error: "Missing required fields: device_id, timestamp, ownerID, or data.",
      };
    }

    // Simulate the same processing as the IoT SQL Rule
    const params = {
      TableName: process.env.DEVICES_TABLE, // Replace with your DynamoDB table name
      Item: {
        device_id,
        timestamp,
        ownerID,
        data,
      },
    };

    // Attempt to write to DynamoDB
    await dynamodb.put(params).promise();

    return {
      success: true,
      message: "Telemetry data stored successfully.",
      item: params.Item,
    };
  } catch (error: unknown) {
    // Cast the error to Error to access its properties
    const err = error as Error;

    console.error("Error processing telemetry data:", err.message);

    return {
      success: false,
      error: err.message || "Unknown error occurred.",
    };
  }
};
