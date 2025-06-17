import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GMCam',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'GM Cam'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Holds the image picked from the camera
  XFile? _imageFile;

  // ImagePicker instance
  final ImagePicker _picker = ImagePicker();

  // Launches the camera, captures an image and updates UI
  Future<void> _pickImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  // ✨ NEW • save the currently-captured picture to the gallery
  Future<void> _saveImageToGallery() async {
    if (_imageFile == null) return;

    // Ask for the storage / media permission on Android (no-op on iOS)
    if (Platform.isAndroid) {
      if (await Permission.photos.request().isGranted) {
        // API 33+
        final bytes = await File(_imageFile!.path).readAsBytes();
        final result = await ImageGallerySaverPlus.saveImage(
          Uint8List.fromList(bytes),
          name: 'degen_${DateTime.now().millisecondsSinceEpoch}',
          quality: 100,
        );

        if (!mounted) return;
        final isSuccess = (result['isSuccess'] as bool?) ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSuccess ? 'Saved to gallery' : 'Could not save'),
          ),
        );
      } else if (await Permission.storage.request().isGranted) {
        // API <33
        final bytes = await File(_imageFile!.path).readAsBytes();
        final result = await ImageGallerySaverPlus.saveImage(
          Uint8List.fromList(bytes),
          name: 'degen_${DateTime.now().millisecondsSinceEpoch}',
          quality: 100,
        );

        if (!mounted) return;
        final isSuccess = (result['isSuccess'] as bool?) ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSuccess ? 'Saved to gallery' : 'Could not save'),
          ),
        );
      }
    }
  }

  Future<void> _openEditorAndSave() async {
    if (_imageFile == null) return;

    // 1. Open the editor and wait for the user to finish
    final edited = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => ProImageEditor.file(
          File(_imageFile!.path),
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (bytes) async =>
                Navigator.pop(context, bytes),
          ),
          configs: ProImageEditorConfigs(
            paintEditor: const PaintEditorConfigs(enabled: false),
            //textEditor: const TextEditorConfigs(enabled: false),
            //cropRotateEditor: const CropRotateEditorConfigs(enabled: false),
            filterEditor: const FilterEditorConfigs(enabled: false),
            blurEditor: const BlurEditorConfigs(enabled: false),
            emojiEditor: const EmojiEditorConfigs(enabled: false),
            stickerEditor: StickerEditorConfigs(
              enabled: true,
              builder: (setLayer, scroll) {
                return GridView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 120,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    final url = 'https://picsum.photos/id/${index + 100}/200';
                    return GestureDetector(
                      onTap: () => setLayer(
                        WidgetLayer(widget: Image.network(url)),
                      ), // add to canvas
                      child: Image.network(url, fit: BoxFit.cover),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    // 2. Save the returned bytes with the code you already have
    if (edited != null) {
      final result = await ImageGallerySaverPlus.saveImage(
        edited,
        name: 'degen_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (result['isSuccess'] ?? false) ? 'Saved!' : 'Could not save',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_imageFile != null) ...[
              const SizedBox(height: 20),
              Image.file(File(_imageFile!.path), height: 200),
            ],
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _pickImageFromCamera,
            tooltip: 'Capture Image',
            heroTag: 'camera',
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 16),
          if (_imageFile != null)
            FloatingActionButton(
              onPressed: _openEditorAndSave,
              tooltip: 'Edit and Save',
              heroTag: 'edit',
              backgroundColor: Colors.blue,
              child: const Icon(Icons.edit),
            ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
