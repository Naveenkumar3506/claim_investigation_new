import 'package:claim_investigation/models/case_model.dart';
import 'package:claim_investigation/models/report_model.dart';
import 'db_manager.dart';

class DBHelper {
  static Future saveCases(List<CaseModel> arrayCaseModel) async {
    final db = DbManager.db;
    arrayCaseModel.forEach((caseModel) async {
      await db.insert(DbManager.caseTable, caseModel.toMap());
    });
  }

  static Future<List<CaseModel>> getAllCases() async {
    final listCases = await DbManager.db.queryAllRows(DbManager.caseTable);
    return List<CaseModel>.from(listCases.map((x) => CaseModel.fromMap(x)));
  }

  static Future updateCaseDetail(CaseModel caseModel) async {
    await DbManager.db.update(DbManager.caseTable, 'caseId = ?',
        [caseModel.caseId], caseModel.toMap());
  }

  static Future updateCaseSyncStatus(CaseModel caseModel, int syncStatus) async {
    await DbManager.db.update(DbManager.caseTable, 'caseId = ?',
        [caseModel.caseId], {"syncStatus": syncStatus});
  }

  static Future saveReport(ReportModel reportModel) async {
    final db = DbManager.db;
    await db.insert(DbManager.dashBoardTable, reportModel.toMap());
  }

  static Future<ReportModel> getReport() async {
    final report = await DbManager.db.queryAllRows(DbManager.dashBoardTable);
    return ReportModel.fromMap(report.first);
  }
}
