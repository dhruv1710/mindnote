import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  return NotesNotifier();
});

class NotesNotifier extends StateNotifier<List<Note>>{
  NotesNotifier() : super([]);
  final String apiUrl = 'http://localhost:8000/api';
  final dio = Dio();


  Future<List<Note>> fetchNotes(userId, query) async {
    final response = await dio.get('$apiUrl/search', queryParameters: {'id': 1, 'q': 'demo'});
    print("response:$response");
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((noteJson) => Note.fromJson(noteJson)).toList();
    } else {
      throw Exception('Failed to fetch notes');
    }
  }

  Future<Note> createNote(Note note) async {
    final response = await http.post(
      Uri.parse('$apiUrl/add'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(note.toJson()),
    );
    if (response.statusCode == 201) {
      final dynamic data = json.decode(response.body);
      state = [...state, note];
      return Note.fromJson(data);
    } else {
      throw Exception('Failed to create note');
    }
    
  }

  Future<Note> updateNote(Note note) async {
    final response = await http.put(
      Uri.parse('$apiUrl/notes/${note.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(note.toJson()),
    );
    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body);
      return Note.fromJson(data);
    } else {
      throw Exception('Failed to update note');
    }
  }

  Future<void> deleteNote(String noteId) async {
    final response = await http.delete(Uri.parse('$apiUrl/notes/$noteId'));
    state = state.where((note) => note.id != noteId).toList();
    if (response.statusCode != 204) {
      throw Exception('Failed to delete note');
    }
  }
}

class Note {
  final String id;
  final String userId;
  final String document;

  Note({
    required this.id,
    required this.userId,
    required this.document,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      userId: json['user_id'],
      document: json['document'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'document': document,
    };
  }
}