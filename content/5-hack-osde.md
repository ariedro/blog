+++
title = "Hacking my health insurance security token generation"
description = "The true hippie with OSDE"
date = "2024-09-01"
[taxonomies]
tags=["hacking", "cryptography"]
+++

Following up with my quest to clean my phone from apps that I was forced to
install by living in a civilization that doesn't care about bloated software.
This time it was the turn of my health insurance app.

I have OSDE. On there, in order to have a medical appointment, purchase
discounted medications and other related actions, you MUST have installed the
OSDE app, not only for presenting the card credential number, but for it to
give you a "token" that generates every 5 minutes.

You show this token to the person who is taking your medical appointment or
purchase, thus validating that you are authorized to do it.

{{ figure(src="/osde-app.jpg", position="center" caption_position="left", caption="OSDE App with generated token, in this case is 602 and it will be valid for 2 minutes") }}

I don't think this seem like a particularly bad way to validate your authority
to use the service, but I'd rather not have an app installed for something
that could be a card. And I knew this could be circunvented because it works
offline.

So here we go with the hack.

## OTP

Asking to a friend about this, I realized that this app implements a
cryptographic
[One-Time Password (OTP)](https://en.wikipedia.org/wiki/One-time_password)
just like Google Authenticator.

In short this takes a static identity seed, the current timestamp (mod by
5 minutes), and hashes it, producing a number that should guarantee the user's
identity in that moment.

Knowing this, and having my phone rooted, I could grep the app's storage and
find the needed seed.

After a few attempts I found what I was looking for:

```sh
$ strings /data/data/ar.com.osde.ads/databases/credencialDigitalSqlite | grep OTP
credenciales"[ ... ,\"semilla\":\"( This is it )\" ... ]"/
```

## Matching the token

Having the seed, all I had to do was replicate the same encodings and options
that the app uses.

After a few failed attempts with publicly available OTP libraries, I realized
that it would be easier to decompile the app and take a look at how the app is
actually hashing the seed.

As with the [trains app hack](/3-hack-trains-api), I used the jadx program
and took a peek inside.

Quickly I found it:

```js
otplib_otplib_browser__WEBPACK_IMPORTED_MODULE_4__["totp"].options = {
    digits: 3,
    step: 300,
    algorithm: 'sha256',
    createHmacSecret: function (secret, params) {
        return secret;
    }
```

With this I've got both the encodings and the js library used ([otplib](https://www.npmjs.com/package/otplib)).

And finally I was able to reproduce the same token generation as the app:

```js
const { totp } = require('otplib');

const seed = "...";

totp.options = {
    digits: 3,
    step: 300,
    algorithm: "sha256",
    createHmacSecret: function (secret, params) {
        return secret;
    }
};

console.log(totp.generate(seed));
```

```sh
$ node index.js
602
```

## Minimizing the code

From previous work experience, I have had major problems relying on external
cryptographic libraries. So this time I would like to not depend on otplib and
have it to manually generate the token by myself.

By scrapping the otplib code and minimizing it to only do the generation for
this type of token, I ended up with a compact version of it:

```js
const { createHmac } = require("crypto");

const seed = "...";

const generateToken = (secret) => {
  const counter = Math.floor(new Date().getTime() / 300000)
    .toString(16)
    .padStart(16, "0");
  const digest = createHmac("sha256", secret)
    .update(Buffer.from(counter, "hex"))
    .digest();
  const offset = digest[digest.length - 1] & 0xf;
  const binary =
    ((digest[offset] & 0x7f) << 24) |
    ((digest[offset + 1] & 0xff) << 16) |
    ((digest[offset + 2] & 0xff) << 8) |
    (digest[offset + 3] & 0xff);
  const tokenNumber = binary % Math.pow(10, 3);
  return tokenNumber.toString().padStart(3, "0");
};

console.log(generateToken(seed));
```

## OSDE-CLI

For the final touch I ended up adding a few optional parameters and printing
extra information. This way anyone could use this "terminal version of the OSDE
app", without the need to use the official one.

{{ figure(src="/osde-cli.jpg", position="center" caption_position="left", caption="Running it on Termux, much faster than the OSDE app") }}

I published it [on a github repository](https://github.com/ariedro/osde-cli),
so anyone can use it freely.

I hope you liked this blogpost, until next time.