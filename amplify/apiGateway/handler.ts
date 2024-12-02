import AWS from 'aws-sdk';
import { getResourceArn } from '../resource-discovery/helper';

const apiGateway = new AWS.ApiGatewayV2();

export const handler = async (): Promise<void> => {
  try {
    // Fetch necessary ARNs and URLs dynamically
    const createDeviceArn = await getResourceArn('ResourceType', 'CreateDeviceFunction');
    const fetchDevicesArn = await getResourceArn('ResourceType', 'FetchDevicesFunction');
    const cognitoUserPoolArn = await getResourceArn('ResourceType', 'CognitoUserPool');
    const cognitoIssuerUrl = `https://${cognitoUserPoolArn?.split(':')[5]}.amazonaws.com/${cognitoUserPoolArn?.split('/').pop()}`;
    const webAppUrl = await getResourceArn('ResourceType', 'WebAppURL');

    if (!createDeviceArn || !fetchDevicesArn || !cognitoIssuerUrl || !webAppUrl) {
      throw new Error('Required resources are missing.');
    }

    // Define JWT authorizer
    const authorizer = await apiGateway.createAuthorizer({
      ApiId: 'YourApiId', // Replace with actual API Gateway ID
      AuthorizerType: 'JWT',
      IdentitySource: ['$request.header.Authorization'],
      Name: 'CognitoJWTAuthorizer',
      JwtConfiguration: {
        Issuer: cognitoIssuerUrl,
        Audience: ['YourCognitoAppClientId'], // Replace with actual App Client ID
      },
    }).promise();

    // Set up routes for CreateDevice
    await apiGateway.createRoute({
      ApiId: 'YourApiId', // Replace with actual API Gateway ID
      RouteKey: 'POST /',
      Target: `integrations/${createDeviceArn}`,
      AuthorizationType: 'JWT',
      AuthorizerId: authorizer.AuthorizerId,
    }).promise();

    // Set up routes for FetchDevices
    await apiGateway.createRoute({
      ApiId: 'YourApiId', // Replace with actual API Gateway ID
      RouteKey: 'GET /',
      Target: `integrations/${fetchDevicesArn}`,
      AuthorizationType: 'JWT',
      AuthorizerId: authorizer.AuthorizerId,
    }).promise();

    console.log('API Gateway setup completed.');
  } catch (error) {
    console.error('Error setting up API Gateway:', error);
    throw error;
  }
};
