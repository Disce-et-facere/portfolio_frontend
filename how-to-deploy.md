# Deploment setup

1. clone repo

2. deploy with aws amplify (will fail to build the 1st time!)

3. Add secrets to amplify secrets (you need to manually navigate and find 
the values on AWS CLI, website)

4. create 4 different http api's with api gateway
   1. createDeviceAPI  
      - POST route with jwt auth integrated with createDeviceLambda  
      - OPTIONS route with integration http URI pointing toward the frontend URL  
      - set cors accordingly  
   2. fetchDevicesAPI  
      - GET route with jwt auth integrated with fetchDevicesLambda  
      - OPTIONS route with integration http URI pointing toward the frontend URL  
      - set cors accordingly  
   3. fetchDeviceDataAPI  
      - GET route with jwt auth integrated with fetchDeviceDataLambda  
      - OPTIONS route with integration http URI pointing toward the frontend URL  
      - set cors accordingly  
   4. deleteDeviceDataAPI  
      - DELETE route with jwt auth integrated with deleteDeviceLambda  
      - OPTIONS route with integration http URI pointing toward the frontend URL  
      - set cors accordingly  
5. set iot Core/ message route/ rule to:  

   ```sql
   SELECT *, 
   clientid() AS device_id, 
   floor(timestamp() / 1000) AS timestamp, 
   floor(timestamp() / 1000) AS createdAt, 
   floor(timestamp() / 1000) AS updatedAt FROM '+/telemetry'
   ```

6.  set iotcore policy for incoming pubs

7.  set permission for iot core to send data to dynamoDB

8.  ReDeploy!

