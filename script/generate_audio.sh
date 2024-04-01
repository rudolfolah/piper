#!/bin/sh
DOCKER_IMAGE=${DOCKER_IMAGE:-"piper:with-voice"}
TEXT=$1
echo "$TEXT" > /tmp/text.txt
echo "Running the container"
docker run -d -it --entrypoint sh -w /dist/piper --name piper $DOCKER_IMAGE
docker cp /tmp/text.txt piper:/dist/piper/text.txt
echo "Generating the audio"
docker exec piper sh -c "cat /dist/piper/text.txt | ./piper --model voice_file.onnx --output_file /dist/piper/output.wav"
docker cp piper:/dist/piper/output.wav ./output.wav
echo "Stopping and removing the container"
docker stop piper
docker rm piper
