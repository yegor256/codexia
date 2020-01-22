FROM node:12
RUN apt-get update && \
    apt-get install -y openjdk-8-jdk && \
    apt-get install -y ant && \
    apt-get clean
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY . /usr/src/app
RUN npm install
RUN chmod +x postgres-data
RUN npm run build-with-docker
EXPOSE 8000
CMD [ "npm", "run", "run-with-docker" ]
