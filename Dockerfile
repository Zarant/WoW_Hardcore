#syntax=docker/dockerfile:1.2

FROM akorn/luarocks:lua5.4-alpine AS builder

RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing \
	dumb-init gcc libc-dev

RUN luarocks install bit32
RUN luarocks install busted