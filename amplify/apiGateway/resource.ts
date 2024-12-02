import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as apigatewayv2 from 'aws-cdk-lib/aws-apigatewayv2';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as integrations from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import { getResourceArn } from '../resource-discovery/helper';

export const setupApiGateway = async () => {
  const app = new cdk.App();
  const stack = new cdk.Stack(app, 'ApiGatewayStack');

  try {
    // Fetch the ARNs and URLs needed
    const createDeviceArn = await getResourceArn('ResourceType', 'CreateDeviceFunction');
    const fetchDevicesArn = await getResourceArn('ResourceType', 'FetchDevicesFunction');
    const issuerUrl = await getResourceArn('ResourceType', 'CognitoIssuerUrl');
    const appClientId = await getResourceArn('ResourceType', 'CognitoAppClientId');
    const webAppUrl = await getResourceArn('ResourceType', 'WebAppUrl');

    if (!createDeviceArn || !fetchDevicesArn || !issuerUrl || !appClientId || !webAppUrl) {
      throw new Error('Required resources for API Gateway are missing.');
    }

    // Import Lambda Functions
    const createDeviceFunction = lambda.Function.fromFunctionArn(stack, 'CreateDeviceFunction', createDeviceArn);
    const fetchDevicesFunction = lambda.Function.fromFunctionArn(stack, 'FetchDevicesFunction', fetchDevicesArn);

    // **CreateDevice API**
    const createDeviceApi = new apigatewayv2.HttpApi(stack, 'CreateDeviceApi', {
      corsPreflight: {
        allowOrigins: [webAppUrl],
        allowHeaders: ['content-type', 'authorization'],
        allowMethods: [apigatewayv2.CorsHttpMethod.OPTIONS, apigatewayv2.CorsHttpMethod.POST],
      },
    });

    // Cognito Authorizer for CreateDevice API
    const createDeviceAuthorizer = new apigatewayv2.HttpAuthorizer(stack, 'CreateDeviceAuthorizer', {
      httpApi: createDeviceApi, // Attach to CreateDevice API
      type: apigatewayv2.HttpAuthorizerType.JWT,
      identitySource: ['$request.header.Authorization'],
      jwtIssuer: issuerUrl,
      jwtAudience: [appClientId],
    });

    // Integration for CreateDevice Lambda
    const createDeviceIntegration = new integrations.HttpLambdaIntegration('CreateDeviceIntegration', createDeviceFunction);

    // POST route for CreateDevice
    createDeviceApi.addRoutes({
      path: '/',
      methods: [apigatewayv2.HttpMethod.POST],
      integration: createDeviceIntegration,
      authorizer: {
        bind: () => ({
          authorizationType: 'JWT',
          authorizerId: createDeviceAuthorizer.authorizerId,
        }),
      },
    });

    // OPTIONS route for CreateDevice
    createDeviceApi.addRoutes({
      path: '/',
      methods: [apigatewayv2.HttpMethod.OPTIONS],
      integration: new integrations.HttpUrlIntegration('CreateDeviceOptionsIntegration', webAppUrl),
    });

    // Output CreateDevice API Endpoint
    new cdk.CfnOutput(stack, 'CreateDeviceApiEndpoint', {
      value: createDeviceApi.apiEndpoint,
      description: 'HTTP API Gateway endpoint for CreateDevice',
    });

    // **FetchDevices API**
    const fetchDevicesApi = new apigatewayv2.HttpApi(stack, 'FetchDevicesApi', {
      corsPreflight: {
        allowOrigins: [webAppUrl],
        allowHeaders: ['content-type', 'authorization'],
        allowMethods: [apigatewayv2.CorsHttpMethod.OPTIONS, apigatewayv2.CorsHttpMethod.GET],
      },
    });

    // Cognito Authorizer for FetchDevices API
    const fetchDevicesAuthorizer = new apigatewayv2.HttpAuthorizer(stack, 'FetchDevicesAuthorizer', {
      httpApi: fetchDevicesApi, // Attach to FetchDevices API
      type: apigatewayv2.HttpAuthorizerType.JWT,
      identitySource: ['$request.header.Authorization'],
      jwtIssuer: issuerUrl,
      jwtAudience: [appClientId],
    });

    // Integration for FetchDevices Lambda
    const fetchDevicesIntegration = new integrations.HttpLambdaIntegration('FetchDevicesIntegration', fetchDevicesFunction);

    // GET route for FetchDevices
    fetchDevicesApi.addRoutes({
      path: '/',
      methods: [apigatewayv2.HttpMethod.GET],
      integration: fetchDevicesIntegration,
      authorizer: {
        bind: () => ({
          authorizationType: 'JWT',
          authorizerId: fetchDevicesAuthorizer.authorizerId,
        }),
      },
    });

    // OPTIONS route for FetchDevices
    fetchDevicesApi.addRoutes({
      path: '/',
      methods: [apigatewayv2.HttpMethod.OPTIONS],
      integration: new integrations.HttpUrlIntegration('FetchDevicesOptionsIntegration', webAppUrl),
    });

    // Output FetchDevices API Endpoint
    new cdk.CfnOutput(stack, 'FetchDevicesApiEndpoint', {
      value: fetchDevicesApi.apiEndpoint,
      description: 'HTTP API Gateway endpoint for FetchDevices',
    });

    console.log('API Gateway setup completed.');
  } catch (error) {
    console.error('Error setting up API Gateway:', error);
    throw error;
  }
};
