import { postDeploy } from './backend'; // Import your postDeploy function

(async () => {
  try {
    console.log('Running post-deployment tasks...');
    await postDeploy();
    console.log('Post-deployment tasks completed successfully.');
  } catch (error) {
    console.error('Error during post-deployment tasks:', error);
    process.exit(1);
  }
})();
