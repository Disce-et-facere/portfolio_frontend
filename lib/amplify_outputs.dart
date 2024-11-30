const amplifyConfig = '''{
  "auth": {
    "user_pool_id": "eu-central-1_8CahOmFtu",
    "aws_region": "eu-central-1",
    "user_pool_client_id": "607439gcflutsmha0cfd3vri08",
    "identity_pool_id": "eu-central-1:e63e7105-19ca-4765-aa6e-75459a4bd023",
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
    "url": "https://trmwgi2xcnafrgqnbattumvuei.appsync-api.eu-central-1.amazonaws.com/graphql",
    "aws_region": "eu-central-1",
    "api_key": "da2-jf53dllybzhodekqudjxgavw3m",
    "default_authorization_type": "AMAZON_COGNITO_USER_POOLS",
    "authorization_types": [
      "API_KEY",
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
            "data": {
              "name": "data",
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
                  },
                  {
                    "allow": "public",
                    "provider": "apiKey",
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
      "nonModels": {},
      "mutations": {
        "addTelemetry": {
          "name": "addTelemetry",
          "isArray": false,
          "type": "AWSJSON",
          "isRequired": false,
          "arguments": {
            "device_id": {
              "name": "device_id",
              "isArray": false,
              "type": "String",
              "isRequired": true
            },
            "timestamp": {
              "name": "timestamp",
              "isArray": false,
              "type": "AWSTimestamp",
              "isRequired": true
            },
            "ownerID": {
              "name": "ownerID",
              "isArray": false,
              "type": "String",
              "isRequired": true
            },
            "data": {
              "name": "data",
              "isArray": false,
              "type": "AWSJSON",
              "isRequired": true
            }
          }
        }
      }
    }
  },
  "version": "1.1"
}''';