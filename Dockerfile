FROM alpine as build

# tinytex dependencies
RUN apk --no-cache add \
  perl  \
  wget \
  xz \
  tar \
  fontconfig \
  freetype \
  lua \
  gcc

# add user install as appuser and setup workdir
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

USER appuser
WORKDIR /home/appuser

# setup path
ENV PATH=/home/appuser/.TinyTeX/bin/x86_64-linuxmusl/:$PATH

# download and install tinytex
RUN wget -qO- "https://yihui.name/gh/tinytex/tools/install-unx.sh" | sh

# add tlmgr to path
RUN /home/appuser/.TinyTeX/bin/*/tlmgr path add

# verify latex and tlmgr version
RUN latex --version && tlmgr --version

# install texlive packages
RUN tlmgr install \
    preview \
    standalone \
    dvisvgm

# verify 
RUN dvisvgm --version

FROM alpine as production

RUN apk --no-cache add perl

# add user install as appuser and setup workdir
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
WORKDIR /home/appuser

COPY --from=build /home/appuser/.TinyTeX /home/appuser/.TinyTeX

ENV PATH=/home/appuser/.TinyTeX/bin/x86_64-linuxmusl:$PATH

# setup test workdir
RUN mkdir /tmp/test
WORKDIR /tmp/test
# copy test latex standalone equation
COPY ./test.tex .

# run latex - ignore latex errors
RUN latex -interaction=nonstopmode  ./test.tex || true

# run dvisvgm with no-fonts
# verify no-font svg was generated
# run dvisvgm with ttf font
# verify ttf font svg was generated
RUN dvisvgm --no-fonts ./test.dvi && test -f test.svg \
  && rm test.svg && dvisvgm --font-format=ttf ./test.dvi \
  && test -f test.svg && rm -R /tmp/*

# reset workdir
WORKDIR /home/appuser