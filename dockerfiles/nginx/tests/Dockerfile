FROM alpine

RUN apk add --update python3
RUN pip3 install flask

COPY basic_app.py /

CMD ["python3", "/basic_app.py"]
