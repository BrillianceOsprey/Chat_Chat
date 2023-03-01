import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final String peerNickName;
  const ChatPage(
      {super.key,
      required this.peerId,
      required this.peerAvatar,
      required this.peerNickName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
