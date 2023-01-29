FROM node:18-alpine as base

WORKDIR /usr/src/app

COPY package*.json ./
COPY .npmrc ./

RUN npm i

COPY . .

CMD [ "npm", "start" ]
