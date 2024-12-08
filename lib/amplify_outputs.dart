const amplifyConfig = r'''{
  "auth": {
    "user_pool_id": "eu-central-1_QHNxbmIRZ",
    "aws_region": "eu-central-1",
    "user_pool_client_id": "2m3mt1k00custflj84eb6sqh25",
    "identity_pool_id": "eu-central-1:e80b5b0f-f662-4791-80fd-3209b3d81de7",
    "mfa_methods": [],
    "standard_required_attributes": [
      "email"
    ],
    "username_attributes": [
      "email"
    ],
    "user_verification_types": [
      "email"
    ],
    "groups": [],
    "mfa_configuration": "NONE",
    "password_policy": {
      "min_length": 8,
      "require_lowercase": true,
      "require_numbers": true,
      "require_symbols": true,
      "require_uppercase": true
    },
    "unauthenticated_identities_enabled": true
  },
  "data": {
    "url": "https://zxu2gfqq7zcxvdadrtpkntxg7q.appsync-api.eu-central-1.amazonaws.com/graphql",
    "aws_region": "eu-central-1",
    "default_authorization_type": "AMAZON_COGNITO_USER_POOLS",
    "authorization_types": [
      "AWS_IAM"
    ],
    "model_introspection": {
      "version": 1,
      "models": {
        "telemetry": {
          "name": "telemetry",
          "fields": {
            "device_id": {
              "name": "device_id",
              "isArray": false,
              "type": "String",
              "isRequired": true,
              "attributes": []
            },
            "timestamp": {
              "name": "timestamp",
              "isArray": false,
              "type": "AWSTimestamp",
              "isRequired": true,
              "attributes": []
            },
            "ownerID": {
              "name": "ownerID",
              "isArray": false,
              "type": "String",
              "isRequired": true,
              "attributes": []
            },
            "deviceData": {
              "name": "deviceData",
              "isArray": false,
              "type": "AWSJSON",
              "isRequired": true,
              "attributes": []
            },
            "createdAt": {
              "name": "createdAt",
              "isArray": false,
              "type": "AWSDateTime",
              "isRequired": false,
              "attributes": [],
              "isReadOnly": true
            },
            "updatedAt": {
              "name": "updatedAt",
              "isArray": false,
              "type": "AWSDateTime",
              "isRequired": false,
              "attributes": [],
              "isReadOnly": true
            }
          },
          "syncable": true,
          "pluralName": "telemetries",
          "attributes": [
            {
              "type": "model",
              "properties": {}
            },
            {
              "type": "key",
              "properties": {
                "fields": [
                  "device_id",
                  "timestamp"
                ]
              }
            },
            {
              "type": "key",
              "properties": {
                "name": "OwnerIDIndex",
                "queryField": "listDevicesByOwnerID",
                "fields": [
                  "ownerID",
                  "timestamp"
                ]
              }
            },
            {
              "type": "auth",
              "properties": {
                "rules": [
                  {
                    "allow": "private",
                    "provider": "userPools",
                    "operations": [
                      "create",
                      "update",
                      "delete",
                      "read"
                    ]
                  }
                ]
              }
            }
          ],
          "primaryKeyInfo": {
            "isCustomPrimaryKey": true,
            "primaryKeyFieldName": "device_id",
            "sortKeyFieldNames": [
              "timestamp"
            ]
          }
        }
      },
      "enums": {},
      "nonModels": {}
    }
  },
  "version": "1.3"
}''';