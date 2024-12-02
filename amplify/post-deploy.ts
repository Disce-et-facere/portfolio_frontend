const { postDeploy } = require('./backend');

(async () => {
  try {
    console.log("Running post-deployment tasks...");
    await postDeploy();
    console.log("Post-deployment tasks completed successfully.");
  } catch (error) {
    console.error("Error running post-deployment tasks:", error);
    process.exit(1);
  }
})();