#!/bin/sh
TEXT=$1
echo "$TEXT" > /tmp/text.txt
docker run -d -it --entrypoint bash --name piper piper:en-voice
docker cp /tmp/text.txt piper:/dist/piper/text.txt
docker exec piper bash -c "cat /dist/piper/text.txt | ./piper --model voice_file.onnx --output_file /dist/piper/output.wav"
docker cp piper:/dist/piper/output.wav ./output.wav
docker stop piper
docker rm piper
