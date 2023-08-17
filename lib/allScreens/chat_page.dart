import 'dart:io';

import 'package:chat_chat/allConstants/constants.dart';
import 'package:chat_chat/allModels/message_chat.dart';
import 'package:chat_chat/allProviders/auth_provider.dart';
import 'package:chat_chat/allProviders/chat_provider.dart';
import 'package:chat_chat/allProviders/setting_provider.dart';
import 'package:chat_chat/allScreens/full_photo_page.dart';
import 'package:chat_chat/allScreens/login_page.dart';
import 'package:chat_chat/allWidgets/loading.dart';
import 'package:chat_chat/appCoreFeatures/logger.dart';
import 'package:chat_chat/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  // ignore: no_logic_in_create_state
  State<ChatPage> createState() => ChatPageState(
        peerId: peerId,
        peerAvatar: peerAvatar,
        peerNickName: peerNickName,
      );
}

class ChatPageState extends State<ChatPage> {
  ChatPageState({
    Key? key,
    required this.peerId,
    required this.peerAvatar,
    required this.peerNickName,
  });
  String peerId;
  String peerAvatar;
  String peerNickName;
  late String currentUserId;

  List<QueryDocumentSnapshot> listMessage = List.from([]);

  int _limit = 20;
  int limitIncrement = 20;
  String groupChatId = "";
  File? imageFile;
  bool isLoading = false;
  bool isShowSticker = false;
  String imageUrl = "";

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollCotroller = ScrollController();
  final FocusNode focusNode = FocusNode();

  late ChatProvider chatProvider;
  late AuthProvider authProvider;

  @override
  void initState() {
    super.initState();
    chatProvider = context.read<ChatProvider>();
    authProvider = context.read<AuthProvider>();
    focusNode.addListener(onFocusChange);
    listScrollCotroller.addListener(_scrollListener);
    readLocal();
  }

  _scrollListener() {
    if (listScrollCotroller.offset >=
            listScrollCotroller.position.maxScrollExtent &&
        !listScrollCotroller.position.outOfRange) {
      setState(() {
        _limit = limitIncrement;
      });
    }
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      setState(() {
        isShowSticker = false;
      });
    }
  }

  void readLocal() {
    if (authProvider.getUserFirebaseId()?.isNotEmpty == true) {
      currentUserId = authProvider.getUserFirebaseId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (cxt) => const LoginPage(),
          ),
          (route) => false);
    }

    if (currentUserId.hashCode <= peerId.hashCode) {
      groupChatId = '$currentUserId-$peerId';
    } else {
      groupChatId = '$peerId-$currentUserId';
    }

    chatProvider.updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      currentUserId,
      {FirestoreConstants.chattingWith: peerId},
    );
  }

  //
  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile;
    // pickedFile = await imagePicker.getImage(source: ImageSource.gallery);
    pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      if (imageFile != null) {
        setState(() {
          isLoading = true;
        });
        upLoadFile();
      }
    }
  }

  Future upLoadFile() async {
    String fileName = DateTime.now().microsecondsSinceEpoch.toString();
    Logger.clap('Chat Page file name', fileName);
    UploadTask uploadTask = chatProvider.uploadFile(imageFile!, fileName);
    Logger.clap('Chat Page image file', imageFile);
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, TypeMessage.image);
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void onSendMessage(String content, int type) {
    if (content.trim().isNotEmpty) {
      textEditingController.clear();
      chatProvider.sendMessage(
        content,
        type,
        groupChatId,
        currentUserId,
        peerId,
      );
      Logger.clap('Chat Page type', type);
      Logger.clap('Chat Page content', content);
      listScrollCotroller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      Fluttertoast.showToast(
        msg: 'Nothing to send',
        backgroundColor: ColorConstants.greyColor,
      );
    }
  }

  void getSticker() {
    Logger.clap('Chat Page get Sticker', 'get Sticker');
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) ==
                currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) !=
                currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      chatProvider.updateDataFirestore(
        FirestoreConstants.pathUserCollection,
        currentUserId,
        {FirestoreConstants.chattingWith: null},
      );
      Navigator.pop(context);
    }
    return Future.value(false);
  }

  void _callPhoneNumber(String callPhoneNumber) async {
    var url = 'tel://$callPhoneNumber';
    if (await canLaunchUrl(url as Uri)) {
      await launchUrl(url as Uri);
    } else {
      throw 'Error occurred';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.grey,
        iconTheme: const IconThemeData(
          color: ColorConstants.primaryColor,
        ),
        title: Text(
          peerNickName,
          style: const TextStyle(
            color: ColorConstants.primaryColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              SettingProvider settingProvider;
              settingProvider = context.read<SettingProvider>();
              String callPhoneNUmer =
                  settingProvider.getPrefs(FirestoreConstants.phoneNumber) ??
                      "";
              _callPhoneNumber(callPhoneNUmer);
            },
            icon: const Icon(
              Icons.phone_iphone,
              size: 30,
              color: ColorConstants.primaryColor,
            ),
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: onBackPress,
        child: Stack(
          children: [
            Column(
              children: [
                buildListMessage(),
                isShowSticker ? buildSticker() : const SizedBox.shrink(),
                buildInput(),
              ],
            ),
            buildLoading(),
          ],
        ),
      ),
    );
  }

  Widget buildSticker() {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.all(5),
      height: 180,
      decoration: const BoxDecoration(
          border: Border(
              top: BorderSide(color: ColorConstants.greyColor2, width: 0.5)),
          color: Colors.white),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => onSendMessage('mimi1', TypeMessage.sticker),
                child: Image.asset(
                  'images/mimi1.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton(
                onPressed: () => onSendMessage('mimi2', TypeMessage.sticker),
                child: Image.asset(
                  'images/mimi2.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton(
                onPressed: () => onSendMessage('mimi3', TypeMessage.sticker),
                child: Image.asset(
                  'images/mimi3.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => onSendMessage('mimi4', TypeMessage.sticker),
                child: Image.asset(
                  'images/mimi4.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton(
                onPressed: () => onSendMessage('mimi5', TypeMessage.sticker),
                child: Image.asset(
                  'images/mimi5.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton(
                onPressed: () => onSendMessage('mimi6', TypeMessage.sticker),
                child: Image.asset(
                  'images/mimi6.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => onSendMessage('mimi7', TypeMessage.sticker),
                child: Image.asset(
                  'images/mimi7.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton(
                onPressed: () => onSendMessage('mimi8', TypeMessage.sticker),
                child: Image.asset(
                  'images/mimi8.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton(
                onPressed: () => onSendMessage('mimi9', TypeMessage.sticker),
                child: Image.asset(
                  'images/mimi9.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          )
        ],
      ),
    ));
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading ? const LoadingView() : const SizedBox.shrink(),
    );
  }

  Widget buildInput() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: ColorConstants.greyColor2, width: 0.5),
          ),
          color: Colors.white),
      child: Row(
        children: [
          // get image button
          Material(
            color: Colors.white,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                onPressed: getImage,
                icon: const Icon(
                  Icons.camera_enhance,
                  color: ColorConstants.primaryColor,
                ),
              ),
            ),
          ),
          // get sticker
          Material(
            color: Colors.white,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                onPressed: getSticker,
                icon: const Icon(
                  Icons.face_retouching_natural,
                  color: ColorConstants.primaryColor,
                ),
              ),
            ),
          ),
          // type your message
          Flexible(
            child: TextField(
              onSubmitted: (value) {
                onSendMessage(
                  textEditingController.text,
                  TypeMessage.text,
                );
              },
              style: const TextStyle(
                color: ColorConstants.primaryColor,
                fontSize: 15,
              ),
              controller: textEditingController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Type your message...',
                hintStyle: TextStyle(
                  color: ColorConstants.greyColor,
                ),
              ),
              focusNode: focusNode,
            ),
          ),
          // send message button
          Material(
            color: Colors.white,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                onPressed: () =>
                    onSendMessage(textEditingController.text, TypeMessage.text),
                icon: const Icon(
                  Icons.send,
                  color: ColorConstants.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(int idx, DocumentSnapshot? document) {
    if (document != null) {
      MessageChat messageChat = MessageChat.fromDocument(document);
      if (messageChat.idFrom == currentUserId) {
        Logger.clap('Chat Page messageChat.type', messageChat.type);
        var data = MessageChat.fromDocument(document);
        Logger.i('Chat page messageList data11', data.content);
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            messageChat.type == TypeMessage.text
                ? Container(
                    padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                    width: 200,
                    decoration: BoxDecoration(
                      color: ColorConstants.greyColor2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: EdgeInsets.only(
                      bottom: isLastMessageRight(idx) ? 20 : 10,
                      right: 10,
                    ),
                    child: Text(
                      messageChat.content,
                      style: const TextStyle(
                        color: ColorConstants.primaryColor,
                      ),
                    ),
                  )
                : messageChat.type == TypeMessage.image
                    ? Container(
                        margin: EdgeInsets.only(
                          bottom: isLastMessageRight(idx) ? 20 : 10,
                          right: 10,
                        ),
                        child: OutlinedButton(
                          onPressed: () {
                            Logger.d('Chat Page Image', 'Pressed on images');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (cxt) =>
                                    FullPhotoPage(url: messageChat.content),
                              ),
                            );
                          },
                          style: ButtonStyle(
                            padding: MaterialStateProperty.all<EdgeInsets>(
                              const EdgeInsets.all(0),
                            ),
                          ),
                          child: Material(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Image.network(
                              messageChat.content,
                              loadingBuilder: (context, child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  decoration: const BoxDecoration(
                                    color: ColorConstants.greyColor2,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  width: 200,
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: ColorConstants.themeColor,
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                      null &&
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Material(
                                  clipBehavior: Clip.hardEdge,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(8)),
                                  child: Image.asset(
                                    'images/img_not_available.jpeg',
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        margin: EdgeInsets.only(
                          bottom: isLastMessageRight(idx) ? 20 : 10,
                          right: 10,
                        ),
                        child: Image.asset(
                          'images/${messageChat.content}.gif',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
          ],
        );
      } else {
        Logger.clap('Chat page messageList data peerAvatar', peerAvatar);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  isLastMessageLeft(idx)
                      ? Material(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(18),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Image.network(
                            peerAvatar,
                            // 'https://lh3.googleusercontent.com/a/AGNmyxYKd5jZPbYPvg78guachjaL3nfokfIL9xrW21xP=s96-c',
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  color: ColorConstants.themeColor,
                                  value: loadingProgress.expectedTotalBytes !=
                                              null &&
                                          loadingProgress.expectedTotalBytes !=
                                              null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.account_circle,
                                size: 35,
                                color: ColorConstants.greyColor,
                              );
                            },
                            width: 35,
                            height: 35,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 35,
                        ),
                  messageChat.type == TypeMessage.text
                      ? Container(
                          padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                          width: 200,
                          margin: const EdgeInsets.only(left: 10),
                          decoration: const BoxDecoration(
                            color: ColorConstants.primaryColor,
                            borderRadius: BorderRadius.all(
                              Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            messageChat.content,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        )
                      : messageChat.type == TypeMessage.image
                          ? Container(
                              // margin: EdgeInsets.only(
                              //   bottom: isLastMessageRight(idx) ? 20 : 10,
                              //   right: 10,
                              // ),
                              margin: const EdgeInsets.only(
                                left: 10,
                              ),
                              child: TextButton(
                                onPressed: () {
                                  Logger.d('Tapped on image',
                                      'pressed on left image');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (cxt) => FullPhotoPage(
                                          url: messageChat.content),
                                    ),
                                  );
                                },
                                style: ButtonStyle(
                                  padding:
                                      MaterialStateProperty.all<EdgeInsets>(
                                    const EdgeInsets.all(0),
                                  ),
                                ),
                                child: Material(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: Image.network(
                                    messageChat.content,
                                    loadingBuilder: (context, child,
                                        ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        decoration: const BoxDecoration(
                                          color: ColorConstants.greyColor2,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(8),
                                          ),
                                        ),
                                        width: 200,
                                        height: 200,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: ColorConstants.themeColor,
                                            value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null &&
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Material(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                      child: Image.asset(
                                        'images/img_not_available.jpeg',
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              margin: EdgeInsets.only(
                                bottom: isLastMessageRight(idx) ? 20 : 10,
                                right: 10,
                              ),
                              child: Image.asset(
                                'images/${messageChat.content}.gif',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                ],
              ),
              isLastMessageLeft(idx)
                  ? Container(
                      margin:
                          const EdgeInsets.only(left: 50, top: 5, bottom: 5),
                      child: Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(
                          DateTime.fromMillisecondsSinceEpoch(
                            int.parse(
                              messageChat.timestamp,
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          color: ColorConstants.greyColor,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : const SizedBox.shrink()
            ],
          ),
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
              stream: chatProvider.getChatStream(groupChatId, _limit),
              builder: (cxt, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  listMessage.addAll(snapshot.data!.docs);
                  DocumentSnapshot data = listMessage.last;
                  Logger.w('Chat page messageList data buildMessage',
                      MessageChat.fromDocument(data));
                  return ListView.builder(
                    itemCount: snapshot.data?.docs.length,
                    reverse: true,
                    controller: listScrollCotroller,
                    itemBuilder: (context, idx) =>
                        buildItem(idx, snapshot.data?.docs[idx]),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ColorConstants.themeColor,
                    ),
                  );
                }
              },
            )
          : const Center(
              child: CircularProgressIndicator(
                color: ColorConstants.themeColor,
              ),
            ),
    );
  }
}
