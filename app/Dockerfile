FROM node:latest


WORKDIR /workspaces/terraform-slack-notification/app
COPY --chown=node:node ./terraform-slack-notification .

RUN apt update -y && apt-get install -y git
RUN npm i -g @nestjs/cli

WORKDIR /workspaces/terraform-slack-notification/app/terraform-slack-notification
RUN chown -R node:node /workspaces
USER node

CMD ["npm", "start"]