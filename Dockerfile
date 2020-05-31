FROM swift:5.2 as builder
WORKDIR /build
COPY . .
RUN swift test -c release -Xswiftc -enable-testing
