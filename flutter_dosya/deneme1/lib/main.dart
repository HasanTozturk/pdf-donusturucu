import 'dart:async';
import 'dart:io'; // File sınıfını ekledik
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

void main() {
  runApp(MyApp()); // Wrap MyApp around MyHomePage
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Dönüştürücü',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isDarkMode = false;
  IconData iconData = Icons.wb_sunny;
  List<CroppedFile> selectedImages = [];
  void toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
      iconData = isDarkMode ? Icons.lightbulb_outline : Icons.wb_sunny;
      // Tema modunu güncelle
      if (isDarkMode) {
        // Karanlık tema
        ThemeMode.dark;
      } else {
        // Açık tema
        ThemeMode.light;
      }
    });
  }


  Future<void> _pickImages(ImageSource source) async {
    List<XFile>? pickedImages = await ImagePicker().pickMultiImage();
    if (pickedImages != null) {
      for (var pickedImage in pickedImages) {
        await _cropImage(pickedImage);
      }
    }
  }

  Future<void> _cropImage(XFile imageFile) async {
  CroppedFile? croppedFile = await ImageCropper().cropImage(
    sourcePath: imageFile.path,
    aspectRatioPresets: [
      CropAspectRatioPreset.square,
      CropAspectRatioPreset.ratio3x2,
      CropAspectRatioPreset.original,
      CropAspectRatioPreset.ratio4x3,
      CropAspectRatioPreset.ratio16x9
    ],
    uiSettings: [
      AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false),
      IOSUiSettings(
        title: 'Cropper',
      ),
      WebUiSettings(
        context: context,
      ),
    ],
  );
  if (croppedFile!= null) {
    setState(() {
      selectedImages.add(croppedFile);
    });
  }
}

  Future<void> convertToPDF() async {
    if (selectedImages.isNotEmpty) {
      final pdf = pw.Document();

      for (var image in selectedImages) {
        final bytes = await image.readAsBytes();
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(pw.MemoryImage(bytes)),
              );
            },
          ),
        );
      }

      final output = await getExternalStorageDirectory();
      final file = File('${output!.path}/example.pdf');
      await file.writeAsBytes(await pdf.save());

      OpenFile.open(file.path);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Başarılı'),
          content: const Text('PDF dosyası başarıyla oluşturuldu!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Uyarı'),
          content: const Text('Lütfen önce bir veya daha fazla resim seçin!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }
 Future<void> _takePictures(ImageSource source) async {
  final XFile? picture = await ImagePicker().pickImage(source: source);
  if (picture != null) {
    await _cropImage(picture);
  }
}



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
     theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.grey,
        brightness: Brightness.dark,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PDF Dönüştürücü'),
          actions: [
            IconButton(
              icon: Icon(iconData),
              onPressed: toggleDarkMode,
            ),
          ],
        ),
        
        backgroundColor: Colors.blue[400],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImages(ImageSource.gallery),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: const Text('Galeriden Seç'),
                  ),
                  ElevatedButton(
                    onPressed: () => _takePictures(ImageSource.camera),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: const Text('Kameradan Çek'),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: selectedImages.isNotEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.file(
                            File(selectedImages[index].path), // CroppedFile'ı File'a dönüştürme
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: convertToPDF,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text('PDF\'e Dönüştür'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
