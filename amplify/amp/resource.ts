import { addTag } from '../resource-discovery/helper';
import { getCloudFormationOutput } from '../resource-discovery/helper';

// Define the CloudFormation stack name dynamically if not hardcoded
const HOSTING_STACK_NAME = 'amplify-yourprojectname-env'; // Replace with your Amplify project stack name

/**
 * Setup and tag the web app URL for discovery.
 */
export const setupAmpResources = async () => {
  try {
    console.log(`Fetching WEB_APP_URL from stack: ${HOSTING_STACK_NAME}`);

    // Fetch the WEB_APP_URL dynamically from CloudFormation Outputs
    const webAppUrl = await getCloudFormationOutput(HOSTING_STACK_NAME, 'WEB_APP_URL');
    if (!webAppUrl) {
      throw new Error('WEB_APP_URL not found in CloudFormation outputs.');
    }

    // Tag the URL for resource discovery
    await addTag(webAppUrl, 'ResourceType', 'WebAppURL');
    console.log(`WEB_APP_URL tagged successfully: ${webAppUrl}`);
  } catch (error) {
    console.error('Error setting up Amplify resources:', error);
    throw error;
  }
};

/**
 * Utility function to fetch the web app URL on demand.
 */
export const webAppUrl = async (): Promise<string> => {
  const url = await getCloudFormationOutput(HOSTING_STACK_NAME, 'WEB_APP_URL');
  if (!url) {
    throw new Error('WEB_APP_URL not found in CloudFormation outputs.');
  }
  return url;
};
