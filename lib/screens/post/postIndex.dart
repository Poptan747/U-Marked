import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:u_marked/reusable_widget/appBar.dart';

class PostIndex extends StatefulWidget {
  const PostIndex({Key? key,required this.classID}) : super(key: key);
  final String classID;

  @override
  State<PostIndex> createState() => _PostIndexState();
}

var _isLoading = true;
var _noData = true;
String cID = '';
var _descriptionMap = <String, String>{};
var _postImageMap = <String, String>{};
var _nameMap = <String, String>{};
var _isCurrentUserMap = <String, bool>{};
var _userImageMap = <String, String>{};
var _userCommentMap = <String, String>{};
var _userCommentNameMap = <String, String>{};
var _userCommentImageMap = <String, String>{};

class _PostIndexState extends State<PostIndex> {

  @override
  void initState() {
    super.initState();
    defaultData();
    loadData();
  }

  defaultData(){
    _isLoading = true;
    _noData = true;
    cID = '';
    _descriptionMap = <String, String>{};
    _postImageMap = <String, String>{};
    _nameMap = <String, String>{};
    _userImageMap = <String, String>{};
    _userCommentMap = <String, String>{};
    _userCommentNameMap = <String, String>{};
    _userCommentImageMap = <String, String>{};
    _isCurrentUserMap = <String, bool>{};
  }

  void loadData() async{
    String classID = widget.classID;
    setState(() {
      cID = widget.classID;
      _isLoading = true;
      _noData = true;
    });
    try {
      String userID = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot<
          Map<String, dynamic>> querySnapshot = await FirebaseFirestore
          .instance
          .collection('classes').doc(classID)
          .collection('posts')
          .get();
      List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot
          .docs;
      if (documents.isNotEmpty){

        for (DocumentSnapshot<Map<String, dynamic>> document in documents){

          var classPostData = document.data() as Map<String, dynamic>;
          String postID = classPostData['postID'];
          var postCollection = await FirebaseFirestore.instance.collection('posts').doc(postID).get();
          var postData = await postCollection.data() as Map<String, dynamic>;
          String createByUID = postData['createBy'];
          setState(() {
            if(userID == createByUID){
              _isCurrentUserMap[postID] = true;
            }else{
              _isCurrentUserMap[postID] = false;
            }
          });

          var userCollection = await FirebaseFirestore.instance.collection('users').doc(createByUID).get();
          var data = await userCollection.data() as Map<String, dynamic>;
          if (data['userType'] == 1){
            var studentCollection = await FirebaseFirestore.instance.collection('students').doc(createByUID).get();
            var studentData = await studentCollection.data() as Map<String, dynamic>;
            setState(() {
              _nameMap[postID] = studentData['name'];
              _userImageMap[postID] = data['imagePath'];
              _descriptionMap[postID] = postData['description'];
              _postImageMap[postID] = postData['imagePath'];
            });
          }else{
            var lecCollection = await FirebaseFirestore.instance.collection('lecturers').doc(createByUID).get();
            var lecData = await lecCollection.data() as Map<String, dynamic>;
            setState(() {
              _nameMap[postID] = lecData['name'];
              _userImageMap[postID] = data['imagePath'];
              _descriptionMap[postID] = postData['description'];
              _postImageMap[postID] = postData['imagePath'];
            });
          }
          //comment data
          QuerySnapshot<
              Map<String, dynamic>> commentQuerySnapshot = await FirebaseFirestore
              .instance
              .collection('posts').doc(postID)
              .collection('comments')
              .get();
          List<DocumentSnapshot<Map<String, dynamic>>> commentDocuments = commentQuerySnapshot
              .docs;
          if (commentDocuments.isNotEmpty){
            for (DocumentSnapshot<Map<String, dynamic>> commentDocument in commentDocuments){
              var commentData = commentDocument.data() as Map<String, dynamic>;
              String docID = commentDocument.id;
              String commentCreateByUID = commentData['createBy'];
              var userCommentCollection = await FirebaseFirestore.instance.collection('users').doc(commentCreateByUID).get();
              var userCommentdata = await userCommentCollection.data() as Map<String, dynamic>;
              if (userCommentdata['userType'] == 1){
                var studentCollection = await FirebaseFirestore.instance.collection('students').doc(commentCreateByUID).get();
                var studentData = await studentCollection.data() as Map<String, dynamic>;
                setState(() {
                  _userCommentNameMap[docID] = studentData['name'];
                  _userCommentImageMap[docID] = userCommentdata['imagePath'];
                  _userCommentMap[docID] = commentData['comment'];
                });
              }else{
                var lecCollection = await FirebaseFirestore.instance.collection('lecturers').doc(commentCreateByUID).get();
                var lecData = await lecCollection.data() as Map<String, dynamic>;
                setState(() {
                  _userCommentNameMap[docID] = lecData['name'];
                  _userCommentImageMap[docID] = userCommentdata['imagePath'];
                  _userCommentMap[docID] = commentData['comment'];
                });
              }
            }
          }
        }
        setState(() {
          _isLoading = false;
          _noData = false;
        });
      }else{
        setState(() {
          _isLoading = false;
          _noData = true;
        });
      }

    }on FirebaseFirestore catch(error){
      var snackBar = SnackBar(
        content: Text(error.toString()),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: postIndexAppBar(context,widget.classID),
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: Colors.blue.shade100,
          child: _isLoading? const Center(child: CircularProgressIndicator(color: Colors.white,)) : _buildPostCardStream(),
        ),
      ),
    );
  }

  Widget _buildPostCardStream() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('classes').doc(widget.classID).collection('posts').orderBy('createAt', descending: true).snapshots(),
      builder: (context, orderSnapshot) {
        if (orderSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white,));
        }
        if(orderSnapshot.hasError){
        }

        if(!orderSnapshot.hasData || orderSnapshot.data!.docs.isEmpty){
          return const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Card(
                  child: ListTile(
                    title: Text('No Post Found'),
                  ),
                ),
              ),
            ),
          );
        }else{
          return ListView.builder(
            itemCount: orderSnapshot.data!.docs.length,
            physics: const ScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {

              var orderData = orderSnapshot.data!.docs[index].data() as Map<String, dynamic>;
              String postID = orderData['postID'];
              String createAt = _nameMap[postID] ?? 'Unknown Name';
              String userImage = _userImageMap[postID] ?? 'Unknown Date';
              bool hasUserImage = userImage.trim().isNotEmpty;
              String description = _descriptionMap[postID] ?? 'Unknown Time';
              String postImage = _postImageMap[postID] ?? '';
              bool hasPostImage = postImage.trim().isNotEmpty;
              bool editable = _isCurrentUserMap[postID] ?? false;
              return Card(
                margin: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          hasUserImage?
                          CircleAvatar(
                            radius: 20.0,
                            backgroundImage: NetworkImage(userImage),
                          ):
                          const CircleAvatar(
                            foregroundImage: AssetImage('images/user/default_user.jpg'),
                            radius: 50,
                          ),
                          const SizedBox(width: 8.0),
                          Text(createAt, style: const TextStyle(fontWeight: FontWeight.bold, ),),
                          const Spacer(),
                          if(editable)
                          IconButton(
                            icon: const Icon(Icons.edit,color: Colors.blue,),
                            onPressed: () {
                              showModalBottomSheet(
                                isScrollControlled: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                context: context,
                                builder: (BuildContext context) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                    child: EditPostDialog(postID: postID,classID: widget.classID),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Text(
                      description,
                    ),
                    const Divider(),
                    if(hasPostImage)
                      Image.network(
                        postImage,
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                    if(hasPostImage)
                    const Divider(),
                    ButtonBar(
                      alignment: MainAxisAlignment.spaceAround,
                      children: [
                        GFButton(
                          onPressed: (){
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return CommentDialog(postID: postID,classID: widget.classID,);
                              },
                            );
                          },
                          text: "Comments",
                          icon: Icon(Icons.mode_comment,color: Colors.grey.shade800,),
                          type: GFButtonType.transparent,
                        ),
                      ],
                    ),
                    _buildCommentStream(postID)
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildCommentStream(String postID) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('posts').doc(postID).collection('comments').orderBy('createAt', descending: true).snapshots(),
      builder: (context, orderSnapshot) {
        if (orderSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white,));
        }
        if(orderSnapshot.hasError){
        }

        if(!orderSnapshot.hasData || orderSnapshot.data!.docs.isEmpty){
          return const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Card(
                  child: ListTile(
                    title: Text('No Comment Found'),
                  ),
                ),
              ),
            ),
          );
        }else{
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ListView.builder(
                  itemCount: orderSnapshot.data!.docs.length,
                  physics: const ScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    String commentID = orderSnapshot.data!.docs[index].id;
                    String comment = _userCommentMap[commentID] ?? 'Loading...';
                    String userImage = _userCommentImageMap[commentID] ?? 'Loading...';
                    String userName = _userCommentNameMap[commentID] ?? 'Loading...';
                    bool hasUserImage = userImage.trim().isNotEmpty;
                    return ListTile(
                      contentPadding: EdgeInsets.all(0),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          Row(
                            children: [
                              hasUserImage?
                              CircleAvatar(
                                radius: 20.0,
                                backgroundImage: NetworkImage(userImage),
                              ):
                              const CircleAvatar(
                                foregroundImage: AssetImage('images/user/default_user.jpg'),
                                radius: 50,
                              ),
                              const SizedBox(width: 8.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName, // User name
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(comment),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

class CommentDialog extends StatefulWidget {
  const CommentDialog({Key? key, required this.postID, required this.classID}) : super(key: key);
  final String postID;
  final String classID;

  @override
  State<CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<CommentDialog> {
  final _createCommentForm = GlobalKey<FormState>();
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() async{
    final isValid = _createCommentForm.currentState!.validate();
    if(!isValid){
      return;
    }
    _createCommentForm.currentState!.save();

    String postID = widget.postID;
    FirebaseFirestore.instance.collection('posts').doc(postID).collection('comments').add({
      'comment' : _commentController.text,
      'postID' : postID,
      'createBy' : FirebaseAuth.instance.currentUser!.uid,
      'createAt' : DateTime.now(),
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
        content: Text('Comment created!'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });

  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AlertDialog(
        title: const Text('Add a Comment'),
        content: Form(
          key: _createCommentForm,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(labelText: 'Your Comment'),
                maxLines: 3,
                validator: (value){
                  if(value == null || value.trim().isEmpty){
                    return 'Please write something about the comment.';
                  }
                },
                onSaved: (value){
                  _commentController.text = value!;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  _submit();
                },
                child: const Text('Post Comment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditPostDialog extends StatefulWidget {
  const EditPostDialog({Key? key, required this.postID, required this.classID}) : super(key: key);
  final String postID;
  final String classID;

  @override
  State<EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends State<EditPostDialog> {
  final _editPostForm = GlobalKey<FormState>();
  final TextEditingController _postController = TextEditingController();
  String _errorMessage = '';
  bool isLoading = false;
  String imageUrl ='';
  bool changeImage = false;
  File? _pickedImageFile;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  void loadData() async{
    String postID = widget.postID;
    final postCollection = await FirebaseFirestore.instance.collection('posts').doc(postID).get();
    final postData = await postCollection.data() as Map<String, dynamic>;

    setState(() {
      _postController.text = postData['description'];
      imageUrl = postData['imagePath'];
    });
  }

  void _submit() async{
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });
    final isValid = _editPostForm.currentState!.validate();
    if(!isValid){
      return;
    }
    _editPostForm.currentState!.save();

    try{
      String description = _postController.text;
      FirebaseFirestore.instance.collection('posts').doc(widget.postID).update({
        'description' : description,
      }).then((value) async{
        if(imageUrl.trim().isNotEmpty){
          if(changeImage){
            final storageRef = FirebaseStorage.instance.ref().child('post_images').child('${widget.postID}.jpg');
            if(imageUrl.trim().isNotEmpty){
              await storageRef.delete();
            }
            await storageRef.putFile(_pickedImageFile!);
            FirebaseFirestore.instance.collection('posts').doc(widget.postID).update({
              'imagePath' :  await storageRef.getDownloadURL(),
            });
          }else{
            FirebaseFirestore.instance.collection('posts').doc(widget.postID).update({
              'imagePath' :  imageUrl,
            });
          }
        }else{
          FirebaseFirestore.instance.collection('posts').doc(widget.postID).update({
            'imagePath' :  imageUrl,
          });
        }
      });

      setState(() {
        isLoading = false;
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostIndex(classID: widget.classID),
          ),
        );

        var snackBar = const SnackBar(
          content: Text('Post updated!'),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });

    }on FirebaseFirestore catch(error){
      setState(() {
        _errorMessage = error.toString();
      });
    }
  }

  void _delete() async{
    String postID = widget.postID;

    await FirebaseFirestore.instance.collection('posts').doc(postID).delete();

    await FirebaseFirestore.instance.collection('classes').doc(widget.classID)
        .collection('posts').doc(postID).delete();

    setState(() {
      Navigator.pop(context);

      var snackBar = const SnackBar(
        content: Text('Post deleted!'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  void _pickImage() async{
    final pickImage = await ImagePicker().pickImage(source: ImageSource.gallery);

    if(pickImage == null){
      return;
    }

    setState(() {
      _pickedImageFile = File(pickImage.path);
      changeImage = true;
    });
  }

  void _removeImage() async{
    setState(() {
      imageUrl = '';
      changeImage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _editPostForm,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Edit Posts',
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
                !changeImage?
                imageUrl.trim().isNotEmpty?
                Image.network(
                    imageUrl,height: 200,width: double.infinity,fit: BoxFit.contain,
                ):Container()
                    : Image.file(
                    _pickedImageFile!,
                    height: 200.0,
                    width: double.infinity,
                    fit: BoxFit.contain
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Add a Picture'),
                    ),
                    if(imageUrl.trim().isNotEmpty)
                      TextButton.icon(
                        onPressed: _removeImage,
                        icon: const Icon(Icons.image_not_supported),
                        label: const Text('Remove Picture'),
                        style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.all<Color>(Colors.red),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirm Action'),
                              content: const Text('Are you sure you want to delete this post?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    _delete();
                                    Navigator.of(context).pop(true);
                                  },
                                  child: const Text('Yes'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  child: const Text('No'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                        style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.all<Color>(Colors.red),
                        ),
                      child: const Text('Delete')
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _submit();
                      },
                      child: const Text('Confirm Changed'),
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
