# Replica do AWS lambda (usando py 3.7 pq é o mais novo q funfa com o selenium)
FROM lambci/lambda:python3.6

USER root

ENV APP_DIR /var/task

WORKDIR $APP_DIR

COPY requirements.txt .

COPY bin ./bin
COPY lib ./lib

RUN mkdir -p $APP_DIR/lib
RUN pip install --upgrade pip
RUN pip install -r requirements.txt -t /var/task/lib