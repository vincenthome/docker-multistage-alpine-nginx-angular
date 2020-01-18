FROM alpine:3.10 as nginx-build

# Define build argument for version
ARG VERSION=1.14.2

ENV LIBRARY_PATH=/lib:/usr/lib

# Install build tools, libraries and utilities
RUN apk add --no-cache --virtual .build-deps                          \
        build-base                                                    \
        gnupg                                                         \
        pcre-dev                                                      \
        wget                                                          \
        zlib-dev

# Retrieve, verify and unpack Nginx source
## install Nginx on Ubuntu from Source Distribution including gpg verify:
## https://www.linode.com/docs/web-servers/nginx/installing-nginx-on-ubuntu-12-04-lts-precise-pangolin/
## well-known server: hkp://p80.pool.sks-keyservers.net:80
RUN set -x                                                         && \
    cd /tmp                                                        && \
    gpg --keyserver hkp://p80.pool.sks-keyservers.net:80              \
        --recv-keys 520A9993A1C052F8       						   && \
    wget -q http://nginx.org/download/nginx-${VERSION}.tar.gz      && \
    wget -q http://nginx.org/download/nginx-${VERSION}.tar.gz.asc  && \
    gpg --verify nginx-${VERSION}.tar.gz.asc                       && \
    tar -xf nginx-${VERSION}.tar.gz                                && \
    rm -f nginx-${VERSION}.tar.*

WORKDIR /tmp/nginx-${VERSION}

# Build and install nginx
RUN ./configure                                                       \
        --with-ld-opt="-static"                                       \
        --with-http_sub_module                                     && \
    make install                                                   && \
    strip /usr/local/nginx/sbin/nginx

# Symlink access and error logs to /dev/stdout and /dev/stderr, in
# order to make use of Docker's logging mechanism
RUN ln -sf /dev/stdout /usr/local/nginx/logs/access.log            && \
    ln -sf /dev/stderr /usr/local/nginx/logs/error.log



# Stage 0, "ng-build", based on Node.js, to build and compile the frontend
FROM node:alpine as ng-build

WORKDIR /app

COPY package*.json /app/

RUN npm install

COPY ./ /app/

ARG configuration=production

RUN set -x && \
    npm run build -- --output-path=./dist/out --configuration $configuration


FROM scratch

# Customise static content, and configuration
COPY --from=nginx-build /etc/passwd /etc/group /etc/
COPY --from=nginx-build /usr/local/nginx /usr/local/nginx

COPY --from=ng-build /app/dist/out/ /usr/local/nginx/html
#COPY index.html /usr/local/nginx/html/

COPY nginx.conf /etc/nginx/conf.d/

# Change default stop signal from SIGTERM to SIGQUIT
STOPSIGNAL SIGQUIT

# Expose port
EXPOSE 80

# Define entrypoint and default parameters
ENTRYPOINT ["/usr/local/nginx/sbin/nginx"]
CMD ["-g", "daemon off;"]

# command line
# docker image build -t nginx .
# docker container run --name nginx -d -p 80:80 nginx

# troubleshoot
# Check Status
# docker container ls -l   
# Check log errors
# docker container logs nginx


