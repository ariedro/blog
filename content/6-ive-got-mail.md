+++
title = "I've got mail"
description = "And you can too"
date = "2025-02-02"
[taxonomies]
tags=["self-hosted", "protocols"]
+++

Recently I've started to notice that I'm getting my mail notifications late,
I used to get the inbox directly with the `atom.xml` that Gmail provides and
be notified by checking my RSS feed, the problem is that this only gets
updated every 20 minutes or so.

The obvious solution would be to have a mail app that is constantly updating
the inbox and getting notified that way, but this is costly for my phone,
which is kind of old and not in the best debloated shape.

So for this I wanted to make something like I've already done [previously](/1-smtp-faker),
which is a way to relay this to a server process and be notified via Telegram.

## IMAP

Internet Message Access Protocol is one of the two standard protocols for
retrieving mails from a remote mail server. Being the most used one I chose
it over POP3, but this could have been done with POP3 as well.

It works like normal application layers old internet protocols such as SMTP,
in the way that the session is managed via plain text querying commands and
retrieving the results.

## Programming the solution

For my purposes, I only wanted to get the latest unread mails, so the only
query that I need to do is to fetch the mails on the inbox. However, being
that this is a little more complicated than SMTP, this time I will be using
an external library, so no hardcoding commands this time.

I used NodeJs for this and used the [node-imap](https://www.npmjs.com/package/node-imap) library.
The code for this is kind of ugly as it's event-based so it doesn't follow a
sequential flow.

Basically what I did was:

1. Establish a connection
1. Open the inbox
1. Fetch the messages, filtering only the headers fields `SUBJECT` and `FROM`
1. For each message do some parsing, both of its headers as well as its metadata
1. If the message doesn't have a `\\Seen` flag and hasn't already been cached, send it to Telegram
1. Save the message to the cache
1. Exit

You can check out the full code [here](https://github.com/ariedro/youve-got-mail/blob/master/index.js).

## Seeing it in action

On Telegram I've created yet another bot for this specific purpose, that way I
can customize its notification sound to be the iconical "You've got mail" voice
alert each time I get a new mail.

{{ audio(src="/imap-youvegotmail.ogg" position="center" caption_position="left", caption="The iconical voice alert") }}

And here's a censored screenshot of it in action:

{{ figure(src="/imap-screenshot.png", position="center") }}

Now I can get notified for my mails right away, without having bloat running on my phone!