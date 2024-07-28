# Mind Note - AI Voice Note-Taking and Retreival

## Installation Requirements
Flutter 3.11 or above
Python 3.10 or above

## Setup
Go to the backend code and do
``` pip install -r requirements.txt ```
``` flutter pub get ```

## To Run the QDrantDB

```
docker run -p 6333:6333 \          
    -v $(pwd)/qdrant_storage:/qdrant/storage \
    qdrant/qdrant
```


