+++
title = "Self-hosting my alarm clock radio"
description = "Self-host everything"
date = "2023-12-30"
[taxonomies]
tags=["self-hosted", "audio"]
+++

I don’t like waking up, before going to sleep I tend to schdule many alarms and the next morning I turn off each one of them.

When I was younger I remember having an old radio alarm that would turn on at a scheduled time, I used it as an wake up alarm and I remember being effective.

Maybe because hearing people talking would be less numbing that hearing the same song every day, and it would motivate me more to not turn off the alarm, maybe, I don’t know.

But I wanted to try this.

## Radio

The trivial solution would be to just buy a radio with an alarm, but I discarded this from the start because

1. I don't like the radio static, and even less when I can listen to a live broadcast on the internet very clearly.
2. I didn’t want to spend money

## Mobile

My first attempt was downloading an app that would do this. As I’m already waking up with my cellphone I might as well continue using it.

I tried the [RadioDroid](https://f-droid.org/es/packages/net.programmierecke.radiodroid2/) app, it seems like it has the features I want, it connects to a radio URL and can be used as an alarm clock. But upon using a few nights I’ve noted that the alarm doesn’t always go off. I guess it might be because it’s trying to attempt an active connection and Android goes into idle mode after a while?

Besides I like to turn Wi-Fi off at night, and I realise that it lacks some other nice-to-haves, like adjusting the volume incrementally.

I tried others apps but this was the more promising, I don't want payware, and I surely didn’t feel like programming in Android, so it seemed like I would need another option.

## Raspberry Pi

I have a couple of raspberry pis through the house, one of them I use it as a server for various services that are running all day long. So I thought about using it for this purpose as well.

I moved the raspi to the bedroom and connected to it some old PC speakers I had.

{{ figure(src="/cereza.png", position="center" caption_position="left", caption="Ignore the poor state of the raspberry") }}

Having the interface of a whole computer now I had much more control, as I can program it however I want. All I had to do is play audio through the speakers at a certain time.

### The player

The core of the schedule is to just to reproduce audio through the raspberry’s speakers, so I needed an audio player for it.

My priorities were that I needed a program that would be lightweight, CLI so I could run it directly on the terminal, and that could also play radio files.

I wasn’t going to install anything fancy like VLC or MPV just to play an audio file. So after searching around I found [mpg123](https://www.mpg123.de/), which fullfilled my needs perfectly, it is extremely lightweight, is CLI, doesn’t have an interface and reproduces radio files directly from the URL.

### The radio

As I said on the beginning, I wanted to hear people talking, so I searched for an AM radio. The most popular here regardless of political spectrum is Radio Mitre, which I don't find it entirely despicable, so it works for me.

I scrapped it’s web and found a link for a MP3 file that could be reproduced directly

`http://27323.live.streamtheworld.com/AM790_56.mp3`

And after executing the following on the raspberry pi.

```
$ mpg123 http://27323.live.streamtheworld.com/AM790_56.mp3
High Performance MPEG 1.0/2.0/2.5 Audio Player for Layers 1, 2 and 3
	version 1.26.4; written and copyright by Michael Hipp and others
	free software (LGPL) without any warranty but with best wishes

Directory: http://27323.live.streamtheworld.com/

Terminal control enabled, press 'h' for listing of keys and functions.

Playing MPEG stream 1 of 1: AM790_56.mp3 ...
ICY-NAME:
ICY-URL: https://radiomitre.com.ar/

MPEG 1.0 L III cbr96 44100 j-s

ICY-META: StreamTitle='SEP WHATSAPP MITRE -SMD';
```

It’s working! The live radio is coming out from the speakers.

### Off button

Now that it works, I need a way to turn it off when I’m already awake.

As I was thinking about how I could attach a physical button to the raspi and having to attach wires and other electronical things and such. I thought to myself

_”Wait, I’m a Node.js developer, I don’t need buttons, I can host a bloated express server just to listen for an action, and then send a HTTP request from my phone to trigger it.”_

So I had all the elements to start programming.

## Programming

I started with the core functionality, spawning the radio process.

```js
const { spawn } = require('node:child_process');

const play = spawn('mpg123', ['http://27323.live.streamtheworld.com/AM790_56.mp3']);
```

And then handling the process killing on an express endpoint.

```js
const express = require('express');

const app = express();

app
  .get('/apagar', (_req, res) => {
    try {
      play.kill(9);
      res.send('Apagado\n');
      process.exit(0);
    } catch (error) {
      res.status(500).send(error);
      process.exit(1);
    }
  })
  .listen(3000);
```

On my phone, I created a termux shortcut script that does the HTTP request.

```bash
curl $RASPBERRY_IP:3000/apagar
```

From this I can turn the alarm off with a single tap on my phone.

And the core functionality is done!

#### Cron job

All I had to do now is set the alarm in motion each morning, which I simply added a cron job to execute it at a determined time. In this case at 08:30.

```
30 8 * * * cd radespertador && npm run start
```

### Increasing volume and parametrizing

One last feature I’d like to have is to the volume being increasing slowly, I don’t want to get startled all of the sudden of my sleep.

I had to spawn another child process with a call to control the volume, and in intervals call the controller with smaller increments of the percentage for the volume.

```js
const setVolume = volume => spawn('amixer', ['sset', "'Headphone'", `${volume}%`]);

setVolume(0);
let currentVolume = 0;
setInterval(() => {
  setVolume(currentVolume > 99 ? currentVolume : ++currentVolume);
}, 2000);
```

And of course it would be a bad practice to leave all of this with literals and magic numbers, so I had everything parameterized, and the values can be tweaked on the config file.

You can see the final code [here](https://github.com/ariedro/radespertador).

#### Final result

Here’s a recording of how it works, for demostration purpose the increment for the volume is way more frequent than it is in reality

{{ video(src="/radio.mp4" position="center" caption_position="left", caption="Wait for it") }}

## Conclusion

Did it work? Kind of, I still struggle to wake up. But at least now I can listen to boomers say random things on the morning before turning off the alarm, and I can say that I build that.
