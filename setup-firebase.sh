#!/usr/bin/env bash
# One-shot Firebase setup for Laminae (project laminae-3b3c4). Run from the repo root.
set -euo pipefail
FB="npx -y firebase-tools@latest"
P=laminae-3b3c4
$FB login
$FB use $P
# Auth providers (Google + email/password) and Firestore (eur3, rules, indexes)
$FB deploy --only auth,firestore --project $P
# Register the web app if none exists, then print its config
APP=$($FB apps:list WEB --project $P --json | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{const r=JSON.parse(d).result||[];console.log(r[0]?r[0].appId:"")})')
if [ -z "$APP" ]; then
  $FB apps:create WEB laminae --project $P
  APP=$($FB apps:list WEB --project $P --json | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>console.log(JSON.parse(d).result[0].appId))')
fi
$FB apps:sdkconfig WEB "$APP" --project $P > /tmp/laminae-sdk.txt
# Patch FIREBASE_CONFIG in index.html
node -e '
const fs=require("fs");const t=fs.readFileSync("/tmp/laminae-sdk.txt","utf8");
const g=k=>(t.match(new RegExp(k+"[\"]?\\s*:\\s*\"([^\"]+)\""))||[])[1]||"";
const c={apiKey:g("apiKey"),authDomain:g("authDomain"),projectId:g("projectId"),appId:g("appId")};
let h=fs.readFileSync("index.html","utf8");
h=h.replace(/const FIREBASE_CONFIG = \{[\s\S]*?\};/,"const FIREBASE_CONFIG = {\n  apiKey: \""+c.apiKey+"\",\n  authDomain: \""+c.authDomain+"\",\n  projectId: \""+c.projectId+"\",\n  appId: \""+c.appId+"\"\n};");
fs.writeFileSync("index.html",h);console.log(c);'
echo "Done. Add bellomatisp.github.io in Authentication > Settings > Authorized domains if sign-in says unauthorized-domain, then commit & push."
