import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as apigatewayv2 from 'aws-cdk-lib/aws-apigatewayv2';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as integrations from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as iam from 'aws-cdk-lib/aws-iam';

interface ApiGatewayProps {
  webAppUrl: string;
  createDeviceLambdaArn: string;
  fetchDevicesLambdaArn: string;
  deleteDeviceLambdaArn: string;
  issuerUrl: string;
  appClientId: string;
}

export class ApiGatewayStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: ApiGatewayProps) {
    super(scope, id);

    const {
      webAppUrl,
      createDeviceLambdaArn,
      fetchDevicesLambdaArn,
      deleteDeviceLambdaArn,
      issuerUrl,
      appClientId,
    } = props;

    // Helper function to create JWT authorizer with bind method
    const createJwtAuthorizer = (httpApi: apigatewayv2.HttpApi) => {
      const authorizer = new apigatewayv2.HttpAuthorizer(this, `${httpApi.node.id}-Authorizer`, {
        httpApi,
        type: apigatewayv2.HttpAuthorizerType.JWT,
        identitySource: ['$request.header.Authorization'],
        jwtIssuer: issuerUrl,
        jwtAudience: [appClientId],
      });

      return {
        bind: () => ({
          authorizationType: 'JWT',
          authorizerId: authorizer.authorizerId,
        }),
      };
    };

    // Helper function to add routes
    const addRoutes = (
      api: apigatewayv2.HttpApi,
      integration: apigatewayv2.HttpRouteIntegration,
      methods: apigatewayv2.HttpMethod[],
      authorizer?: ReturnType<typeof createJwtAuthorizer>
    ) => {
      api.addRoutes({
        path: '/',
        methods,
        integration,
        authorizer,
      });

      // Add CORS OPTIONS route
      api.addRoutes({
        path: '/',
        methods: [apigatewayv2.HttpMethod.OPTIONS],
        integration: new integrations.HttpUrlIntegration(`${api.node.id}-OptionsIntegration`, webAppUrl),
      });
    };

    // **API 1: CreateDevice API**
    const createDeviceApi = new apigatewayv2.HttpApi(this, 'CreateDeviceApi', {
      corsPreflight: {
        allowOrigins: [webAppUrl],
        allowHeaders: ['content-type', 'authorization'],
        allowMethods: [apigatewayv2.CorsHttpMethod.OPTIONS, apigatewayv2.CorsHttpMethod.POST],
      },
    });

    const createDeviceLambda = lambda.Function.fromFunctionArn(this, 'CreateDeviceFunction', createDeviceLambdaArn);

    const createDeviceAuthorizer = createJwtAuthorizer(createDeviceApi);

    addRoutes(createDeviceApi, new integrations.HttpLambdaIntegration('CreateDeviceIntegration', createDeviceLambda), [
      apigatewayv2.HttpMethod.POST,
    ], createDeviceAuthorizer);

    // Grant permissions to API Gateway to invoke Lambda
    createDeviceLambda.grantInvoke(new iam.ServicePrincipal('apigateway.amazonaws.com'));

    // **API 2: FetchDevices API**
    const fetchDevicesApi = new apigatewayv2.HttpApi(this, 'FetchDevicesApi', {
      corsPreflight: {
        allowOrigins: [webAppUrl],
        allowHeaders: ['content-type', 'authorization'],
        allowMethods: [apigatewayv2.CorsHttpMethod.OPTIONS, apigatewayv2.CorsHttpMethod.GET],
      },
    });

    const fetchDevicesLambda = lambda.Function.fromFunctionArn(this, 'FetchDevicesFunction', fetchDevicesLambdaArn);

    const fetchDevicesAuthorizer = createJwtAuthorizer(fetchDevicesApi);

    addRoutes(fetchDevicesApi, new integrations.HttpLambdaIntegration('FetchDevicesIntegration', fetchDevicesLambda), [
      apigatewayv2.HttpMethod.GET,
    ], fetchDevicesAuthorizer);

    // Grant permissions to API Gateway to invoke Lambda
    fetchDevicesLambda.grantInvoke(new iam.ServicePrincipal('apigateway.amazonaws.com'));

    // **API 3: DeleteDevice API**
    const deleteDeviceApi = new apigatewayv2.HttpApi(this, 'DeleteDeviceApi', {
      corsPreflight: {
        allowOrigins: [webAppUrl],
        allowHeaders: ['content-type', 'authorization'],
        allowMethods: [apigatewayv2.CorsHttpMethod.OPTIONS, apigatewayv2.CorsHttpMethod.DELETE],
      },
    });

    const deleteDeviceLambda = lambda.Function.fromFunctionArn(this, 'DeleteDeviceFunction', deleteDeviceLambdaArn);

    const deleteDeviceAuthorizer = createJwtAuthorizer(deleteDeviceApi);

    addRoutes(deleteDeviceApi, new integrations.HttpLambdaIntegration('DeleteDeviceIntegration', deleteDeviceLambda), [
      apigatewayv2.HttpMethod.DELETE,
    ], deleteDeviceAuthorizer);

    // Grant permissions to API Gateway to invoke Lambda
    deleteDeviceLambda.grantInvoke(new iam.ServicePrincipal('apigateway.amazonaws.com'));

    // Outputs
    new cdk.CfnOutput(this, 'CreateDeviceApiEndpoint', { value: createDeviceApi.apiEndpoint });
    new cdk.CfnOutput(this, 'FetchDevicesApiEndpoint', { value: fetchDevicesApi.apiEndpoint });
    new cdk.CfnOutput(this, 'DeleteDeviceApiEndpoint', { value: deleteDeviceApi.apiEndpoint });
  }
}
