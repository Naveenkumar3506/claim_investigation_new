import 'dart:io';

//
import 'package:claim_investigation/models/case_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DbManager {
  DbManager._();

  static final DbManager db = DbManager._();
  static Database _database;

  static final _databaseVersion = 1;
  static final databaseName = "claim.db";
  static final caseTable = 'CaseTable';
  static final dashBoardTable = 'DashBoardTable';
  static final PIVCaseTable = 'PIVCaseTable';
  static final NewCaseTable = 'NewCaseTable';
  static final CDPCaseTable = 'CDPCaseTable';
  static final ClosedCaseTable = 'ClosedCaseTable';
  static final InvestigatorCaseTable = 'InvestigatorCaseTable';
  static final syncCaseTable = 'syncCaseTable';
  //
  Future<Database> get database async {
    if (_database != null) return _database;
    // if _database is null we instantiate it
    _database = await _initDB();
    return _database;
  }

  /// initialize DB
  _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, databaseName);
    print("DBpath->$path");
    return await openDatabase(path, version: _databaseVersion, onOpen: (db) {},
        onCreate: (Database db, int version) async {
      await db.execute(
          "CREATE TABLE $caseTable (caseId INTEGER PRIMARY KEY, policyNumber TEXT, investigation TEXT, insuredName TEXT, insuredDOD TEXT, insuredDOB TEXT, sumAssured REAL, intimationType TEXT, location TEXT, caseStatus TEXT, caseSubStatus TEXT, nominee_Name TEXT, nominee_ContactNumber TEXT, nominee_address TEXT, pincode TEXT, insured_address TEXT, case_description TEXT, longitude TEXT, latitude TEXT, pdf1FilePath TEXT, pdf2FilePath TEXT, pdf3FilePath TEXT, audioFilePath TEXT, videoFilePath TEXT, signatureFilePath TEXT, excelFilepath TEXT, image TEXT, image2 TEXT, capturedDate TEXT, createdBy TEXT, createdDate TEXT, updatedDate TEXT, updatedBy TEXT, remarks TEXT, newRemarks TEXT ,fromUser TEXT, caseMovementStatus TEXT)");
      await db.execute(
          "CREATE TABLE $PIVCaseTable (caseId INTEGER PRIMARY KEY, policyNumber TEXT, investigation TEXT, insuredName TEXT, insuredDOD TEXT, insuredDOB TEXT, sumAssured REAL, intimationType TEXT, location TEXT, caseStatus TEXT, caseSubStatus TEXT, nominee_Name TEXT, nominee_ContactNumber TEXT, nominee_address TEXT, pincode TEXT, insured_address TEXT, case_description TEXT, longitude TEXT, latitude TEXT, pdf1FilePath TEXT, pdf2FilePath TEXT, pdf3FilePath TEXT, audioFilePath TEXT, videoFilePath TEXT, signatureFilePath TEXT, excelFilepath TEXT, image TEXT, image2 TEXT, capturedDate TEXT, createdBy TEXT, createdDate TEXT, updatedDate TEXT, updatedBy TEXT, remarks TEXT, newRemarks TEXT ,fromUser TEXT, caseMovementStatus TEXT)");
      await db.execute(
          "CREATE TABLE $NewCaseTable (caseId INTEGER PRIMARY KEY, policyNumber TEXT, investigation TEXT, insuredName TEXT, insuredDOD TEXT, insuredDOB TEXT, sumAssured REAL, intimationType TEXT, location TEXT, caseStatus TEXT, caseSubStatus TEXT, nominee_Name TEXT, nominee_ContactNumber TEXT, nominee_address TEXT, pincode TEXT, insured_address TEXT, case_description TEXT, longitude TEXT, latitude TEXT, pdf1FilePath TEXT, pdf2FilePath TEXT, pdf3FilePath TEXT, audioFilePath TEXT, videoFilePath TEXT, signatureFilePath TEXT, excelFilepath TEXT, image TEXT, image2 TEXT, capturedDate TEXT, createdBy TEXT, createdDate TEXT, updatedDate TEXT, updatedBy TEXT, remarks TEXT, newRemarks TEXT ,fromUser TEXT, caseMovementStatus TEXT)");
      await db.execute(
          "CREATE TABLE $CDPCaseTable (caseId INTEGER PRIMARY KEY, policyNumber TEXT, investigation TEXT, insuredName TEXT, insuredDOD TEXT, insuredDOB TEXT, sumAssured REAL, intimationType TEXT, location TEXT, caseStatus TEXT, caseSubStatus TEXT, nominee_Name TEXT, nominee_ContactNumber TEXT, nominee_address TEXT, pincode TEXT, insured_address TEXT, case_description TEXT, longitude TEXT, latitude TEXT, pdf1FilePath TEXT, pdf2FilePath TEXT, pdf3FilePath TEXT, audioFilePath TEXT, videoFilePath TEXT, signatureFilePath TEXT, excelFilepath TEXT, image TEXT, image2 TEXT, capturedDate TEXT, createdBy TEXT, createdDate TEXT, updatedDate TEXT, updatedBy TEXT, remarks TEXT, newRemarks TEXT ,fromUser TEXT, caseMovementStatus TEXT)");
      await db.execute(
          "CREATE TABLE $ClosedCaseTable (caseId INTEGER PRIMARY KEY, policyNumber TEXT, investigation TEXT, insuredName TEXT, insuredDOD TEXT, insuredDOB TEXT, sumAssured REAL, intimationType TEXT, location TEXT, caseStatus TEXT, caseSubStatus TEXT, nominee_Name TEXT, nominee_ContactNumber TEXT, nominee_address TEXT, pincode TEXT, insured_address TEXT, case_description TEXT, longitude TEXT, latitude TEXT, pdf1FilePath TEXT, pdf2FilePath TEXT, pdf3FilePath TEXT, audioFilePath TEXT, videoFilePath TEXT, signatureFilePath TEXT, excelFilepath TEXT, image TEXT, image2 TEXT, capturedDate TEXT, createdBy TEXT, createdDate TEXT, updatedDate TEXT, updatedBy TEXT, remarks TEXT, newRemarks TEXT ,fromUser TEXT, caseMovementStatus TEXT)");
      await db.execute(
          "CREATE TABLE $InvestigatorCaseTable (caseId INTEGER PRIMARY KEY, policyNumber TEXT, investigation TEXT, insuredName TEXT, insuredDOD TEXT, insuredDOB TEXT, sumAssured REAL, intimationType TEXT, location TEXT, caseStatus TEXT, caseSubStatus TEXT, nominee_Name TEXT, nominee_ContactNumber TEXT, nominee_address TEXT, pincode TEXT, insured_address TEXT, case_description TEXT, longitude TEXT, latitude TEXT, pdf1FilePath TEXT, pdf2FilePath TEXT, pdf3FilePath TEXT, audioFilePath TEXT, videoFilePath TEXT, signatureFilePath TEXT, excelFilepath TEXT, image TEXT, image2 TEXT, capturedDate TEXT, createdBy TEXT, createdDate TEXT, updatedDate TEXT, updatedBy TEXT, remarks TEXT, newRemarks TEXT ,fromUser TEXT, caseMovementStatus TEXT)");
      await db.execute(
          "CREATE TABLE $syncCaseTable (caseId INTEGER PRIMARY KEY, policyNumber TEXT, investigation TEXT, insuredName TEXT, insuredDOD TEXT, insuredDOB TEXT, sumAssured REAL, intimationType TEXT, location TEXT, caseStatus TEXT, caseSubStatus TEXT, nominee_Name TEXT, nominee_ContactNumber TEXT, nominee_address TEXT, pincode TEXT, insured_address TEXT, case_description TEXT, longitude TEXT, latitude TEXT, pdf1FilePath TEXT, pdf2FilePath TEXT, pdf3FilePath TEXT, audioFilePath TEXT, videoFilePath TEXT, signatureFilePath TEXT, excelFilepath TEXT, image TEXT, image2 TEXT, capturedDate TEXT, createdBy TEXT, createdDate TEXT, updatedDate TEXT, updatedBy TEXT, remarks TEXT, newRemarks TEXT ,fromUser TEXT, caseMovementStatus TEXT)");
      await db.execute(
          "CREATE TABLE $dashBoardTable (PIV INTEGER, new INTEGER, cdp INTEGER, closed INTEGER, investigator INTEGER)");
    });
  }

  Future<int> insert(String table, Map<String, dynamic> row, bool isReplace) async {
    Database db = await database;
    print('insert into $table');
    return await db.insert(table, row,
        conflictAlgorithm: isReplace == true ? ConflictAlgorithm.replace : ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    Database db = await database;
    return await db.query(table);
  }

  Future<List<Map<String, dynamic>>> queryRows(
      String table, String whereCondition, List<dynamic> arguments) async {
    Database db = await database;
    return await db.query(table, where: whereCondition, whereArgs: arguments);
  }

  Future<int> update(String table, String whereCondition,
      List<dynamic> arguments, Map<String, dynamic> row) async {
    Database db = await database;
    final fff = await db.update(table, row,
        where: whereCondition, whereArgs: arguments);
    return fff;
  }

  Future<int> delete(
      String table, String whereCondition, List<dynamic> arguments) async {
    Database db = await database;
    final fff =
        await db.delete(table, where: whereCondition, whereArgs: arguments);
    return fff;
  }

  Future<int> deleteAll(String table) async {
    Database db = await database;
    return await db.delete(table);
  }
}
