import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Social Media App'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            PostCard(),
            PostCard(),
            // Add more PostCard widgets as needed
          ],
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(
                  // User profile image
                  radius: 20.0,
                  backgroundImage: AssetImage('images/user/default_user.jpg'),
                ),
                SizedBox(width: 8.0),
                Text(
                  'John Doe', // User name
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Post content
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque sit amet justo vel justo tempor facilisis.',
            ),
          ),
          // Post image
          Image.asset(
            'images/user/default_user.jpg',
            height: 200.0,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          // Like, Comment, Share buttons

          ButtonBar(
            alignment: MainAxisAlignment.spaceAround,
            children: [
              GFButton(
                onPressed: (){
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return CommentDialog();
                    },
                  );
                },
                text: "Comments",
                icon: Icon(Icons.mode_comment,color: Colors.grey.shade800,),
                type: GFButtonType.transparent,
              ),
            ],
          ),
          const Divider(),
          _buildCommentsSection()
        ],
      ),
    );
  }
}

class CommentDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add a Comment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(labelText: 'Your comment'),
            maxLines: 3,
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              // Handle submit comment
              Navigator.of(context).pop();
            },
            child: Text('Post Comment'),
          ),
        ],
      ),
    );
  }
}

Widget _buildCommentsSection() {
  // Example comments; you can replace this with actual comment data
  List<String> comments = ['Great post!', 'I love it!', 'Nice picture!'];

  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.0),
        // Use a ListView.builder to display comments
        ListView.builder(
          shrinkWrap: true,
          itemCount: comments.length,
          itemBuilder: (context, index) {
            return ListTile(
              contentPadding: EdgeInsets.all(0),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        // User profile image
                        radius: 20.0,
                        backgroundImage: AssetImage('images/user/default_user.jpg'),
                      ),
                      SizedBox(width: 8.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'John Doe', // User name
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(comments[index]),
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



