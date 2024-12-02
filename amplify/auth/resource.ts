import { defineAuth } from '@aws-amplify/backend';
import { addTag } from '../resource-discovery/helper'; // For tagging resources
import AWS from 'aws-sdk';

export const auth = defineAuth({
  loginWith: {
    email: true,
  },
  userAttributes: {
    "custom:OwnerID": {
      dataType: "String",
      mutable: true,
    },
  },
});

/**
 * Post-deployment logic to tag Cognito resources for discovery.
 */
export const tagCognitoResources = async () => {
  const cognito = new AWS.CognitoIdentityServiceProvider();

  try {
    // Fetch all user pools (assuming single user pool for simplicity)
    const userPools = await cognito.listUserPools({ MaxResults: 10 }).promise();
    const userPool = userPools.UserPools?.[0];

    if (!userPool || !userPool.Id) {
      throw new Error('No Cognito User Pool found during tagging.');
    }

    const userPoolArn = `arn:aws:cognito-idp:${process.env.AWS_REGION}:${process.env.AWS_ACCOUNT_ID}:userpool/${userPool.Id}`;
    const appClients = await cognito.listUserPoolClients({ UserPoolId: userPool.Id }).promise();
    const appClientId = appClients.UserPoolClients?.[0]?.ClientId;

    if (!appClientId) {
      throw new Error('No Cognito App Client found.');
    }

    // Tagging the User Pool
    await addTag(userPoolArn, 'ResourceType', 'UserPool');
    console.log(`Tagged Cognito User Pool: ${userPoolArn}`);

    // Store outputs as environment variables or pass them to downstream services
    process.env.COGNITO_USER_POOL_ID = userPool.Id;
    process.env.COGNITO_ISSUER_URL = `https://cognito-idp.${process.env.AWS_REGION}.amazonaws.com/${userPool.Id}`;
    process.env.COGNITO_APP_CLIENT_ID = appClientId;
  } catch (error) {
    console.error('Error tagging Cognito resources:', error);
    throw error;
  }
};
