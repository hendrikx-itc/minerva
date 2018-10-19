FROM ubuntu:latest

# Usage:
# docker run -it -v <your directory>:/documents/
RUN apt-get install -y git

ENV DEBIAN_FRONTEND noninteractive

# Update apt-get sources AND install stuff
RUN apt-get update && apt-get install -y -q python-sphinx texlive texlive-latex-extra pandoc build-essential

RUN mkdir documents

WORKDIR /documents

CMD ["/bin/bash"]
