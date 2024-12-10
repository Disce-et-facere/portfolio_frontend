import { APIGatewayProxyEvent } from 'aws-lambda';
import AWS from 'aws-sdk';

const iotData = new AWS.IotData({ endpoint: process.env.IOT_CORE_ENDPOINT });

export const handler = async (event: APIGatewayProxyEvent) => {
  console.log('Event:', JSON.stringify(event, null, 2));

  const { deviceId } = JSON.parse(event.body || '{}');

  if (!deviceId) {
    throw new Error('Device ID is required');
  }

  try {
    const params = {
      thingName: deviceId,
    };

    // Get device shadow
    const result = await iotData.getThingShadow(params).promise();

    if (!result.payload) {
      throw new Error('Payload is undefined.');
    }

    const payload = result.payload.toString(); // Convert payload to a string
    const shadowData = JSON.parse(payload);

    return {
      deviceId,
      status: shadowData.state?.reported?.status || 'Unknown',
    };
  } catch (error) {
    console.error('Error fetching shadow data:', error);
    throw new Error('Failed to fetch device shadow');
  }
};
