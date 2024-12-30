FROM node:latest

RUN apt update -y && apt-get install -y git
RUN npm i -g @nestjs/cli

USER node

WORKDIR /workspaces/terraform-slack-notification/app/terraform-slack-notification
CMD ["npm", "start"]