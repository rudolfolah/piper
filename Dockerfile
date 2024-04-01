FROM debian:bullseye as build
ARG TARGETARCH
ARG TARGETVARIANT

ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
        build-essential cmake ca-certificates curl pkg-config git

WORKDIR /build

COPY ./ ./
RUN cmake -Bbuild -DCMAKE_INSTALL_PREFIX=install
RUN cmake --build build --config Release
RUN cmake --install build

# Do a test run
RUN ./build/piper --help

# Build .tar.gz to keep symlinks
WORKDIR /dist
RUN mkdir -p piper && \
    cp -dR /build/install/* ./piper/ && \
    tar -czf "piper_${TARGETARCH}${TARGETVARIANT}.tar.gz" piper/

# -----------------------------------------------------------------------------

# FROM debian:bullseye as test
# ARG TARGETARCH
# ARG TARGETVARIANT

# WORKDIR /test

# COPY local/en-us/lessac/low/en-us-lessac-low.onnx \
#      local/en-us/lessac/low/en-us-lessac-low.onnx.json ./

# # Run Piper on a test sentence and verify that the WAV file isn't empty
# COPY --from=build /dist/piper_*.tar.gz ./
# RUN tar -xzf piper*.tar.gz
# RUN echo 'This is a test.' | ./piper/piper -m en-us-lessac-low.onnx -f test.wav
# RUN if [ ! -f test.wav ]; then exit 1; fi
# RUN size="$(wc -c < test.wav)"; \
#     if [ "${size}" -lt "1000" ]; then echo "File size is ${size} bytes"; exit 1; fi

# -----------------------------------------------------------------------------

FROM build as build_with_voice
ARG voice_file en-us-lessac-medium
ENV VOICE_FILE $voice_file
WORKDIR /dist
COPY --from=build /dist/piper /dist/dist
WORKDIR /dist/piper
RUN curl -L --output voice-${VOICE_FILE}.tar.gz https://github.com/rhasspy/piper/releases/download/v0.0.2/voice-${VOICE_FILE}.tar.gz
RUN tar -xvf voice-${VOICE_FILE}.tar.gz
RUN rm voice-${VOICE_FILE}.tar.gz
RUN mv ${VOICE_FILE}.onnx voice_file.onnx
RUN mv ${VOICE_FILE}.onnx.json voice_file.onnx.json
# echo 'Welcome to the world of speech synthesis!' | ./piper --model voice_file.onnx --output_file welcome.wav

FROM debian:bullseye-slim@sha256:a165446a88794db4fec31e35e9441433f9552ae048fb1ed26df352d2b537cb96 as with_voice
COPY --from=build_with_voice /dist/piper /dist/piper
# remove apt cache
RUN rm -rf /var/lib/apt/lists/*
# remove build dependencies
RUN apt-get autoremove --yes

FROM scratch as prod

# COPY --from=test /test/piper_*.tar.gz /test/test.wav ./
COPY --from=build /dist/piper_*.tar.gz ./
