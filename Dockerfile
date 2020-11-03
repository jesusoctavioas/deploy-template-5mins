FROM python:3.8

COPY webapp .

RUN pip install pipenv
RUN pipenv install

EXPOSE 5000

CMD ['pipenv', 'run', 'flask', 'run']
