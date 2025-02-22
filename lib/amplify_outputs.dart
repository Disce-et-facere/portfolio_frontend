const amplifyConfig = r'''{
  "auth": {
    "user_pool_id": "eu-central-1_TWpxL4IpN",
    "aws_region": "eu-central-1",
    "user_pool_client_id": "23dijkdufcap0mpfq7b8uf1ito",
    "identity_pool_id": "eu-central-1:816df2a0-b970-476b-882e-bf73e77be32c",
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
    "url": "https://hsd44tek75dvne3sdfrpj3yejq.appsync-api.eu-central-1.amazonaws.com/graphql",
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
              "type": "AWSTimestamp",
              "isRequired": true,
              "attributes": []
            },
            "updatedAt": {
              "name": "updatedAt",
              "isArray": false,
              "type": "AWSTimestamp",
              "isRequired": true,
              "attributes": []
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
      "nonModels": {
        "FetchShadowResponse": {
          "name": "FetchShadowResponse",
          "fields": {
            "deviceId": {
              "name": "deviceId",
              "isArray": false,
              "type": "String",
              "isRequired": true,
              "attributes": []
            },
            "status": {
              "name": "status",
              "isArray": false,
              "type": "String",
              "isRequired": false,
              "attributes": []
            },
            "deviceData": {
              "name": "deviceData",
              "isArray": false,
              "type": "AWSJSON",
              "isRequired": false,
              "attributes": []
            }
          }
        }
      },
      "queries": {
        "fetchDeviceShadow": {
          "name": "fetchDeviceShadow",
          "isArray": false,
          "type": {
            "nonModel": "FetchShadowResponse"
          },
          "isRequired": false,
          "arguments": {
            "deviceId": {
              "name": "deviceId",
              "isArray": false,
              "type": "String",
              "isRequired": true
            }
          }
        }
      }
    }
  },
  "version": "1.1"
}''';