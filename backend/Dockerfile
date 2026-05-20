FROM node:20-alpine
WORKDIR /app
COPY src ./src
RUN cd src && npm install --omit=dev
EXPOSE 3001
CMD ["node", "src/index.js"]
