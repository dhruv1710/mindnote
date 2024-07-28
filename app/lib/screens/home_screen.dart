import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:mindnote/providers/notes_provider.dart';
import 'package:mindnote/providers/user_provider.dart';
import 'package:mindnote/services/audio_service.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool listening = false;
  List<Note> notes = [];
  String transcription = '';
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverList(delegate: SliverChildListDelegate.fixed([
            const SizedBox(height: 16),
            Center(child: const Text('Welcome to MindNote!',style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold),)),
            listening?IconButton(onPressed: (){AudioService().stopStreaming();}, icon: Icon(Icons.stop)):
            SizedBox(
              height: 100,
              width: 100,
              child: IconButton(
                iconSize: 50,
                  onPressed: () async {
                    setState(() {
                      listening = true;
                    });
                    await AudioService().startStreaming((newChunkTranscription){
                      setState(() {
                        transcription += newChunkTranscription;
                      });
                    });
                    print(transcription);
                    
                   
                  },
                  icon: listening
                      ? Icon(Icons.keyboard_voice)
                      : Icon(Icons.keyboard_voice_outlined)),
            ),

                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: TextEditingController(),
                        decoration: InputDecoration(
                          hintText: 'Search notes',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: () async {
                              // final userId = ref.read(userProvider).asData!.value.id;
                              print(searchController.text);
                              final notes = await ref.read(notesProvider.notifier).fetchNotes('1', searchController.text);
                              print(notes);
                              setState(() {
                                this.notes = notes;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
          ])),
          
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return ListTile(
                  title: Text(notes[index].document),
                  subtitle: Text(notes[index].userId),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      ref.read(notesProvider.notifier).deleteNote(notes[index].id);
                      setState(() {
                        notes.removeAt(index);
                      });
                    },
                  ),
                );
              },
              
              childCount: notes.length,
            ),
          ),
        ],
      ),
    );
  }
}