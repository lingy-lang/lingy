FROM alpine:3.17

RUN apk add \
        bash \
        build-base \
        perl \
        perl-app-cpanminus \
        perl-dev \
        perl-utils \
        readline-dev \
 && cpanm -n \
        Capture::Tiny \
        Term::ReadLine::Gnu \
        Tie::IxHash \
        XXX \
        YAML::PP \
 && true

ENV PATH /host/perl/bin:$PATH
