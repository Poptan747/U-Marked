import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:u_marked/screens/post/postIndex.dart';

class createPostBottomSheet extends StatefulWidget {
  const createPostBottomSheet({Key? key,required this.classID}) : super(key: key);
  final String classID;

  @override
  State<createPostBottomSheet> createState() => _createPostBottomSheetState();
}

class _createPostBottomSheetState extends State<createPostBottomSheet> {

  final _createPostForm = GlobalKey<FormState>();
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _subjectNameController = TextEditingController();
  String _errorMessage = '';
  bool isLoading = false;
  File? _pickedImageFile;

  @override
  void dispose() {
    _postController.dispose();
    _subjectNameController.dispose();
    super.dispose();
  }

  void _submit() async{
    setState(() {
      _errorMessage = '';
    });
    final isValid = _createPostForm.currentState!.validate();
    if(!isValid){
      return;
    }
    _createPostForm.currentState!.save();

    try{
      setState(() {
        isLoading = true;
      });

      String description = _postController.text;
      FirebaseFirestore.instance.collection('posts').add({
        'description' : description,
        'imagePath' : '',
        'classID' : widget.classID,
        'createBy' : FirebaseAuth.instance.currentUser!.uid,
        'createAt' : DateTime.now(),
      }).then((value) async{
        if(_pickedImageFile !=null){
          final metadata = SettableMetadata(contentType: "image/jpeg");
          final storageRef = FirebaseStorage.instance.ref().child('post_images').child('${value.id}.jpg');
          await storageRef.putFile(_pickedImageFile!,metadata);
          FirebaseFirestore.instance.collection('posts').doc(value.id).update({
            'imagePath' :  await storageRef.getDownloadURL(),
          });
        }
        FirebaseFirestore.instance.collection('classes').doc(widget.classID).collection('posts').doc(value.id).set({
          'classID' : widget.classID,
          'postID' : value.id,
          'createAt' : DateTime.now(),
        });
      });


      setState(() {
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostIndex(classID: widget.classID),
          ),
        );

        var snackBar = const SnackBar(
          content: Text('Post created!'),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        isLoading = false;
      });
    }on FirebaseFirestore catch(error){
      setState(() {
        _errorMessage = error.toString();
      });
    }
  }

  void _pickImage() async{
    final pickImage = await ImagePicker().pickImage(source: ImageSource.gallery);

    if(pickImage == null){
      return;
    }

    setState(() {
      _pickedImageFile = File(pickImage.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _createPostForm,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'New Posts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                isLoading? const CircularProgressIndicator() : const SizedBox(),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _postController,
                  decoration: const InputDecoration(labelText: 'Write Something...',),
                  maxLines: 3,
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please write something about the post.';
                    }
                  },
                  onSaved: (value){
                    _postController.text = value!;
                  },
                ),
                _errorMessage.trim().isNotEmpty ? Text(_errorMessage, style: const TextStyle(color: Colors.red),) : const SizedBox(),
                const SizedBox(height: 10),
                _pickedImageFile != null ?
                Image.file(
                  _pickedImageFile!,
                  height: 200.0,
                  width: double.infinity,
                    fit: BoxFit.contain
                )
                    : Container(),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Add a Picture'),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Back'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _submit();
                      },
                      child: const Text('Create New Post'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}