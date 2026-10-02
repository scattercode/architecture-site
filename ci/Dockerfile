# A prebuilt rendering image: Quarto + TinyTeX + librsvg + the Python packages
# the generated chapters need. Build and push it once, then point IMAGE in
# .gitlab-ci.yml at it and drop the apt/tinytex steps from before_script.
#
#   docker build -t registry.gitlab.com/<group>/<project>/quarto-render:1.7.32 ci/
#   docker push   registry.gitlab.com/<group>/<project>/quarto-render:1.7.32
ARG QUARTO_VERSION=1.7.32
FROM ghcr.io/quarto-dev/quarto:${QUARTO_VERSION}

RUN apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends librsvg2-bin python3-pip \
 && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN pip install --quiet --break-system-packages -r /tmp/requirements.txt

RUN quarto install tinytex --no-prompt --update-path
ENV PATH="/root/.TinyTeX/bin/x86_64-linux:${PATH}"
