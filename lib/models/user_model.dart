import 'dart:convert';
import 'dart:convert';

UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));

String userModelToJson(UserModel data) => json.encode(data.toJson());

class UserModel {
  UserModel({
    this.userId,
    this.fullName,
    this.roleName,
    this.username,
    this.userEmail,
    this.mobileNumber,
    this.address1,
    this.address2,
    this.address3,
    this.state,
    this.city,
    this.password,
    this.status,
    this.userImage,
    this.createdBy,
    this.createdon,
    this.updatedDate,
    this.updatedBy,
  });

  int userId;
  String fullName;
  String roleName;
  String username;
  String userEmail;
  String mobileNumber;
  String address1;
  String address2;
  String address3;
  String state;
  String city;
  String password;
  String status;
  String userImage;
  String createdBy;
  DateTime createdon;
  DateTime updatedDate;
  String updatedBy;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userId: json["user_id"],
    fullName: json["full_name"],
    roleName: json["role_name"],
    username: json["username"],
    userEmail: json["user_email"],
    mobileNumber: json["mobile_number"],
    address1: json["address1"],
    address2: json["address2"],
    address3: json["address3"],
    state: json["state"],
    city: json["city"],
    password: json["password"],
    status: json["status"],
    userImage: json["user_image"],
    createdBy: json["createdBy"],
    createdon: DateTime.parse(json["createdon"]),
    updatedDate: DateTime.parse(json["updatedDate"]),
    updatedBy: json["updatedBy"],
  );

  Map<String, dynamic> toJson() => {
    "user_id": userId,
    "full_name": fullName,
    "role_name": roleName,
    "username": username,
    "user_email": userEmail,
    "mobile_number": mobileNumber,
    "address1": address1,
    "address2": address2,
    "address3": address3,
    "state": state,
    "city": city,
    "password": password,
    "status": status,
    "user_image": userImage,
    "createdBy": createdBy,
    "createdon": createdon.toIso8601String(),
    "updatedDate": updatedDate.toIso8601String(),
    "updatedBy": updatedBy,
  };
}
