+++
title = "How I tricked my camera into believing it was sending mails"
description = "Millennial discovers network protocols"
date = "2022-03-04"
[taxonomies]
tags=["self-hosted", "protocols"]
+++

## The problem

I've got a security camera, it's kind of old and limited in the amount of
features it has. I recently installed it on my front yard, and I wanted a
motion detection alert. This camera actually supports that feature, but it
has one problem:

The alerts can only be sent via mail.

{{ figure(src="/cam-config.png", position="center" caption_position="left", caption="Camera config page") }}

Now, this wouldn't be an issue if I actually paid attention to mails as soon
as they come, but I don't, I relay them to a RSS feed and I do not read it
until I log on to the internet and start browsing the feed.

## Possible solutions

If recieving mails is not the most convenient thing to do, another way to get
notifications that I know i'll be reading them as soon as they come is a
telegram bot, this is easy since the API is pretty simple and it could be
simplified to sending a single HTTP request.

In order to achieve this, the first thing that it occurred to me was mounting
a full SMTP server and somehow hook a curl command in there when it detects
that an email is coming from the camera.

But then I realized it wasn't necessary, since if I could simply emulate a
SMTP server, then I would receive the data directly and handle it as I wish.

## Emulating a SMTP server

So I opened up the [RFC 5321](https://datatracker.ietf.org/doc/html/rfc5321)
to see what were the standard steps in the communication for receiving an email.
And SMTP lives up to its name since it is extremely simple.

Basically it comes down to this:

- Send a greeting message with 220 code identifying ourselves
- Get a `EHLO` command with the client's identity
- Reply with `250 OK`
- Get a `MAIL` command with the mail's sender
- Reply with `250 OK`
- Get a `RCPT` command with the mail's reciever
- Reply with `250 OK`
- Get a `DATA` command
- Reply with 354 telling the client to start sending the data
- Get the data, ending with a `CRLF.CRLF`
- Reply with `250 OK`
- Get a `QUIT` command
- Reply with `221 Bye`

Since all of this is just text, I can test a mail send directly
by typing in netcat:

{{ image(src="/smtp.gif", position="center") }}

The content of the mails is in MIME, so in the motion detection mails with the
attachments are just text encoded in base64.

## Implementation

I wrote a short nodejs program, you can check the full source code
[here](https://github.com/ariedro/smtp-faker/blob/master/faker.js). It all comes
down to emulating the same communication described above, parsing the
attachments and send them to a telegram bot or any other service you'd want.

{{ figure(src="/telegram-bot.png", position="center", caption_position="left", caption="A screenshot of the telegram bot sending me a photo everytime someone passes on the street, while Tiburcio rests") }}

## Further things

I've discovered that the mail sending feature only supports sending photos
when the motion detection happens. So it would be nice to instead have a
full video of the detection.

According to the
[camera manual](https://www.foscam.es/descarga/Foscam-IPCamera-CGI-User-Guide-AllPlatforms-2015.11.06.pdf),
this would be possible if instead the file got recorded with a FTP server.
So I think it would be more or less the same procedure I did with this
but with the FTP protocol.

Or I may just end up buying a newer camera.
