import { getResourceArn } from './helper';

export async function getEnvironmentVariables() {
  const tableArn = await getResourceArn('Project', 'AmplifyApp');
  const iotArn = await getResourceArn('Project', 'AmplifyApp');
  const apiGatewayArn = await getResourceArn('Project', 'AmplifyApp');
  const userPoolArn = await getResourceArn('Project', 'AmplifyApp');

  if (!tableArn || !iotArn || !apiGatewayArn || !userPoolArn) {
    throw new Error('One or more resources could not be found by tags.');
  }

  const tableName = tableArn.split('/').pop();
  const apiGatewayUrl = `https://${apiGatewayArn.split('/').pop()}.execute-api.${process.env.AWS_REGION}.amazonaws.com`;
  const userPoolId = userPoolArn.split('/').pop();
  const tokenIssuer = `https://cognito-idp.${process.env.AWS_REGION}.amazonaws.com/${userPoolId}`;

  return {
    DEVICE_TABLE_NAME: tableName!,
    IOT_CORE_ARN: iotArn!,
    API_GATEWAY_URL: apiGatewayUrl!,
    USER_POOL_ID: userPoolId!,
    TOKEN_ISSUER: tokenIssuer!,
  };
}
