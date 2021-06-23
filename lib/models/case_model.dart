import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

CaseModel caseModelFromJson(String str) => CaseModel.fromJson(json.decode(str));

String caseModelToJson(CaseModel data) => json.encode(data.toJson());

class CaseModel {
  CaseModel(
      {this.caseId,
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
      this.capturedDate,
      this.createdBy,
      this.createdDate,
      this.updatedDate,
      this.updatedBy,
      this.remarks,
      this.newRemarks,
      this.caseDocs});

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
  String capturedDate;
  String createdBy;
  DateTime createdDate;
  DateTime updatedDate;
  String updatedBy;
  String remarks;
  String newRemarks;
  List<CaseDoc> caseDocs;

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
        newRemarks: json["newRemarks"],
        caseDocs: json["case_Docs"] == null
            ? null
            : List<CaseDoc>.from(
                json["case_Docs"].map((x) => CaseDoc.fromJson(x))),
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
        "capturedDate": capturedDate,
        "createdBy": createdBy,
        "createdDate":
            DateFormat('yyyy-MM-ddThh:mm:ss.000+00:00').format(createdDate),
        "updatedDate":
            DateFormat('yyyy-MM-ddThh:mm:ss.000+00:00').format(updatedDate),
        "updatedBy": updatedBy,
        "remarks": remarks,
        "case_Docs": caseDocs == null
            ? null
            : List<dynamic>.from(caseDocs.map((x) => x.toJson())),
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
        newRemarks: json["newRemarks"],
        caseDocs: json["case_Docs"] == null
            ? null
            : List<CaseDoc>.from(
                jsonDecode(json["case_Docs"]).map((x) => CaseDoc.fromJson(x))),
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
        "newRemarks": newRemarks,
        "case_Docs": caseDocs == null
            ? null
            : jsonEncode(List<dynamic>.from(caseDocs.map((x) => x.toJson()))),
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

class CaseDoc {
  CaseDoc({
    this.docType,
    this.docName,
    this.isURL,
  });

  DocType docType;
  String docName;
  bool isURL;
  Uint8List thumbnail;

  factory CaseDoc.fromJson(Map<String, dynamic> json) => CaseDoc(
      docType:
          json["doc_type"] == null ? null : docTypeValues.map[json["doc_type"]],
      docName: json["doc_name"] == null ? null : json["doc_name"],
      isURL: json["isURL"] != null ? json["isURL"] : true);

  Map<String, dynamic> toJson() => {
        "doc_type": docType == null ? null : docTypeValues.reverse[docType],
        "doc_name": docName == null ? null : docName,
        "isURL": isURL
      };
}

enum DocType { PDF, IMAGE, SIGNATURE, VIDEO, AUDIO, EXCEL }

final docTypeValues = EnumValues({
  "audio": DocType.AUDIO,
  "excel": DocType.EXCEL,
  "image": DocType.IMAGE,
  "pdf": DocType.PDF,
  "signature": DocType.SIGNATURE,
  "video": DocType.VIDEO
});

class EnumValues<T> {
  Map<String, T> map;
  Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    if (reverseMap == null) {
      reverseMap = map.map((k, v) => new MapEntry(v, k));
    }
    return reverseMap;
  }
}
