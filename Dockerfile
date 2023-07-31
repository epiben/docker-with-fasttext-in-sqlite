FROM python:3.8.0

RUN apt-get update && apt-get install -y \
  build-essential \
  wget \
  git \
  unzip \
  && rm -rf /var/cache/apk/*

# Use bash shell to enable arrays (https://stackoverflow.com/a/70976397)
SHELL ["/bin/bash", "-c"]

# === INSTALL DEPENDENCIES ===
RUN pip3 install --upgrade pip
COPY requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt --no-cache-dir

# === DOWNLOAD PRE-TRAINED FASTTEXT KEYED VECTORS ===
WORKDIR /fasttext_keyed_vectors
COPY put_keyedvectors_in_sqlite.py .

# ca: Catalan, da: Danish, de: German, en: English, es: Spanish, it: Italian
ENV languages="ca da de en es it"

# Keep the aligned and non-aligned in two layers
RUN for l in $languages; do \
    # Aligned keyed vectors
    wget --progress=bar:force:noscroll --show-progress -q \
      https://dl.fbaipublicfiles.com/fasttext/vectors-aligned/wiki.$l.align.vec && \
    python3 put_keyedvectors_in_sqlite.py \
      --fpath_dotvec wiki.$l.align.vec \
      --fpath_database fasttext.db \
      --table_name $(echo "${l}_aligned") && \
    rm wiki.$l.align.vec; \
  done

RUN for l in $languages; do \
    # Non-aligned keyed vectors
    wget --progress=bar:force:noscroll --show-progress -q \
      https://dl.fbaipublicfiles.com/fasttext/vectors-crawl/cc.$l.300.vec.gz && \
    gzip -d cc.$l.300.vec.gz && \
    python3 put_keyedvectors_in_sqlite.py \
      --fpath_dotvec cc.$l.300.vec \
      --fpath_database fasttext.db \
      --table_name $(echo "${l}_original") && \
    rm cc.$l.300.vec; \
  done

WORKDIR /
