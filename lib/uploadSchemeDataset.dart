
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

const Color _primaryBlue = Color(0xFF2457C5);

class UploadSchemeDataset extends StatefulWidget {
  const UploadSchemeDataset({super.key});

  @override
  State<UploadSchemeDataset> createState() =>
      _UploadSchemeDatasetState();
}

class _UploadSchemeDatasetState extends State<UploadSchemeDataset> {
  bool _isUploading = false;
  String _message = '';
  bool _isError = false;

  final List<String> requiredFields = [
    'scheme_id',
    'scheme_name',
    'description',
    'scheme_type',
    'provider_name',
    'government_level',
    'state',
    'academic_year',
    'education_levels',
    'courses',
    'min_age',
    'max_age',
    'categories',
    'max_family_income',
    'min_percentage',
    'mandatory_conditions',
    'benefit_type',
    'benefit_amount',
    'application_start_date',
    'application_deadline',
    'application_url',
    'source_url',
    'last_verified_at',
    'required_documents',
    'reminder_days',
    'status',
  ];

  final Set<String> jsonFields = {
    'education_levels',
    'courses',
    'categories',
    'mandatory_conditions',
    'required_documents',
    'reminder_days',
  };

  final Set<String> numericFields = {
    'min_age',
    'max_age',
    'max_family_income',
    'min_percentage',
  };

  Future<void> _pickAndUploadFile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please log in first.', isError: true);
      return;
    }

    String fileName = '';
    int totalRecords = 0;
    int addedRecords = 0;
    int updatedRecords = 0;
    bool uploadSucceeded = false;
    String? errorDetails;

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (!adminDoc.exists ||
          adminDoc.data()?['role'] != 'admin') {
        _showMessage(
          'Only authorized administrators can upload datasets.',
          isError: true,
        );
        return;
      }

      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json'],
      );

      if (files.isEmpty) return;

      final file = files.first;
      fileName = file.name;

      final bytes = await file.readAsBytes();
      final content = utf8.decode(
        bytes,
        allowMalformed: false,
      );

      final extension = file.extension?.toLowerCase();

      late List<Map<String, dynamic>> schemes;

      if (extension == 'csv') {
        schemes = _parseCsv(content);
      } else if (extension == 'json') {
        schemes = _parseJson(content);
      } else {
        throw Exception('Please select a CSV or JSON file.');
      }

      _validateSchemes(schemes);

      if (schemes.isEmpty) {
        throw Exception('The selected file contains no schemes.');
      }

      totalRecords = schemes.length;

      if (!mounted) return;

      setState(() {
        _isUploading = true;
        _message = 'Checking existing schemes...';
        _isError = false;
      });

      final firestore = FirebaseFirestore.instance;

      // Count existing documents before uploading.
      // These counts are estimates if another admin uploads
      // the same scheme IDs at the same time.
      for (var start = 0;
          start < schemes.length;
          start += 30) {
        final end = (start + 30 < schemes.length)
            ? start + 30
            : schemes.length;

        final snapshots = await Future.wait(
          schemes.sublist(start, end).map((scheme) {
            return firestore
                .collection('schemes')
                .doc(scheme['scheme_id'].toString())
                .get();
          }),
        );

        for (final snapshot in snapshots) {
          if (snapshot.exists) {
            updatedRecords++;
          } else {
            addedRecords++;
          }
        }
      }

      setState(() {
        _message = 'Uploading $totalRecords schemes...';
      });

      await _saveToFirestore(schemes, user.uid);

      uploadSucceeded = true;
    } catch (e) {
      errorDetails = e.toString();
    } finally {
      if (fileName.isNotEmpty) {
        final status = uploadSucceeded
            ? 'success'
            : (errorDetails != null &&
                    (addedRecords + updatedRecords > 0))
                ? 'partial'
                : 'failed';

        try {
          await FirebaseFirestore.instance
              .collection('upload_history')
              .add({
            'fileName': fileName,
            'totalRecords': totalRecords,
            'addedRecords': addedRecords,
            'updatedRecords': updatedRecords,
            'status': status,
            'uploadedBy': user.email ?? user.uid,
            'uploadedByUid': user.uid,
            'uploadedAt': FieldValue.serverTimestamp(),
            'errorDetails': errorDetails ?? '',
          });
        } catch (historyError) {
          debugPrint(
            'Failed to save upload history: $historyError',
          );

          errorDetails = errorDetails == null
              ? 'Dataset upload finished, but its history could not be saved. '
                  'Check Firestore rules and connection.'
              : '$errorDetails\nHistory save error: $historyError';
        }
      }

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }

    if (!mounted) return;

    if (uploadSucceeded && errorDetails == null) {
      // Open upload history automatically after success.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const DatasetUploadHistoryPage(),
        ),
      );
    } else if (uploadSucceeded) {
      _showMessage(
        'Dataset uploaded, but history could not be saved. '
        '$errorDetails',
        isError: true,
      );
    } else if (errorDetails != null) {
      _showMessage(
        'Upload failed: $errorDetails',
        isError: true,
      );
    }
  }

  List<Map<String, dynamic>> _parseCsv(String content) {
    final rows = csv.decode(content);

    if (rows.isEmpty) {
      throw Exception('The CSV file is empty.');
    }

    final headers = rows.first
        .map((value) => value.toString().trim())
        .toList();

    if (headers.toSet().length != headers.length) {
      throw Exception(
        'The CSV contains duplicate column names.',
      );
    }

    final missingHeaders = requiredFields
        .where((field) => !headers.contains(field))
        .toList();

    if (missingHeaders.isNotEmpty) {
      throw Exception(
        'Missing CSV columns: ${missingHeaders.join(', ')}',
      );
    }

    final schemes = <Map<String, dynamic>>[];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];

      if (row.every(
        (value) => value.toString().trim().isEmpty,
      )) {
        continue;
      }

      if (row.length != headers.length) {
        throw Exception(
          'CSV row ${i + 1} has ${row.length} values, '
          'but ${headers.length} columns are expected.',
        );
      }

      final scheme = <String, dynamic>{};

      for (var j = 0; j < headers.length; j++) {
        scheme[headers[j]] = row[j].toString().trim();
      }

      schemes.add(_convertFields(scheme));
    }

    return schemes;
  }

  List<Map<String, dynamic>> _parseJson(String content) {
    final decoded = jsonDecode(content);

    if (decoded is! List) {
      throw Exception(
        'The JSON file must contain a list of scheme objects.',
      );
    }

    final schemes = <Map<String, dynamic>>[];

    for (var i = 0; i < decoded.length; i++) {
      final item = decoded[i];

      if (item is! Map) {
        throw Exception(
          'JSON item ${i + 1} must be an object.',
        );
      }

      schemes.add(
        _convertFields(Map<String, dynamic>.from(item)),
      );
    }

    return schemes;
  }

  Map<String, dynamic> _convertFields(
    Map<String, dynamic> scheme,
  ) {
    final converted = <String, dynamic>{};

    for (final field in requiredFields) {
      final value = scheme[field];

      if (jsonFields.contains(field)) {
        if (value == null ||
            value.toString().trim().isEmpty) {
          converted[field] = <dynamic>[];
        } else if (value is String) {
          converted[field] = jsonDecode(value);
        } else {
          converted[field] = value;
        }
      } else if (numericFields.contains(field)) {
        if (value == null ||
            value.toString().trim().isEmpty) {
          converted[field] = null;
        } else {
          final number = num.tryParse(value.toString());

          if (number == null) {
            throw Exception(
              '"$field" must be a valid number. '
              'Invalid value: $value',
            );
          }

          converted[field] = number;
        }
      } else {
        converted[field] =
            value?.toString().trim() ?? '';
      }
    }

    return converted;
  }

  void _validateSchemes(
    List<Map<String, dynamic>> schemes,
  ) {
    final seenIds = <String>{};

    for (var i = 0; i < schemes.length; i++) {
      final scheme = schemes[i];

      for (final field in requiredFields) {
        if (!scheme.containsKey(field)) {
          throw Exception(
            'Scheme ${i + 1} is missing field "$field".',
          );
        }
      }

      final id =
          scheme['scheme_id']?.toString().trim() ?? '';
      final name =
          scheme['scheme_name']?.toString().trim() ?? '';

      if (id.isEmpty) {
        throw Exception(
          'Scheme ${i + 1} has an empty scheme_id.',
        );
      }

      if (name.isEmpty) {
        throw Exception(
          'Scheme $id has an empty scheme_name.',
        );
      }

      if (!seenIds.add(id)) {
        throw Exception(
          'Duplicate scheme_id "$id" found in the file.',
        );
      }
    }
  }

  Future<void> _saveToFirestore(
    List<Map<String, dynamic>> schemes,
    String uid,
  ) async {
    final firestore = FirebaseFirestore.instance;

    // Each batch has at most 400 writes.
    // If a later batch fails, earlier batches remain committed.
    for (var start = 0;
        start < schemes.length;
        start += 400) {
      final end = (start + 400 < schemes.length)
          ? start + 400
          : schemes.length;

      final batch = firestore.batch();

      for (final scheme in schemes.sublist(start, end)) {
        final schemeId = scheme['scheme_id'].toString();

        final ref = firestore
            .collection('schemes')
            .doc(schemeId);

        batch.set(ref, {
          ...scheme,
          'updatedAt': FieldValue.serverTimestamp(),
          'uploadedBy': uid,
        });
      }

      await batch.commit();
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    setState(() {
      _message = message;
      _isError = isError;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Scheme Dataset'),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_upload_outlined,
                      size: 72,
                      color: _primaryBlue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Upload Government Scheme Dataset',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Select a CSV or JSON file containing '
                      'the required scheme columns.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading
                            ? null
                            : _pickAndUploadFile,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(
                          _isUploading
                              ? 'Uploading...'
                              : 'Choose File and Upload',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isError
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Expected format: CSV or JSON',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// DATASET UPLOAD HISTORY PAGE
// ------------------------------------------------------------

class DatasetUploadHistoryPage extends StatelessWidget {
  const DatasetUploadHistoryPage({super.key});

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate().toLocal();

      String twoDigits(int n) => n.toString().padLeft(2, '0');

      return '${twoDigits(date.day)}/'
          '${twoDigits(date.month)}/${date.year} '
          '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
    }

    return 'Date pending';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dataset Upload History'),
        backgroundColor: const Color(0xFF1B3F7A),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('upload_history')
            .orderBy('uploadedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load upload history.\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 76,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No upload history yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Upload history will appear here after '
                      'a dataset upload is recorded.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final data = documents[index].data();

              final status =
                  (data['status'] ?? 'unknown').toString();

              final statusColor = status == 'success'
                  ? Colors.green
                  : status == 'partial'
                      ? Colors.orange
                      : Colors.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: ExpansionTile(
                  leading: Icon(
                    status == 'success'
                        ? Icons.check_circle
                        : status == 'partial'
                            ? Icons.warning_amber
                            : Icons.error,
                    color: statusColor,
                    size: 32,
                  ),
                  title: Text(
                    (data['fileName'] ?? 'Unknown file')
                        .toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${_formatDate(data['uploadedAt'])}\n'
                    'Status: ${status.toUpperCase()}',
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(
                    16, 0, 16, 16,
                  ),
                  children: [
                    _historyRow(
                      'Total records',
                      data['totalRecords'],
                    ),
                    _historyRow(
                      'Added',
                      data['addedRecords'],
                    ),
                    _historyRow(
                      'Overwritten',
                      data['updatedRecords'],
                    ),
                    _historyRow(
                      'Uploaded by',
                      data['uploadedBy'],
                    ),
                    if ((data['errorDetails'] ?? '')
                        .toString()
                        .isNotEmpty)
                      _historyRow(
                        'Details',
                        data['errorDetails'],
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _historyRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? '-'),
          ),
        ],
      ),
    );
  }
}
