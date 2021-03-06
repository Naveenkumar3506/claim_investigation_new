import 'dart:convert';

ReportModel reportModelFromJson(String str) => ReportModel.fromJson(json.decode(str));

String reportModelToJson(ReportModel data) => json.encode(data.toJson());

class ReportModel {
  ReportModel({
    this.pivPrvLiveCount,
    this.reportModelNew,
    this.claimDocumentPickup,
    this.closed,
    this.actionedByInvestigator,
  });

  int pivPrvLiveCount;
  int reportModelNew;
  int claimDocumentPickup;
  int closed;
  int actionedByInvestigator;

  factory ReportModel.fromJson(Map<String, dynamic> json) => ReportModel(
    pivPrvLiveCount: json["PIV/PRV/LIVE count"],
    reportModelNew: json["New"],
    claimDocumentPickup: json["Claim Document Pickup"],
    closed: json["Closed"],
    actionedByInvestigator: json["Actioned by Investigator"],
  );

  Map<String, dynamic> toJson() => {
    "PIV/PRV/LIVE count": pivPrvLiveCount,
    "New": reportModelNew,
    "Claim Document Pickup": claimDocumentPickup,
    "Closed": closed,
    "Actioned by Investigator": actionedByInvestigator,
  };
}