#Can change to a dockerhub mirror site like: FROM docker.1ms.run/alpine:latest
FROM alpine:latest
#Add a goproxy
ENV GOPROXY "https://goproxy.cn,https://mirrors.aliyun.com/goproxy/,direct"
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
#Install Tailscale and requirements
RUN apk add curl iptables

#Install GO and Tailscale DERPER
RUN APKARCH="$(apk --print-arch)" && \
    case "${APKARCH}" in \
        x86_64) GOARCH=amd64 ;; \
        aarch64) GOARCH=arm64 ;; \
        armv7*|armhf) GOARCH=armv6l ;; \
        x86) GOARCH=386 ;; \
        ppc64le) GOARCH=ppc64le ;; \
        s390x) GOARCH=s390x ;; \
        *) echo "Unsupported architecture: ${APKARCH}" >&2; exit 1 ;; \
    esac && \
    LATEST="$(curl -fsSL 'https://golang.google.cn/VERSION?m=text'| head -n 1)" && \
    curl -fsSL "https://dl.google.com/go/${LATEST}.linux-${GOARCH}.tar.gz" -o go.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz
ENV PATH="/usr/local/go/bin:$PATH"
RUN go install tailscale.com/cmd/derper@latest

#Install Tailscale and Tailscaled
RUN apk add tailscale

#Copy init script
COPY init.sh /init.sh
RUN chmod +x /init.sh

#Derper Web Ports
EXPOSE 444/tcp
#STUN
EXPOSE 3478/udp

ENTRYPOINT /init.sh
