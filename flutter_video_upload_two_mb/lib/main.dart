import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  Future<void> _pickAndUploadVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null) {
      File videoFile = File(result.files.single.path!);
      await uploadVideo(videoFile);
    } else {
      // User canceled the picker
      print("User canceled video selection");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Upload Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _pickAndUploadVideo,
          child: Text('Select and Upload Video'),
        ),
      ),
    );
  }
}

Future<void> uploadVideo(File videoFile) async {
  final int maxPacketSize = 2 * 1024 * 1024; // 2 MB
  final String uploadUrl = "https://localhost:7045/api/FileUpload/upload"; // Replace with your API endpoint

  try {
    final int fileSize = await videoFile.length();

    if (fileSize <= maxPacketSize) {
      await _uploadSingleRequest(videoFile, uploadUrl);
    } else {
      await _uploadInPackets(videoFile, uploadUrl, maxPacketSize);
    }
  } catch (e) {
    print("Error uploading video: $e");
  }
}

Future<void> _uploadSingleRequest(File videoFile, String uploadUrl) async {
  try {
    final Dio dio = Dio();

    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(
        videoFile.path,
        filename: "video.mp4",
      ),
    });

    Response response = await dio.post(uploadUrl, data: formData);

    print("Upload successful. Response: ${response.data}");
  } catch (e) {
    print("Error uploading video: $e");
  }
}

Future<void> _uploadInPackets(File videoFile, String uploadUrl, int maxPacketSize) async {
  try {
    final Dio dio = Dio();
    final int fileSize = await videoFile.length();
    int start = 0;

    while (start < fileSize) {
      int end = (start + maxPacketSize < fileSize) ? start + maxPacketSize : fileSize;

      List<int> bytes = await videoFile.readAsBytes();
      List<int> packet = bytes.sublist(start, end);

      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(packet, filename: "video.mp4"),
      });

      Response response = await dio.post(uploadUrl, data: formData);

      print("Uploaded packet $start to $end. Response: ${response.data}");

      start = end;
    }

    print("Upload complete.");
  } catch (e) {
    print("Error uploading video in packets: $e");
  }
}