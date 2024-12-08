const amplifyConfig = r'''{
  "auth": {
    "user_pool_id": "eu-central-1_88eXAfDBZ",
    "aws_region": "eu-central-1",
    "user_pool_client_id": "3qn78b37d34pc0q7br9iq2so4b",
    "identity_pool_id": "eu-central-1:52f99b3a-6ade-41bf-b45d-050019c8b7ed",
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
    "url": "https://wbsmmvnuwjd57fivijzqsspg44.appsync-api.eu-central-1.amazonaws.com/graphql",
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