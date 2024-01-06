import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mynotes/services/crud/crud_exceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

// opening the DB
class NoteService {
  Database? _db;

  List<DatabaseNote> _notes = [];
  final _noteStreamController =
      StreamController<List<DatabaseNote>>.broadcast();

  //Get or create user
  Future<DatabaseUser> getOrCreateUser({
    required String email,
  }) async {
    try {
      final user = await getUser(email: email);
      return user;
    } on CouldNotFindUser {
      final createdUser = await createUser(email: email);
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  // ignore: unused_element
  Future<void> _cacheNotes() async {
    final allNotes = await getALLNote();
    _notes = allNotes.toList();
    _noteStreamController.add(_notes);
  }

  //Update existing notes
  Future<DatabaseNote> updatetNote({
    required DatabaseNote note,
    required String text,
  }) async {
    final db = _getDatabaseOrThrow();
    // ensure the note exist
    await getNote(id: note.id);

    // update database
    final updateCount = await db.update(
      noteTable,
      {
        textColum: text,
        isSyncedWithServerColum: 0,
      },
    );
    if (updateCount == 0) {
      throw CouldNotUpdateNote();
    } else {
      final updateNote = await getNote(id: note.id);
      _notes.removeWhere((note) => note.id == updateNote.id);
      _notes.add(updateNote);
      _noteStreamController.add(_notes);
      return updateNote;
    }
  }

  //fetch all notes
  Future<Iterable<DatabaseNote>> getALLNote() async {
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      noteTable,
    );
    return notes.map(
      (noteRow) => DatabaseNote.fromRow(noteRow),
    );
  }

  //fetching a speccific note
  Future<DatabaseNote> getNote({required int id}) async {
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      noteTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (notes.isEmpty) {
      throw CouldNotFindNote();
    } else {
      final note = DatabaseNote.fromRow(notes.first);
      _notes.removeWhere((note) => note.id == id);
      _notes.add(note);
      _noteStreamController.add(_notes);
      return note;
    }
  }

  //Delete all note
  Future<int> deleteALLNote() async {
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(noteTable);
    _notes = [];
    _noteStreamController.add(_notes);
    return numberOfDeletions;
  }

  //Delete single the notes
  Future<void> deleteNote({required int id}) async {
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteNote();
    } else {
      _notes.removeWhere((note) => note.id == id);
      _noteStreamController.add(_notes);
    }
  }

  // Creating the note
  Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
    final db = _getDatabaseOrThrow();

    //make sure owner exist in the database with the current id
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw CouldNotDeleteUser();
    }
    const text = '';
    //create note
    final noteId = await db.insert(noteTable, {
      userIdColumn: owner.id,
      textColum: text,
      isSyncedWithServerColum: 1,
    });
    final note = DatabaseNote(
      id: noteId,
      userId: owner.id,
      text: text,
      isSyncedWithServer: true,
    );
    _notes.add(note);
    _noteStreamController.add(_notes);
    return note;
  }

  //Get user
  Future<DatabaseUser> getUser({required String email}) async {
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = 1',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      throw CouldNotFindUser();
    }
    return DatabaseUser.fromRow(results.first);
  }

  // Creating a user
  Future<DatabaseUser> createUser({required String email}) async {
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = 1',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExist();
    }
    final userId = await db.insert(
      userTable,
      {emailColumn: email.toLowerCase()},
    );
    return DatabaseUser(id: userId, email: email);
  }

  //Allowing to delete user
  Future<void> deleteUser({required String email}) async {
    final db = _getDatabaseOrThrow();
    final deletedCount =
        await db.delete(userTable, where: 'email = ?', whereArgs: [
      email.toLowerCase(),
    ]);
    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  //Convenience function for getting current database
  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseNotOpened();
    } else {
      return db;
    }
  }

  // closing the db
  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseNotOpened();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenedException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;

      // Execute command
      await db.execute(createUserTable);
      await db.execute(createNoteTable);
      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;

  const DatabaseUser({
    required this.id,
    required this.email,
  });

  // instanciating frome a row
  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  //convert instance to string
  @override
  String toString() => 'Person, ID = $id , email = $email';

  //implementing the equality behaviour of the class
  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithServer;

  DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithServer,
  });

  // instanciating frome a row
  DatabaseNote.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColum] as String,
        isSyncedWithServer =
            (map[isSyncedWithServerColum] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Note, ID = $id , userId = $userId, isSyncedWithServer = $isSyncedWithServer, text = $text';

  //implementing the equality behaviour of the class
  @override
  bool operator ==(covariant DatabaseNote other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColum = 'text';
const isSyncedWithServerColum = 'is_Synced_With_Server';
const dbName = 'notes.db';
const noteTable = 'notes';
const userTable = 'user';
// Creating the talbe since the database as an onCreate function if the database does not exist;
const createUserTable = '''
        CREATE TABLE IF NOT EXISTS "user"(
        "id"	INTEGER NOT NULL,
        "email"	TEXT NOT NULL UNIQUE,
        PRIMARY KEY("id" AUTOINCREMENT)
      );
    ''';

const createNoteTable = ''' CREATE TABLE IF NOT EXISTS "note" (
        "id"	INTEGER NOT NULL,
        "user_id"	INTEGER NOT NULL,
        "text"	TEXT,
        "is_synced_with_server"	INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY("user_id") REFERENCES " user"("id")
        ); 
        ''';
