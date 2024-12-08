import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences.dart';

class AudioPlayerApp extends StatefulWidget {
  @override
  _AudioPlayerAppState createState() => _AudioPlayerAppState();
}

class _AudioPlayerAppState extends State<AudioPlayerApp> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  bool _isPlaying = false;
  BluetoothDevice? _connectedDevice;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _secretKeyController = TextEditingController();
  
  // 模拟粉丝列表
  final List<String> _allowedUsers = [
    "UP主",
    "用户1",
    "用户2",
    "用户3",
    // 在这里添加更多允许的用户名
  ];

  // 同行密钥
  final String _secretKey = "ABC"; // 替换成实际的密钥

  @override
  void initState() {
    super.initState();
    _audioPlayer.setUrl('https://example.com/audio.mp3');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserAuthentication();
    });
  }

  Future<void> _checkUserAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedUsername = prefs.getString('username');
    final String? savedSecretKey = prefs.getString('secret_key');
    
    if (savedUsername == null || !_allowedUsers.contains(savedUsername) ||
        savedSecretKey != _secretKey) {
      _showLoginDialog();
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('验证身份'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('请输入您的用户名以验证身份'),
            SizedBox(height: 10),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: '输入用户名',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Text('请输入同行密钥'),
            SizedBox(height: 10),
            TextField(
              controller: _secretKeyController,
              decoration: InputDecoration(
                hintText: '输入同行密钥',
                border: OutlineInputBorder(),
              ),
              obscureText: true, // 密钥输入时显示为星号
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final username = _usernameController.text.trim();
              final secretKey = _secretKeyController.text.trim();
              if (!_allowedUsers.contains(username)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('用户名未找到，请重试')),
                );
                return;
              }
              if (secretKey != _secretKey) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('同行密钥错误，请重试')),
                );
                return;
              }
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('username', username);
              await prefs.setString('secret_key', secretKey);
              Navigator.of(context).pop();
            },
            child: Text('确认'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      setState(() {
        _connectedDevice = device;
      });
      // 这里需要实现实际的蓝牙连接逻辑
    } catch (e) {
      print('连接设备失败: $e');
    }
  }

  Future<void> _showDevicesList() async {
    final List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('选择蓝牙设备'),
        content: Container(
          height: 300,
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                title: Text(device.name ?? '未知设备'),
                subtitle: Text(device.address),
                onTap: () {
                  Navigator.pop(context);
                  _connectToDevice(device);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('音频播放器')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _connectedDevice != null 
                ? '已连接到: ${_connectedDevice!.name}'
                : '未连接设备',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_isPlaying) {
                  await _audioPlayer.pause();
                } else {
                  await _audioPlayer.play();
                }
                setState(() {
                  _isPlaying = !_isPlaying;
                });
              },
              child: Text(_isPlaying ? '暂停' : '播放'),
            ),
            ElevatedButton(
              onPressed: _showDevicesList,
              child: Text('连接蓝牙设备'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
} 