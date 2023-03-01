import 'dart:io';

import 'package:chat_chat/allConstants/app_constants.dart';
import 'package:chat_chat/allConstants/color_constants.dart';
import 'package:chat_chat/allConstants/constants.dart';
import 'package:chat_chat/allModels/user_chat.dart';
import 'package:chat_chat/allProviders/setting_provider.dart';
import 'package:chat_chat/allWidgets/loading.dart';
import 'package:chat_chat/appCoreFeatures/logger.dart';
import 'package:chat_chat/main.dart';
import 'package:country_picker/country_picker.dart';
// import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.black,
        iconTheme: const IconThemeData(
          color: ColorConstants.primaryColor,
        ),
        title: const Text(
          AppConstants.settingsTitle,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
      ),
      body: const SettingsPageState(),
    );
  }
}

class SettingsPageState extends StatefulWidget {
  const SettingsPageState({super.key});

  @override
  State<SettingsPageState> createState() => _SettingsPageStateState();
}

class _SettingsPageStateState extends State<SettingsPageState> {
  late final FlCountryCodePicker countryPicker;
  CountryCode? countryCode;
  Country? country;
  TextEditingController? controllerNickName;
  TextEditingController? controllerAboutMe;
  String dailCodeDitgits = "";
  final TextEditingController _controller = TextEditingController();

  String id = "";
  String nickName = "";
  String aboutMe = "";
  String photoUrl = "";
  String phoneNumber = "";

  bool isLoading = false;
  File? avatarImageFile;
  late SettingProvider settingProvider;
  final FocusNode focusNodeNickname = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    super.initState();
    settingProvider = context.read<SettingProvider>();
    countryPicker = const FlCountryCodePicker();
    // Logger.e('SettingsPage', countryPicker);
    readLocal();
  }

  void pickCountry() {
    showCountryPicker(
        context: context,
        onSelect: (Country _country) {
          setState(() {
            country = _country;
            dailCodeDitgits = country!.phoneCode;
            Logger.i('Flag', dailCodeDitgits);
          });
        });
  }

  void readLocal() {
    setState(() {
      id = settingProvider.getPrefs(FirestoreConstants.id) ?? '';
      nickName = settingProvider.getPrefs(FirestoreConstants.nickname) ?? '';
      aboutMe = settingProvider.getPrefs(FirestoreConstants.aboutMe) ?? '';
      photoUrl = settingProvider.getPrefs(FirestoreConstants.photoUrl) ?? '';
      phoneNumber =
          settingProvider.getPrefs(FirestoreConstants.phoneNumber) ?? '';
    });

    controllerNickName = TextEditingController(text: nickName);
    controllerAboutMe = TextEditingController(text: aboutMe);
    Logger.clap('Aboutme', aboutMe);
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile? pickedFile = await imagePicker
        .getImage(source: ImageSource.gallery)
        .catchError((err) {
      Fluttertoast.showToast(msg: err.toString());
    });
    File? image;
    if (pickedFile != null) {
      image = File(pickedFile.path);
    }
    if (image != null) {
      setState(() {
        avatarImageFile = image;
        isLoading = true;
      });
      uploadFile();
    }
  }

  uploadFile() async {
    String fileName = id;
    UploadTask uploadTask =
        settingProvider.uploadFile(avatarImageFile!, fileName);

    try {
      TaskSnapshot snapshot = await uploadTask;
      photoUrl = await snapshot.ref.getDownloadURL();
      UserChat updateInfo = UserChat(
        id: id,
        photoUrl: photoUrl,
        nickName: nickName,
        aboutMe: aboutMe,
        phoneNumber: phoneNumber,
      );
      settingProvider
          .updateDataFirestore(
              FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
          .then((value) async {
        await settingProvider.setPrefs(FirestoreConstants.photoUrl, photoUrl);
        setState(() {
          isLoading = false;
        });
      }).catchError((err) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: err.toString());
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.message.toString());
    }
  }

  void handleUpdatedData() {
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();

    setState(() {
      isLoading = true;
      if (dailCodeDitgits != "+59" && _controller.text != "") {
        phoneNumber = '+${dailCodeDitgits + _controller.text.toString()}';
      }
    });
    UserChat updateInfo = UserChat(
      id: id,
      photoUrl: photoUrl,
      nickName: nickName,
      aboutMe: aboutMe,
      phoneNumber: phoneNumber,
    );

    settingProvider
        .updateDataFirestore(
            FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
        .then((value) async {
      await settingProvider.setPrefs(FirestoreConstants.nickname, nickName);
      await settingProvider.setPrefs(FirestoreConstants.aboutMe, aboutMe);
      await settingProvider.setPrefs(FirestoreConstants.photoUrl, photoUrl);
      await settingProvider.setPrefs(
          FirestoreConstants.phoneNumber, phoneNumber);
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "Update success");
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(
        msg: err.toString(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    Logger.e('PhoneNumber', phoneNumber);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoButton(
                  onPressed: getImage,
                  child: avatarImageFile == null
                      ? photoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(45),
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                width: 90,
                                height: 90,
                                errorBuilder: (context, object, stackTrace) {
                                  return const Icon(
                                    Icons.account_circle,
                                    size: 90,
                                    color: ColorConstants.greyColor,
                                  );
                                },
                                loadingBuilder: (cxt, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 90,
                                    height: 90,
                                    child: CircularProgressIndicator(
                                      color: Colors.grey,
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
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.account_circle,
                              size: 90,
                              color: ColorConstants.greyColor,
                            )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(45),
                          child: Image.file(
                            avatarImageFile!,
                            width: 90,
                            height: 90,
                            fit: BoxFit.contain,
                          ),
                        ),
                ),

                //
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin:
                          const EdgeInsets.only(left: 10, bottom: 5, top: 10),
                      child: const Text(
                        'Name',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryColor,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                            primaryColor: ColorConstants.primaryColor),
                        child: TextField(
                          style: const TextStyle(color: Colors.grey),
                          decoration: const InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: ColorConstants.greyColor2),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: ColorConstants.primaryColor),
                            ),
                            hintText: 'Write you name....',
                            contentPadding: EdgeInsets.all(5),
                            hintStyle:
                                TextStyle(color: ColorConstants.greyColor),
                          ),
                          controller: controllerNickName,
                          onChanged: (val) {
                            nickName = val;
                          },
                          focusNode: focusNodeNickname,
                        ),
                      ),
                    ),
                    Container(
                      margin:
                          const EdgeInsets.only(left: 10, bottom: 5, top: 10),
                      child: const Text(
                        'About me',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryColor,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                            primaryColor: ColorConstants.primaryColor),
                        child: TextField(
                          style: const TextStyle(color: Colors.grey),
                          decoration: const InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: ColorConstants.greyColor2),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: ColorConstants.primaryColor),
                            ),
                            hintText: 'Write you about....',
                            contentPadding: EdgeInsets.all(5),
                            hintStyle:
                                TextStyle(color: ColorConstants.greyColor),
                          ),
                          controller: controllerAboutMe,
                          onChanged: (val) {
                            aboutMe = val;
                          },
                          focusNode: focusNodeAboutMe,
                        ),
                      ),
                    ),
                    Container(
                      margin:
                          const EdgeInsets.only(left: 10, bottom: 5, top: 10),
                      child: const Text(
                        'Phone number',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryColor,
                        ),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: pickCountry,
                        child: const Text('Pick Country'),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                            primaryColor: ColorConstants.primaryColor),
                        child: TextField(
                          style: const TextStyle(color: Colors.grey),
                          decoration: InputDecoration(
                              hintText: phoneNumber,
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: ColorConstants.greyColor2),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: ColorConstants.primaryColor),
                              ),
                              contentPadding: const EdgeInsets.all(5),
                              hintStyle: const TextStyle(color: Colors.grey),
                              prefix: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '+$dailCodeDitgits',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              )),
                          maxLength: 12,
                          keyboardType: TextInputType.number,
                          controller: _controller,

                          // focusNode: focu,
                        ),
                      ),
                    ),
                  ],
                ),
                // update button
                Container(
                  margin: const EdgeInsets.only(top: 50, bottom: 50),
                  child: TextButton(
                    onPressed: handleUpdatedData,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          ColorConstants.primaryColor),
                      padding: MaterialStateProperty.all<EdgeInsets>(
                        const EdgeInsets.fromLTRB(30, 10, 30, 10),
                      ),
                    ),
                    child: const Text(
                      'Update Now',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
              child: isLoading ? const LoadingView() : const SizedBox.shrink()),
        ],
      ),
    );
  }
}
