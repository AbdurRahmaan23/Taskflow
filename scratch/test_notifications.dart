import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/data/data_sources/mock_data_source.dart';
import 'dart:io';
import 'dart:convert';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Mock asset loading
  final mockData = File('assets/mock_data/mock-data.json').readAsStringSync();
  
  // Set up mock platform channel for rootBundle
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
    'flutter/assets',
    (ByteData? message) async {
      return const StringCodec().encodeMessage(mockData);
    },
  );

  final ds = MockDataSource();
  
  final creds = await ds.getUserCredentials('ava.admin@nimbusdigital.test');
  print('Logged in as user ID: ${creds.id}');
  
  final notifs = await ds.getNotifications(creds.id);
  print('Found ${notifs.length} notifications');
}
