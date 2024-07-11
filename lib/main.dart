import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  bool _isVideoUploaded = false; // 用来跟踪视频是否上传
  String _resultText = "";
  bool _redoVisible = false;
  bool _googleMapVisible = false;
  final List<Marker> _markers = [];
  GoogleMapController? _mapController;
  String videoId = ""; // 根据实际情况设置videoId
  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = false; // 上传加载状态

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

  void _uploadVideo() async {
    setState(() {
      _isLoading = true; // 开始加载
    });
    // 上传视频的处理逻辑
    print('Upload Video');
    if (_video != null) {
      List<int> videoBytes = await _video!.readAsBytes();
      String fileName = _video!.path.split('/').last;

      var request = http.MultipartRequest(
          'POST', Uri.parse('http://192.168.1.24:80/upload'));
      request.files.add(
          http.MultipartFile.fromBytes('file', videoBytes, filename: fileName));

      var response = await request.send();
      // Parse the streamed response to get the complete response body
      final responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        _showUploadSuccessDialog();
        print('Video uploaded successfully');
        // Assuming the response body is plain text
        setState(() {
          videoId = responseBody.body;
          _isVideoUploaded = true; // 设置视频已上传的标志
          _isLoading = false; // 加载结束
        });
      } else {
        print('Video upload failed');
        setState(() {
          _isVideoUploaded = false;
          _isLoading = false; // 加载结束
        });
      }
    } else {
      print('No video selected');
      setState(() {
        _isVideoUploaded = false;
        _isLoading = false; // 加载结束
      });
    }
  }

  void _findLocation() async {
    if (!_isVideoUploaded) {
      _showDialog();
      return;
    }

    setState(() {
      _isLoading = true; // 开始加载
      _resultText = "";
      _redoVisible = false;
      _googleMapVisible = false;
    });

    try {
      final response =
          await http.get(Uri.parse('http://192.168.1.24:80/result/$videoId'));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        setState(() {
          _googleMapVisible = true;
          _markers.clear();
          int count = 0;
          List<Map<String, dynamic>> legend = [];

          result.forEach((key, value) {
            count++;
            final pos = LatLng(value[0], value[1]);
            _markers.add(Marker(
              markerId: MarkerId(count.toString()),
              position: pos,
              infoWindow: InfoWindow(title: count.toString(), snippet: key),
            ));
            legend.add({'mark': count, 'location': key});
          });

          if (legend.isEmpty) {
            _resultText =
                "Sorry, could not find any valid locations, maybe try another frame rate.";
            _redoVisible = true;
          } else {
            _tableData = legend; // 更新表格数据
          }
          _isLoading = false; // 加载结束
        });
      } else {
        setState(() {
          _resultText = "Failed to get result from server.";
          _isLoading = false; // 加载结束
        });
      }
    } catch (e) {
      setState(() {
        _resultText = "An error occurred: $e";
        _isLoading = false; // 加载结束
      });
    }
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Prompt'),
          content: Text('Please upload the video first'),
          actions: <Widget>[
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showUploadSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Prompt'),
          content: Text('Upload success!'),
          actions: <Widget>[
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTable() {
    return Table(
      border: TableBorder.all(),
      children: [
        TableRow(
          children: [
            TableCell(child: Center(child: Text('Mark'))),
            TableCell(child: Center(child: Text('Location'))),
          ],
        ),
        ..._tableData
            .map(
              (data) => TableRow(
                children: [
                  TableCell(
                      child: Center(child: Text(data['mark'].toString()))),
                  TableCell(child: Center(child: Text(data['location']))),
                ],
              ),
            )
            .toList(),
      ],
    );
  }

  void _reDo() {
    _findLocation();
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
          child: SingleChildScrollView(
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
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
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
                                                aspectRatio: _controller!
                                                    .value.aspectRatio,
                                                child:
                                                    VideoPlayer(_controller!),
                                              )
                                            : const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                      ),
                                      const SizedBox(
                                        height: 40,
                                      ),
                                      Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Colors.blue,
                                                Colors.purple
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: SizedBox(
                                            width: 160,
                                            child: ElevatedButton(
                                                onPressed: _findLocation,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  shadowColor:
                                                      Colors.transparent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'findLocation',
                                                  style: TextStyle(
                                                      fontFamily:
                                                          'Times New Roman',
                                                      fontSize: 18,
                                                      color: Colors.white),
                                                )),
                                          )),
                                      if (_googleMapVisible)
                                        Column(
                                          children: [
                                            SizedBox(
                                              height: 40,
                                              child: GoogleMap(
                                                onMapCreated: (controller) {
                                                  _mapController = controller;
                                                },
                                                initialCameraPosition:
                                                    const CameraPosition(
                                                  target: LatLng(
                                                      51.508742, -0.120850),
                                                  zoom: 5,
                                                ),
                                                markers:
                                                    Set<Marker>.of(_markers),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            _buildTable(), // 调用 _buildTable 方法来显示表格
                                            Text(_resultText),
                                            if (_redoVisible)
                                              Container(
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                      colors: [
                                                        Colors.blue,
                                                        Colors.purple
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: SizedBox(
                                                    width: 160,
                                                    child: ElevatedButton(
                                                        onPressed: _reDo,
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          shadowColor: Colors
                                                              .transparent,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'reDo',
                                                          style: TextStyle(
                                                              fontFamily:
                                                                  'Times New Roman',
                                                              fontSize: 18,
                                                              color:
                                                                  Colors.white),
                                                        )),
                                                  ))
                                          ],
                                        ),
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
          ))),
    );
  }
}
