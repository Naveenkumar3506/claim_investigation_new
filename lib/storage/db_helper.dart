import 'package:claim_investigation/models/case_model.dart';
import 'package:claim_investigation/models/report_model.dart';
import 'db_manager.dart';

class DBHelper {
  static Future saveCases(List<CaseModel> arrayCaseModel, String table) async {
    final db = DbManager.db;
    arrayCaseModel.forEach((caseModel) async {
      await db.insert(table, caseModel.toMap(), false);
    });
  }

  static Future<List<CaseModel>> getAllCases() async {
    final listCases = await DbManager.db.queryAllRows(DbManager.caseTable);
    return List<CaseModel>.from(listCases.map((x) => CaseModel.fromMap(x)));
  }

  static Future<List<CaseModel>> getCasesFromTable(String table) async {
    final listCases = await DbManager.db.queryAllRows(table);
    return List<CaseModel>.from(listCases.map((x) => CaseModel.fromMap(x)));
  }

  static Future updateCaseDetail(CaseModel caseModel, String table) async {
    await DbManager.db
        .update(table, 'caseId = ?', [caseModel.caseId], caseModel.toMap());
  }

  static Future saveCase(CaseModel caseModel, String table) async {
    final db = DbManager.db;
    await db.insert(table, caseModel.toMap(), true);
  }

  static Future deleteCase(CaseModel caseModel, String table) async {
    await DbManager.db.delete(table, 'caseId = ?', [caseModel.caseId]);
  }

  static Future<List<CaseModel>> getCasesToSync() async {
    final listCases = await DbManager.db.queryAllRows(DbManager.syncCaseTable);
    return List<CaseModel>.from(listCases.map((x) => CaseModel.fromMap(x)));
  }

  static Future saveReport(ReportModel reportModel) async {
    final db = DbManager.db;
    await db.insert(DbManager.dashBoardTable, reportModel.toMap(), true);
  }

  static Future deleteReport() async {
    final db = DbManager.db;
    await db.deleteAll(DbManager.dashBoardTable);
  }

  static Future deleteAll(String table) async {
    final db = DbManager.db;
    await db.deleteAll(table);
  }

  static Future<ReportModel> getReport() async {
    final report = await DbManager.db.queryAllRows(DbManager.dashBoardTable);
    return ReportModel.fromMap(report.first);
  }
}
