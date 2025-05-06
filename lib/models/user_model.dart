class UserModel {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;

  UserModel({required this.uid, this.displayName, this.email, this.photoURL});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      displayName: json['displayName'],
      email: json['email'],
      photoURL: json['photoURL'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
    };
  }
}