FROM mcr.microsoft.com/devcontainers/python:1-3.12-bullseye

RUN apt-get update; \ 
    apt-get install -y \ 
    build-essential \
    libglpk-dev \
    libglpk40 \
    glpk-utils \
    glpk-doc

#COPY requirements.txt /tmp/requirements.txt
#    RUN pip install -r /tmp/requirements.txt