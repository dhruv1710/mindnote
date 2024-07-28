import numpy as np
import openwakeword.utils
from qdrant_client import QdrantClient
from tqdm import tqdm
from fastapi import FastAPI, Request, WebSocket
import json
import uuid
from openwakeword.model import Model
import openwakeword
import io
from pydub import AudioSegment
from pydub.silence import detect_nonsilent
from search import Searcher
from datetime import datetime
import whisper
import ssl
ssl._create_default_https_context = ssl._create_unverified_context

# Constants
CHUNK = 1024

app = FastAPI()

owwModel = Model(wakeword_models=['./models/hey_jarvis_v0.1.tflite'],)

# Create a neural searcher instance
hybrid_searcher = Searcher(collection_name="mindnote")
asr_model = whisper.load_model("medium")

client  = QdrantClient("http://localhost:6333")

# Using Hybrid approach with Neural and Semantic Search
client.set_model("sentence-transformers/all-MiniLM-L6-v2")
client.set_sparse_model("prithivida/Splade_PP_en_v1")

@app.get("/api/search")
def search_notes(id: str,q: str):
    return {"result": hybrid_searcher.search(user=id, text=q)}

@app.put("/api/add")
def add_notes(id: str,content: str):
    note_id = str(uuid.uuid4())
    res = client.add(
        collection_name="mindnote",
        documents=[content],
        metadata=[{"user_id":id,'id':note_id}],
        ids=[note_id]
    )
    return {"result": json.loads(f"{res}")}

# @app.post("/api/listen")
# def listen_notes(request: Request):
#     stream = request.stream()
#     result = process_stream(stream)
#     return {"result": json.loads(f"{res}")}

# Tools
def detect(stream):
    
    audio = np.frombuffer(stream, dtype=np.int16)

    # Feed to openWakeWord model
    prediction = owwModel.predict(audio)

    # Column titles
    

    for mdl in owwModel.prediction_buffer.keys():
        # Add scores in formatted table
        scores = list(owwModel.prediction_buffer[mdl])
        curr_score = format(scores[-1], '.20f').replace("-", "")
        print(scores[-1])
        if scores[-1] > 0.001:
            wakeword_status = "Wakeword Detected"
            print(f"{mdl} | {curr_score} | {wakeword_status}")
            return True
        else:
            return False

async def asr_pipeline(audio_stream):
    # Convert bytes to numpy array for Whisper processing
    audio = np.frombuffer(audio_stream, np.int16).astype(np.float32) / 32768.0
    result = asr_model.transcribe(audio)
    transcription = result['text']
    return transcription
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    buffer = io.BytesIO()
    recording = False

    while True:
        try:
            data = await websocket.receive_bytes()
            buffer.write(data)
            audio_data = buffer.getvalue()
            if not recording:
                if detect(audio_data):
                    print("Wakeword detected")
                    await websocket.send_text("wake word detected")
                    recording = True
                    buffer = io.BytesIO()  # Clear the buffer to start fresh recording
                    start = datetime.now()
            else:
                if is_silent(audio_data):
                    print("Recording stopped")
                    await websocket.send_text("recording stopped")
                    recording = False
                    buffer = io.BytesIO()  # Clear the buffer after stopping recording
                elif (datetime.now() - start).total_seconds()/60 > 1 and (datetime.now() - start).seconds > 10:
                    print("Recording stopped after 1 minute")
                    await websocket.send_text("recording stopped after 1 minute")
                    recording = False
                    buffer = io.BytesIO()
                else:
                    transcription = await asr_pipeline(buffer.getvalue())
                    print("Recording in progress")
                    await websocket.send_text(transcription)
                    # buffer = io.BytesIO()

        except Exception as e:
            print(f"Error: {e}")
            await websocket.close()
            break

def is_silent(audio_data):
    # Convert raw audio data to an AudioSegment
    audio_segment = AudioSegment.from_raw(io.BytesIO(audio_data), sample_width=2, frame_rate=16000, channels=1)
    # Detect non-silent chunks in the audio data
    nonsilent_chunks = detect_nonsilent(audio_segment, min_silence_len=1000, silence_thresh=-50)
    return len(nonsilent_chunks) == 0

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)