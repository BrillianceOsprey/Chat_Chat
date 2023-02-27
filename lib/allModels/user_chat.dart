// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:chat_chat/allConstants/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserChat {
  String id;
  String photoUrl;
  String nickName;
  String aboutMe;
  String phoneNumber;
  UserChat({
    required this.id,
    required this.photoUrl,
    required this.nickName,
    required this.aboutMe,
    required this.phoneNumber,
  });

  UserChat copyWith({
    String? id,
    String? photoUrl,
    String? nickName,
    String? aboutMe,
    String? phoneNumber,
  }) {
    return UserChat(
      id: id ?? this.id,
      photoUrl: photoUrl ?? this.photoUrl,
      nickName: nickName ?? this.nickName,
      aboutMe: aboutMe ?? this.aboutMe,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      FirestoreConstants.nickname: nickName,
      FirestoreConstants.aboutMe: aboutMe,
      FirestoreConstants.photoUrl: photoUrl,
      FirestoreConstants.phoneNumber: phoneNumber,
    };
  }

  factory UserChat.fromDocument(DocumentSnapshot doc) {
    String aboutMe = "";
    String photoUrl = "";
    String nickName = "";
    String phoneNumber = "";

    try {
      aboutMe = doc.get(FirestoreConstants.aboutMe);
    } catch (e) {}
    try {
      photoUrl = doc.get(FirestoreConstants.photoUrl);
    } catch (e) {}
    try {
      nickName = doc.get(FirestoreConstants.nickname);
    } catch (e) {}
    try {
      phoneNumber = doc.get(FirestoreConstants.phoneNumber);
    } catch (e) {}
    return UserChat(
      id: doc.id,
      photoUrl: photoUrl,
      nickName: nickName,
      aboutMe: aboutMe,
      phoneNumber: phoneNumber,
    );
  }

  @override
  String toString() {
    return 'UserChat(id: $id, photoUrl: $photoUrl, nickName: $nickName, aboutMe: $aboutMe, phoneNumber: $phoneNumber)';
  }

  @override
  bool operator ==(covariant UserChat other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.photoUrl == photoUrl &&
        other.nickName == nickName &&
        other.aboutMe == aboutMe &&
        other.phoneNumber == phoneNumber;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        photoUrl.hashCode ^
        nickName.hashCode ^
        aboutMe.hashCode ^
        phoneNumber.hashCode;
  }
}
