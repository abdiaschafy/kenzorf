# ─── Étape 1 : build Angular (Node 22 requis pour Angular 22) ───
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# ─── Étape 2 : service statique via Nginx ───
FROM nginx:1.27-alpine AS serve
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/back-office/browser /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
