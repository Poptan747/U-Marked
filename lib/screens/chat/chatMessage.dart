import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:u_marked/screens/chat/message_bubble.dart';

class chatMessages extends StatelessWidget {
  const chatMessages({Key? key ,required this.chatroomID}) : super(key: key);
  final String chatroomID;

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser!;

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('chatrooms').doc(chatroomID).collection('message')
              .orderBy('createAt',descending: true).snapshots(),
      builder: (ctx , chatSnapshot){
        if(chatSnapshot.connectionState == ConnectionState.waiting){
          return const Center(child: CircularProgressIndicator());
        }
        if(!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty){
          return const Center(child: Text('No message found...'),);
        }
        if(chatSnapshot.hasError){
          return const Center(child: Text('Error...'),);
        }

        var loadedMessages = chatSnapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.only(bottom: 40, left: 13, right: 13),
          reverse: true,
          itemCount: loadedMessages.length,
            itemBuilder: (ctx, index) {
              final chatMessage = loadedMessages[index].data();
              final nexChatMessage = index + 1 < loadedMessages.length
                    ? loadedMessages[index+1].data()
                    : null;
              final currentMessageUID = chatMessage['userID'];
              final nextMessageUID = nexChatMessage != null ? nexChatMessage['userID']
                    : null;
              final nextUserIsSame = nextMessageUID == currentMessageUID;
              if(nextUserIsSame){
                return MessageBubble.next(message: chatMessage['message'], isMe: authUser.uid == currentMessageUID);
              }else{
                return MessageBubble.first(
                    userImage: chatMessage['userImage'] ?? '',
                    username: chatMessage['userName'],
                    message: chatMessage['message'], isMe: authUser.uid == currentMessageUID
                );
              }

            }
        );
      },
    );
  }
}


