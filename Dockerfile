FROM golang:1.9

RUN go get github.com/krishicks/yaml-patch/cmd/yaml-patch
RUN curl -L -k -o fly https://github.com/concourse/concourse/releases/download/v3.8.0/fly_linux_amd64; chmod +x fly; mv fly /bin/fly
