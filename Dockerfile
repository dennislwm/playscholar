# Start by building the application.
FROM golang:1.23 as build

#----------------------
# Install fabric
#   Clone git repo
#   Install fabric
RUN go install github.com/danielmiessler/fabric@latest
RUN mkdir -p /root/.config/fabric && \
  echo DEFAULT_MODEL=gpt-4o-mini > /root/.config/fabric/.env && \
  echo DEFAULT_VENDOR=OpenAI >> /root/.config/fabric/.env && \
  echo PATTERNS_LOADER_GIT_REPO_URL=https://github.com/danielmiessler/fabric.git >> /root/.config/fabric/.env && \
  echo PATTERNS_LOADER_GIT_REPO_PATTERNS_FOLDER=patterns >> /root/.config/fabric/.env && \
  echo OPENAI_API_BASE_URL=https://api.openai.com/v1 >> /root/.config/fabric/.env
RUN fabric --updatepatterns

# # Now copy it into our base image.
FROM gcr.io/distroless/base
COPY --from=build /go/bin/fabric /
COPY --from=build /root/.config/fabric /root/.config/fabric

ENTRYPOINT ["/fabric"]
