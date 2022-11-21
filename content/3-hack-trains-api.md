+++
title = "Hacking my local trains schedules API"
description = "Fuck you SOFSE"
date = "2022-11-21"
[taxonomies]
tags=["hacking", "self-hosted"]
+++

Here in Buenos Aires we rely mainly on 3 modes of public transportation:
buses, subways and trains. Buses are often the primary choice because they're
everywhere, but in terms of efficiency and speed subways and trains are
by far the best choice, if you can take advantage of the proximity of
a railroad branch line.

Say you want to take a train somewhere, and you want to make sure
you are on time, you can download the android app "
[Trenes Argentinos](https://play.google.com/store/apps/details?id=com.mininterior.trenesenvivo)
" from the Google Play store, developed by the private company SOFSE,
and check the time schedules there.

Upon installing it you'll see right away that the app starts requiring
permissions, permissions that a simple app for checking the trains schedule
shouldn't require, like GPS location and file storage access.

If you deny these requests it would still prompt you every time you select a station.

{{ figure(src="/trenes-app.jpg", position="center" caption_position="left",
caption="Shady dialogs in the app, the right one appears everytime you select
a station") }}

If you're like most people you probably wouldn't care much about these things
because the app in the end actually fulfills its purpose.

~~You don't mind having your privacy being invaded any more than it already is
every day, or having to navigate to a horrible UX by closing a dozen
of pop-ups like it's the early internet days.~~

Thankfully I'm not, so I began searching for the API behind it so
I could just write a bash script and `curl` it away.

## Research

Being a public transportation service, I expected the API to also be public.

For example, in the internal jurisdiction of the city of Buenos Aires they implemented an
[unified public transport API specification](https://www.buenosaires.gob.ar/desarrollourbano/transporte/apitransporte)
that provides information on buses, subways and even the status of the city's
traffic lights.

However, this does not seem to be the case for trains, after googling
a little bit I didn't find anything, and everything pointed to this
being a private service. Even in violation of the
[national law 27,275](http://servicios.infoleg.gob.ar/infolegInternet/anexos/265000-269999/265949/texact.htm)
that guarantees the right of access to public information.

This leaves me with only one option.

## Hacking the App

I downloaded the app's raw apk to my pc with a generic apk downloader,
and after researching a little bit about how to decompile an android app file,
I ended up using a program called `jadx`.

```
>: jadx com.mininterior.trenesenvivo.apk
INFO  - loading ...
INFO  - processing ...
ERROR - finished with errors, count: 8
```

I didn't care much about those errors because I wasn't going to recompile
the app anyway, I just wanted to look for the internal service it used.

So I started browsing the decompiled codebase and found the URL right away.

```xml
<string name="trenesApiUrl">https://apiarribos.sofse.gob.ar/</string>
```

And the endpoint's paths and params.

```java
@GET("v1/estaciones/buscar")
Call<PaginationContainer<Estacion>> buscarEstaciones(@Query("nombre") String str, @Query("lineas") RetrofitArray<Integer> retrofitArray, @Query("ramales") RetrofitArray<Integer> retrofitArray2, @Query("exclude") RetrofitArray<Integer> retrofitArray3, @Query("limit") Integer num, @Query("orderBy") String str2);

@GET("v1/alertas")
Call<List<AlertaResponse>> getAlertas();

...
```

Before I started testing, and thinking I had everything I needed,
to my suprise I also found a little file called `TokenAuthenticator.java`.

Thinking to myself: "Well, they probably added an authentication token
that is freely obtainable with an endpoint, in order to avoid getting
spammed".

But after browsing the file a little bit:

```java
String userApi = getUserApi();
String codificar = encode(userApi);
...
tokenRequest.setUsername(userApi);
tokenRequest.setPassword(codificar);
```

Why would there be a user and a password, if the app
doesn't require a login or anything like that?

And then I found it:

```java
public static String getUserApi() {
  Date date = new Date();
  return Base64.encodeToString(
    (new SimpleDateFormat("yyyyMMdd").format(date) + "sofse").getBytes(),
    2
  );
}

public static String encode(String str) {
    String stringBuffer = new StringBuffer(
    Base64.encodeToString(
      new StringBuffer(
        Base64.encodeToString(str.getBytes(), 2)
          .replace("a", "#t")
          .replace("e", "#x")
          .replace("i", "#f")
          .replace("o", "#l")
          .replace("u", "#7")
          .replace("=", "#g")
      )
        .reverse()
        .toString()
        .getBytes(),
      2
    )
      .replace("a", "#j")
      .replace("e", "#p")
      .replace("i", "#w")
      .replace("o", "#8")
      .replace("u", "#0")
      .replace("=", "#v")
  )
    .reverse()
    .toString();
}
```

Up until this point I thought that maybe they didn't publish their API because
they were lazy, or because they did not see the need to do so.

But no, not only did they fill their app with shady storage and GPS accesses,
not only did they not publish their API specification evading a national law,
but they also obscured the access to it with some encoding, being 100% assholes.

I felt that I had a moral obligation to not only circumvent this, but also
to publish it so anyone can use it freely.

## Remaking it

I wanted to make a public proxy that would bypass all of this, so I made a simple
nodejs program using `express`

The core of the program would just be something like:

```js
const app = express();
app.get('*', redirection)
app.listen(PORT);
```

And in the `redirection` middleware it would be located the generation
and maintenance of such obscured tokens, of which they should be made in the
same way as in the app.

After a bit of trial and error, after having to root my phone in order to
be able to sniff HTTP requests, because I couldn't get to replicate the same
exact encoding, I finally did it, I was able to bypass the token generation
and make direct use of the API.

You can find the full source code [here](https://github.com/ariedro/api-trenes).

## Publication and usage

I set up a public instance of this proxy service on the same server where
this blog is hosted, by the path `/api-trenes`.

With this service anyone can make request to it, and it would take care
of the internal authentication, without the user having to worry about it.

For example you can get the lines information:

```sh
curl 'https://ariedro.dev/api-trenes/lineas'
```

Or the schedules to go from "Drago" to "Miguelete"
(Previously you would need to find the corresponding ids for such stations):

```sh
curl 'https://ariedro.dev/api-trenes/estaciones/236/horarios?hasta=271'
```

You can find more info and the full endpoints specification
[in the repository](https://github.com/ariedro/api-trenes).

Having all this live, I can finally make scripts on for example Termux
and be able to get the schedules information instantly, without having to
go through all the spyware in the app.

## Further things

I am not worried if SOFSE finds this and wants to make a legal fuss about it,
after all, they are the ones who are legally wrong in this issue, being a
state-subsidized company, they should keep its information public.

And in the end, this was more an exercise in discovery and reverse engineering
rather than actively trying to affect anyone.

I hope you liked this blogpost, and I look forward to keep posting other
interesting stuff like this more often.