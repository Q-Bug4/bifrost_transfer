// Mocks generated by Mockito 5.4.2 from annotations
// in bifrost_transfer/test/mocks/mock_connection_service.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:bifrost_transfer/application/models/connection_model.dart'
    as _i5;
import 'package:bifrost_transfer/application/models/device_info_model.dart'
    as _i2;
import 'package:bifrost_transfer/application/services/connection_service.dart'
    as _i3;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeDeviceInfoModel_0 extends _i1.SmartFake
    implements _i2.DeviceInfoModel {
  _FakeDeviceInfoModel_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [ConnectionService].
///
/// See the documentation for Mockito's code generation for more information.
class MockConnectionService extends _i1.Mock implements _i3.ConnectionService {
  MockConnectionService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Stream<_i5.ConnectionModel> get connectionStateStream =>
      (super.noSuchMethod(
        Invocation.getter(#connectionStateStream),
        returnValue: _i4.Stream<_i5.ConnectionModel>.empty(),
      ) as _i4.Stream<_i5.ConnectionModel>);

  @override
  _i4.Stream<Map<String, dynamic>> get connectionRequestStream =>
      (super.noSuchMethod(
        Invocation.getter(#connectionRequestStream),
        returnValue: _i4.Stream<Map<String, dynamic>>.empty(),
      ) as _i4.Stream<Map<String, dynamic>>);

  @override
  _i4.Future<_i2.DeviceInfoModel> getLocalDeviceInfo() => (super.noSuchMethod(
        Invocation.method(
          #getLocalDeviceInfo,
          [],
        ),
        returnValue:
            _i4.Future<_i2.DeviceInfoModel>.value(_FakeDeviceInfoModel_0(
          this,
          Invocation.method(
            #getLocalDeviceInfo,
            [],
          ),
        )),
      ) as _i4.Future<_i2.DeviceInfoModel>);

  @override
  _i4.Future<String> initiateConnection(String? targetIp) =>
      (super.noSuchMethod(
        Invocation.method(
          #initiateConnection,
          [targetIp],
        ),
        returnValue: _i4.Future<String>.value(''),
      ) as _i4.Future<String>);

  @override
  _i4.Future<bool> acceptConnection(
    String? initiatorIp,
    String? pairingCode,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #acceptConnection,
          [
            initiatorIp,
            pairingCode,
          ],
        ),
        returnValue: _i4.Future<bool>.value(false),
      ) as _i4.Future<bool>);

  @override
  _i4.Future<void> rejectConnection(String? initiatorIp) => (super.noSuchMethod(
        Invocation.method(
          #rejectConnection,
          [initiatorIp],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> disconnect() => (super.noSuchMethod(
        Invocation.method(
          #disconnect,
          [],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> cancelConnection() => (super.noSuchMethod(
        Invocation.method(
          #cancelConnection,
          [],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> simulateIncomingConnectionRequest(
    String? deviceIp,
    String? deviceName,
    String? pairingCode,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #simulateIncomingConnectionRequest,
          [
            deviceIp,
            deviceName,
            pairingCode,
          ],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);
}
