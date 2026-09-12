FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY --from=builder /app/dist ./dist

# The app's ONLY runtime filesystem write is the tenant upload directory —
# backend/src/lib/uploads.ts mkdirs /app/uploads when NODE_ENV=production (verified: it is
# the sole writeFile/mkdir call in backend/src). So make exactly that path writable by the
# unprivileged user and leave everything else root-owned: /app and the code inside it stay
# read-only to the app process, so a compromised dependency cannot rewrite its own source
# or the node_modules it executes.
RUN mkdir -p /app/uploads \
    && chown node:node /app/uploads

ENV PORT=8080
ENV NODE_ENV=production
# Chrome/crashpad-style tools and some node internals want a writable HOME; node:alpine
# already ships /home/node for this user.
ENV HOME=/home/node

# node:20-alpine ships an unprivileged `node` user (uid 1000) — no need to create one.
# Dropping root is blast-radius control: a compromised dependency starts without root
# inside the container, which is the difference between "read the env" and "talk to the
# container runtime".
USER node

EXPOSE 8080
CMD ["node", "dist/index.js"]
