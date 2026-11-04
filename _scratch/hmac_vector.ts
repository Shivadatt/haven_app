const enc = new TextEncoder();
const key = await crypto.subtle.importKey("raw", enc.encode("pepper"), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
const sig = await crypto.subtle.sign("HMAC", key, enc.encode("PAIRING1"));
console.log(Array.from(new Uint8Array(sig), (b) => b.toString(16).padStart(2, "0")).join(""));
