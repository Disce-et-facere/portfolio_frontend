/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;


/** Thiss is an auto generated class representing the telemetry type in your schema. */
class telemetry extends amplify_core.Model {
  static const classType = const _telemetryModelType();
  final String? _device_id;
  final amplify_core.TemporalTimestamp? _timestamp;
  final String? _ownerID;
  final String? _deviceData;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => modelIdentifier.serializeAsString();
  
  telemetryModelIdentifier get modelIdentifier {
    try {
      return telemetryModelIdentifier(
        device_id: _device_id!,
        timestamp: _timestamp!
      );
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get device_id {
    try {
      return _device_id!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalTimestamp get timestamp {
    try {
      return _timestamp!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get ownerID {
    try {
      return _ownerID!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get deviceData {
    try {
      return _deviceData!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  const telemetry._internal({required device_id, required timestamp, required ownerID, required deviceData, createdAt, updatedAt}): _device_id = device_id, _timestamp = timestamp, _ownerID = ownerID, _deviceData = deviceData;
  
  factory telemetry({required String device_id, required amplify_core.TemporalTimestamp timestamp, required String ownerID, required String deviceData}) {
    return telemetry._internal(
      device_id: device_id,
      timestamp: timestamp,
      ownerID: ownerID,
      deviceData: deviceData);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is telemetry &&
      _device_id == other._device_id &&
      _timestamp == other._timestamp &&
      _ownerID == other._ownerID &&
      _deviceData == other._deviceData;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("telemetry {");
    buffer.write("device_id=" + "$_device_id" + ", ");
    buffer.write("timestamp=" + (_timestamp != null ? _timestamp.toString() : "null") + ", ");
    buffer.write("ownerID=" + "$_ownerID" + ", ");
    buffer.write("deviceData=" + "$_deviceData" + ", ");
    buffer.write("}");
    
    return buffer.toString();
  }
  
  telemetry copyWith({String? ownerID, String? deviceData}) {
    return telemetry._internal(
      device_id: device_id,
      timestamp: timestamp,
      ownerID: ownerID ?? this.ownerID,
      deviceData: deviceData ?? this.deviceData);
  }
  
  telemetry copyWithModelFieldValues({
    ModelFieldValue<String>? ownerID,
    ModelFieldValue<String>? deviceData
  }) {
    return telemetry._internal(
      device_id: device_id,
      timestamp: timestamp,
      ownerID: ownerID == null ? this.ownerID : ownerID.value,
      deviceData: deviceData == null ? this.deviceData : deviceData.value
    );
  }
  
  telemetry.fromJson(Map<String, dynamic> json)  
    : _device_id = json['device_id'],
      _timestamp = json['timestamp'] != null ? amplify_core.TemporalTimestamp.fromSeconds(json['timestamp']) : null,
      _ownerID = json['ownerID'],
      _deviceData = json['deviceData'];
  
  Map<String, dynamic> toJson() => {
    'device_id': _device_id, 'timestamp': _timestamp?.toSeconds(), 'ownerID': _ownerID, 'deviceData': _deviceData,
  };
  
  Map<String, Object?> toMap() => {
    'device_id': _device_id,
    'timestamp': _timestamp,
    'ownerID': _ownerID,
    'deviceData': _deviceData,
  };

  static final amplify_core.QueryModelIdentifier<telemetryModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<telemetryModelIdentifier>();
  static final DEVICE_ID = amplify_core.QueryField(fieldName: "device_id");
  static final TIMESTAMP = amplify_core.QueryField(fieldName: "timestamp");
  static final OWNERID = amplify_core.QueryField(fieldName: "ownerID");
  static final DEVICEDATA = amplify_core.QueryField(fieldName: "deviceData");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "telemetry";
    modelSchemaDefinition.pluralName = "telemetries";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["device_id", "timestamp"], name: null),
      amplify_core.ModelIndex(fields: const ["ownerID", "timestamp"], name: "OwnerIDIndex")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: telemetry.DEVICE_ID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: telemetry.TIMESTAMP,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.timestamp)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: telemetry.OWNERID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: telemetry.DEVICEDATA,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'createdAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'updatedAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _telemetryModelType extends amplify_core.ModelType<telemetry> {
  const _telemetryModelType();
  
  @override
  telemetry fromJson(Map<String, dynamic> jsonData) {
    return telemetry.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'telemetry';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [telemetry] in your schema.
 */
class telemetryModelIdentifier implements amplify_core.ModelIdentifier<telemetry> {
  final String device_id;
  final amplify_core.TemporalTimestamp timestamp;

  /**
   * Create an instance of telemetryModelIdentifier using [device_id] the primary key.
   * And [timestamp] the sort key.
   */
  const telemetryModelIdentifier({
    required this.device_id,
    required this.timestamp});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'device_id': device_id,
    'timestamp': timestamp
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'telemetryModelIdentifier(device_id: $device_id, timestamp: $timestamp)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is telemetryModelIdentifier &&
      device_id == other.device_id &&
      timestamp == other.timestamp;
  }
  
  @override
  int get hashCode =>
    device_id.hashCode ^
    timestamp.hashCode;
}