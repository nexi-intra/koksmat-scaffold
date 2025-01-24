FROM mcr.microsoft.com/azure-cli

RUN apk update
RUN apk add --upgrade powershell   
RUN apk add go

RUN go install github.com/mikefarah/yq/v4@latest
WORKDIR /koksmat
COPY . .
WORKDIR /koksmat/.koksmat/app
RUN go install




CMD [ "sleep","infinity"]