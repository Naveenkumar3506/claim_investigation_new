import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

CaseModel caseModelFromJson(String str) => CaseModel.fromJson(json.decode(str));

String caseModelToJson(CaseModel data) => json.encode(data.toJson());

class CaseModel {
  CaseModel({
    this.caseId,
    this.policyNumber,
    this.investigation,
    this.insuredName,
    this.insuredDod,
    this.insuredDob,
    this.sumAssured,
    this.intimationType,
    this.location,
    this.caseStatus,
    this.nomineeName,
    this.nomineeContactNumber,
    this.nomineeAddress,
    this.insuredAddress,
    this.caseDescription,
    this.longitude,
    this.latitude,
    this.pdf1FilePath,
    this.pdf2FilePath,
    this.pdf3FilePath,
    this.audioFilePath,
    this.videoFilePath,
    this.signatureFilePath,
    this.capturedDate,
    this.createdBy,
    this.createdDate,
    this.updatedDate,
    this.updatedBy,
    this.remarks,
    this.image,
    this.excelFilepath,
    this.newRemarks,
    this.image2,
  });

  int caseId;
  String policyNumber;
  Investigation investigation;
  String insuredName;
  DateTime insuredDod;
  DateTime insuredDob;
  double sumAssured;
  String intimationType;
  Location location;
  String caseStatus;
  String nomineeName;
  String nomineeContactNumber;
  String nomineeAddress;
  String insuredAddress;
  String caseDescription;
  String longitude;
  String latitude;
  String pdf1FilePath;
  String pdf2FilePath;
  String pdf3FilePath;
  String audioFilePath;
  String videoFilePath;
  String signatureFilePath;
  String capturedDate;
  String createdBy;
  DateTime createdDate;
  DateTime updatedDate;
  String updatedBy;
  String remarks;
  String image;
  String newRemarks;
  String excelFilepath;
  String image2;

  factory CaseModel.fromJson(Map<String, dynamic> json) => CaseModel(
        caseId: json["caseId"],
        policyNumber: json["policyNumber"],
        investigation: json["investigation"] != null
            ? Investigation.fromJson(json["investigation"])
            : null,
        insuredName: json["insuredName"],
        insuredDod: json["insuredDOD"] != null && json["insuredDOD"] != ""
            ? DateFormat('yyyy-MM-ddThh:mm:ss.000+00:00')
                .parse(json["insuredDOD"])
            : null,
        insuredDob: json["insuredDOB"] != null && json["insuredDOD"] != ""
            ? DateFormat('yyyy-MM-ddThh:mm:ss.000+00:00')
                .parse(json["insuredDOB"])
            : null,
        sumAssured: json["sumAssured"],
        intimationType: json["intimationType"],
        location: json["location"] != null
            ? Location.fromJson(json["location"])
            : null,
        caseStatus: json["caseStatus"],
        nomineeName: json["nominee_Name"],
        nomineeContactNumber: json["nominee_ContactNumber"],
        nomineeAddress: json["nominee_address"],
        insuredAddress: json["insured_address"],
        caseDescription: json["case_description"],
        longitude: json["longitude"],
        latitude: json["latitude"],
        pdf1FilePath: json["pdf1FilePath"],
        pdf2FilePath: json["pdf2FilePath"],
        pdf3FilePath: json["pdf3FilePath"],
        audioFilePath: json["audioFilePath"],
        videoFilePath: json["videoFilePath"],
        signatureFilePath: json["signatureFilePath"],
        capturedDate: json["capturedDate"],
        createdBy: json["createdBy"],
        createdDate: json["createdDate"] != null
            ? DateTime.parse(json["createdDate"])
            : null,
        updatedDate: json["updatedDate"] != null
            ? DateTime.parse(json["updatedDate"])
            : null,
        updatedBy: json["updatedBy"],
        remarks: json["remarks"],
        image: json["image"],
        excelFilepath: json["excelFilepath"],
        newRemarks: json["newRemarks"],
        image2: json["image2"],
      );

  Map<String, dynamic> toJson() => {
        "caseId": caseId,
        "policyNumber": policyNumber,
        "investigation": investigation != null ? investigation.toJson() : null,
        "insuredName": insuredName,
        "insuredDOD":
            DateFormat('yyyy-MM-ddThh:mm:ss.000+00:00').format(insuredDod),
        "insuredDOB":
            DateFormat('yyyy-MM-ddThh:mm:ss.000+00:00').format(insuredDob),
        "sumAssured": sumAssured,
        "intimationType": intimationType,
        "location": location.toJson(),
        "caseStatus": caseStatus,
        "nominee_Name": nomineeName,
        "nominee_ContactNumber": nomineeContactNumber,
        "nominee_address": nomineeAddress,
        "insured_address": insuredAddress,
        "case_description": caseDescription,
        "longitude": longitude,
        "latitude": latitude,
        "pdf1FilePath": pdf1FilePath,
        "pdf2FilePath": pdf2FilePath,
        "pdf3FilePath": pdf3FilePath,
        "audioFilePath": audioFilePath,
        "videoFilePath": videoFilePath,
        "signatureFilePath": signatureFilePath,
        "capturedDate": capturedDate,
        "createdBy": createdBy,
        "createdDate":
            DateFormat('yyyy-MM-ddThh:mm:ss.000+00:00').format(createdDate),
        "updatedDate":
            DateFormat('yyyy-MM-ddThh:mm:ss.000+00:00').format(updatedDate),
        "updatedBy": updatedBy,
        "remarks": remarks,
        "image2": image2,
      };

  factory CaseModel.fromMap(Map<String, dynamic> json) => CaseModel(
        caseId: json["caseId"],
        policyNumber: json["policyNumber"],
        investigation: json["investigation"] != null
            ? Investigation.fromJson(jsonDecode(json["investigation"]))
            : null,
        insuredName: json["insuredName"],
        insuredDod: json["insuredDOD"] != null
            ? DateFormat('yyyy-MM-ddThh:mm:ss.000+00:00')
                .parse(json["insuredDOD"])
            : null,
        insuredDob: json["insuredDOB"] != null
            ? DateFormat('yyyy-MM-ddThh:mm:ss.000+00:00')
                .parse(json["insuredDOB"])
            : null,
        sumAssured: json["sumAssured"],
        intimationType: json["intimationType"],
        location: json["location"] != null
            ? Location.fromJson(jsonDecode(json["location"]))
            : null,
        caseStatus: json["caseStatus"],
        nomineeName: json["nominee_Name"],
        nomineeContactNumber: json["nominee_ContactNumber"],
        nomineeAddress: json["nominee_address"],
        insuredAddress: json["insured_address"],
        caseDescription: json["case_description"],
        longitude: json["longitude"],
        latitude: json["latitude"],
        pdf1FilePath: json["pdf1FilePath"],
        pdf2FilePath: json["pdf2FilePath"],
        pdf3FilePath: json["pdf3FilePath"],
        audioFilePath: json["audioFilePath"],
        videoFilePath: json["videoFilePath"],
        signatureFilePath: json["signatureFilePath"],
        capturedDate: json["capturedDate"],
        createdBy: json["createdBy"],
        createdDate: json["createdDate"] != null
            ? DateTime.parse(json["createdDate"])
            : null,
        updatedDate: json["updatedDate"] != null
            ? DateTime.parse(json["updatedDate"])
            : null,
        updatedBy: json["updatedBy"],
        remarks: json["remarks"],
        image: json["image"],
        excelFilepath: json["excelFilepath"],
        newRemarks: json["newRemarks"],
        image2: json["image2"],
      );

  Map<String, dynamic> toMap() => {
        "caseId": caseId,
        "policyNumber": policyNumber,
        "investigation":
            investigation != null ? jsonEncode(investigation.toJson()) : null,
        "insuredName": insuredName,
        "insuredDOD": insuredDod != null
            ? DateFormat('yyyy-MM-ddThh:mm:ss.000+00:00').format(insuredDod)
            : null,
        "insuredDOB": insuredDob != null
            ? DateFormat('yyyy-MM-ddThh:mm:ss.000+00:00').format(insuredDob)
            : null,
        "sumAssured": sumAssured,
        "intimationType": intimationType,
        "location": location != null ? jsonEncode(location.toJson()) : null,
        "caseStatus": caseStatus,
        "nominee_Name": nomineeName,
        "nominee_ContactNumber": nomineeContactNumber,
        "nominee_address": nomineeAddress,
        "insured_address": insuredAddress,
        "case_description": caseDescription,
        "longitude": longitude,
        "latitude": latitude,
        "pdf1FilePath": pdf1FilePath,
        "pdf2FilePath": pdf2FilePath,
        "pdf3FilePath": pdf3FilePath,
        "audioFilePath": audioFilePath,
        "videoFilePath": videoFilePath,
        "signatureFilePath": signatureFilePath,
        "excelFilepath": excelFilepath,
        "capturedDate": capturedDate,
        "createdBy": createdBy,
        "createdDate": createdDate != null
            ? DateFormat('yyyy-MM-ddThh:mm:ss.000+00:00').format(createdDate)
            : null,
        "updatedDate": updatedDate != null
            ? DateFormat('yyyy-MM-ddThh:mm:ss.000+00:00').format(updatedDate)
            : null,
        "updatedBy": updatedBy,
        "remarks": remarks,
        "image": image,
        "newRemarks": newRemarks,
        "image2": image2,
      };
}

class Investigation {
  Investigation({
    this.investigationType,
  });

  String investigationType;

  factory Investigation.fromJson(Map<String, dynamic> json) => Investigation(
        investigationType: json["investigationType"],
      );

  Map<String, dynamic> toJson() => {
        "investigationType": investigationType,
      };
}

class Location {
  Location({
    this.city,
    this.state,
    this.zone,
  });

  String city;
  String state;
  String zone;

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        city: json["city"],
        state: json["state"],
        zone: json["zone"],
      );

  Map<String, dynamic> toJson() => {
        "city": city,
        "state": state,
        "zone": zone,
      };
}
