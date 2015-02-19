FROM python:2.7.9-wheezy

# set working diretory
COPY . /code/
WORKDIR /code/

RUN apt-get -y update
RUN apt-get install -y \
    build-essential \
    libssl-dev

RUN pip install -r requirements.txt
