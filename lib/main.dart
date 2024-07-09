import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        title: 'Welcome to the Location Checker',
        debugShowCheckedModeBanner: false,
        home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _video;
  VideoPlayerController? _controller;
  final ImagePicker _picker = ImagePicker();

  // 实现 _selectVideo 方法
  void _selectVideo() async {
    final XFile? pickedFile =
        await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      _video = File(pickedFile.path);
      _controller = VideoPlayerController.file(_video!)
        ..initialize().then((_) {
          setState(() {}); // 更新UI
          _controller!.play();
        });
      print('Video selected: ${_video!.path}');
    } else {
      print('No video selected.');
    }
  }

  void _uploadVideo() async{
    // 上传视频的处理逻辑
    print('Upload Video');
    if(_video != null){
      List<int> videoBytes = await _video!.readAsBytes();
      String fileName = _video!.path.split('/').last;

      var request = http.MultipartRequest('POST', Uri.parse('http://192.168.1.24:80/upload'));
      request.files.add(http.MultipartFile.fromBytes('file', videoBytes, filename: fileName));

      var response = await request.send();

      if (response.statusCode == 200) {
        print('视频上传成功');
      } else {
        print('视频上传失败');
      }
    } else {
      print('未选择视频');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Welcome to the Location Checker',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Times New Roman'),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Colors.blue,
                Colors.purple,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.blue, Colors.purple],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SizedBox(
                        width: 160,
                        child: ElevatedButton(
                          onPressed: _selectVideo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'selectVideo',
                            style: TextStyle(
                                fontFamily: 'Times New Roman',
                                fontSize: 18,
                                color: Colors.white),
                          ),
                        ),
                      )),
                  Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.blue, Colors.purple],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SizedBox(
                        width: 160,
                        child: ElevatedButton(
                            onPressed: _uploadVideo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'uploadVideo',
                              style: TextStyle(
                                  fontFamily: 'Times New Roman',
                                  fontSize: 18,
                                  color: Colors.white),
                            )),
                      )),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: _video != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 20),
                                Container(
                                  alignment: Alignment.center,
                                  width: 300,
                                  child: _controller != null &&
                                          _controller!.value.isInitialized
                                      ? AspectRatio(
                                          aspectRatio:
                                              _controller!.value.aspectRatio,
                                          child: VideoPlayer(_controller!),
                                        )
                                      : const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                )
                              ],
                            )
                          : const Center(
                              child: Text(
                              'No video selected',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: 'Times New Roman',
                                  fontSize: 18,
                                  color: Colors.black),
                            )),
                    ),
                  ),
                ],
              )
            ],
          )),
    );
  }
}
