import { addTag, getResourceArn } from '../resource-discovery/helper';
import * as AWS from 'aws-sdk';

const iam = new AWS.IAM();
const iot = new AWS.Iot();

interface AWSError {
  code: string;
  message: string;
}

/**
 * Sets up IoT Core Rules for telemetry routing and required IAM Role.
 */
export const setupIoTCore = async () => {
  const ruleName = 'TelemetryRule';
  const roleName = 'IoTWriteToDynamoDBRole';

  try {
    // Check if the IAM Role already exists
    let roleArn: string;
    try {
      const existingRole = await iam.getRole({ RoleName: roleName }).promise();
      roleArn = existingRole.Role.Arn;
      console.log(`IAM Role already exists: ${roleArn}`);
    } catch (error: unknown) {
      // Handle AWS errors specifically
      if (isAWSError(error) && error.code === 'NoSuchEntity') {
        console.log('Role does not exist, creating a new one...');
        const rolePolicy = {
          Version: '2012-10-17',
          Statement: [
            {
              Effect: 'Allow',
              Action: 'dynamodb:PutItem',
              Resource: '*', // Adjust to limit the scope of this role
            },
          ],
        };

        const newRole = await iam
          .createRole({
            RoleName: roleName,
            AssumeRolePolicyDocument: JSON.stringify({
              Version: '2012-10-17',
              Statement: [
                {
                  Effect: 'Allow',
                  Principal: {
                    Service: 'iot.amazonaws.com',
                  },
                  Action: 'sts:AssumeRole',
                },
              ],
            }),
          })
          .promise();

        roleArn = newRole.Role.Arn;

        // Attach policy to the role
        await iam
          .putRolePolicy({
            RoleName: roleName,
            PolicyName: `${roleName}-Policy`,
            PolicyDocument: JSON.stringify(rolePolicy),
          })
          .promise();

        console.log(`IAM Role created and policy attached: ${roleArn}`);
      } else {
        console.error('Error checking IAM Role:', error);
        throw error;
      }
    }

    // Fetch the DynamoDB Table ARN dynamically
    const dynamoDbArn = await getDynamoDBArn();
    const tableName = dynamoDbArn?.split('/').pop();
    if (!tableName) {
      throw new Error('Failed to extract DynamoDB table name from ARN');
    }

    // Create IoT Core Rule
    const rulePayload = {
      sql: `SELECT *, clientid() AS DeviceId, timestamp() AS Timestamp FROM '+/telemetry'`,
      ruleDisabled: false,
      actions: [
        {
          dynamoDBv2: {
            roleArn,
            putItem: { tableName },
          },
        },
      ],
    };

    await iot
      .createTopicRule({
        ruleName,
        topicRulePayload: rulePayload,
      })
      .promise();

    console.log(`IoT Core Rule "${ruleName}" created successfully.`);

    // Fetch IoT Core endpoint and tag it
    const endpoint = await iot.describeEndpoint({ endpointType: 'iot:Data-ATS' }).promise();
    const iotCoreEndpoint = endpoint.endpointAddress;

    if (iotCoreEndpoint) {
      await addTag(iotCoreEndpoint, 'ResourceType', 'IoTCore');
      console.log(`IoT Core endpoint "${iotCoreEndpoint}" tagged for discovery.`);
    }
  } catch (error: unknown) {
    console.error('IoT Core setup failed:', error);
    throw error;
  }
};

/**
 * Checks if an error is an AWS error.
 */
function isAWSError(error: unknown): error is AWSError {
  return typeof error === 'object' && error !== null && 'code' in error && 'message' in error;
}

/**
 * Fetches the DynamoDB ARN from resource discovery.
 */
async function getDynamoDBArn(): Promise<string | undefined> {
  // Implement your logic to retrieve the DynamoDB ARN using tags
  const dynamoDbArn = await getResourceArn('ResourceType', 'DynamoDBTable');
  if (!dynamoDbArn) {
    throw new Error('Unable to find the DynamoDB table ARN with the tag "ResourceType: DynamoDBTable"');
  }
  return dynamoDbArn;
}
