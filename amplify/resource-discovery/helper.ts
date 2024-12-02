import AWS from 'aws-sdk';

// Initialize the Tagging API client
const taggingAPI = new AWS.ResourceGroupsTaggingAPI();
const cloudFormation = new AWS.CloudFormation();

/**
 * Fetches a resource ARN by tag key-value pair.
 * @param tagKey The tag key to search for
 * @param tagValue The tag value to match
 * @returns The ARN of the matched resource or undefined
 */
export async function getResourceArn(tagKey: string, tagValue: string): Promise<string | undefined> {
  const result = await taggingAPI
    .getResources({
      TagFilters: [{ Key: tagKey, Values: [tagValue] }],
    })
    .promise();

  return result.ResourceTagMappingList?.[0]?.ResourceARN;
}

/**
 * Adds a tag to a resource.
 * @param resourceArn The ARN of the resource to tag
 * @param tagKey The key of the tag
 * @param tagValue The value of the tag
 */
export async function addTag(resourceArn: string, tagKey: string, tagValue: string): Promise<void> {
  await taggingAPI
    .tagResources({
      ResourceARNList: [resourceArn],
      Tags: {
        [tagKey]: tagValue,
      },
    })
    .promise();
}

/**
 * Fetches a CloudFormation stack output value by output key.
 * @param stackName The name of the stack
 * @param outputKey The key of the desired output
 * @returns The value of the output or undefined
 */
export async function getCloudFormationOutput(
  stackName: string,
  outputKey: string
): Promise<string | undefined> {
  try {
    const { Stacks } = await cloudFormation.describeStacks({ StackName: stackName }).promise();
    const stack = Stacks?.[0];
    if (!stack) {
      throw new Error(`Stack "${stackName}" not found.`);
    }

    const output = stack.Outputs?.find((o) => o.OutputKey === outputKey);
    return output?.OutputValue;
  } catch (error) {
    console.error(`Error fetching output "${outputKey}" from stack "${stackName}":`, error);
    throw error;
  }
}
