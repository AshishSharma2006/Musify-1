import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/spinner.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/appColors.dart';

String status = 'hidden';

typedef OnError = void Function(Exception exception);

StreamSubscription? positionSubscription;
StreamSubscription? audioPlayerStateSubscription;

Duration? duration;
Duration? position;

bool get isPlaying => buttonNotifier.value == MPlayerState.playing;

bool get isPaused => buttonNotifier.value == MPlayerState.paused;

enum MPlayerState { stopped, playing, paused, loading }

class AudioApp extends StatefulWidget {
  @override
  AudioAppState createState() => AudioAppState();
}

@override
class AudioAppState extends State<AudioApp> {
  @override
  void initState() {
    super.initState();

    positionSubscription = audioPlayer?.positionStream
        .listen((p) => {if (mounted) setState(() => position = p)});
    audioPlayer?.durationStream.listen(
      (d) => {
        if (mounted) {setState(() => duration = d)}
      },
    );
  }

  final songLikeStatus = ValueNotifier<bool>(
    isSongAlreadyLiked(ytid),
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.nowPlaying,
          style: TextStyle(
            color: accent,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 32,
              color: accent,
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: size.height * 0.012),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: size.width / 1.2,
                height: size.width / 1.2,
                child: CachedNetworkImage(
                  imageUrl: highResImage.value,
                  imageBuilder: (context, imageProvider) => DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  placeholder: (context, url) => const Spinner(),
                  errorWidget: (context, url, error) => Container(
                    width: size.width / 1.2,
                    height: size.width / 1.2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(30, 255, 255, 255),
                          Color.fromARGB(30, 233, 233, 233),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          MdiIcons.musicNoteOutline,
                          size: size.width / 8,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                    top: size.height * 0.04, bottom: size.height * 0.01),
                child: Column(
                  children: <Widget>[
                    Text(
                      title.value.split(' (')[0].split('|')[0].trim(),
                      textScaleFactor: 2.5,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        artist.value,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: accentLight,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                child: _buildPlayer(size, songLikeStatus),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer(
    Size size,
    ValueNotifier<bool> songLikeStatus,
  ) =>
      Container(
        padding: EdgeInsets.only(
          top: size.height * 0.01,
          left: 16,
          right: 16,
          bottom: size.height * 0.03,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (duration != null)
              Slider(
                activeColor: accent,
                inactiveColor: Colors.green[50],
                value: position?.inMilliseconds.toDouble() ?? 0.0,
                onChanged: (double? value) {
                  setState(() {
                    audioPlayer!.seek(
                      Duration(
                        seconds: (value! / 1000).round(),
                      ),
                    );
                    value = value;
                  });
                },
                max: duration!.inMilliseconds.toDouble(),
              ),
            if (position != null) _buildProgressView(),
            Padding(
              padding: EdgeInsets.only(top: size.height * 0.03),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            MdiIcons.shuffle,
                            color:
                                shuffleNotifier.value ? accent : Colors.white,
                          ),
                          iconSize: size.width * 0.056,
                          onPressed: changeShuffleStatus,
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.skip_previous,
                            color: hasPrevious ? Colors.white : Colors.grey,
                            size: size.width * 0.1,
                          ),
                          iconSize: size.width * 0.056,
                          onPressed: playPrevious,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: ValueListenableBuilder<MPlayerState>(
                            valueListenable: buttonNotifier,
                            builder: (_, value, __) {
                              switch (value) {
                                case MPlayerState.loading:
                                  return Container(
                                    margin: const EdgeInsets.all(8),
                                    width: size.width * 0.08,
                                    height: size.width * 0.08,
                                    child: const Spinner(),
                                  );
                                case MPlayerState.paused:
                                  return IconButton(
                                    icon: const Icon(MdiIcons.play),
                                    iconSize: size.width * 0.1,
                                    onPressed: play,
                                    splashColor: Colors.transparent,
                                  );
                                case MPlayerState.playing:
                                  return IconButton(
                                    icon: const Icon(MdiIcons.pause),
                                    iconSize: size.width * 0.1,
                                    onPressed: pause,
                                    splashColor: Colors.transparent,
                                  );
                                case MPlayerState.stopped:
                                  return IconButton(
                                    icon: const Icon(MdiIcons.play),
                                    iconSize: size.width * 0.08,
                                    onPressed: play,
                                    splashColor: Colors.transparent,
                                  );
                              }
                            },
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.skip_next,
                            color: hasNext ? Colors.white : Colors.grey,
                            size: size.width * 0.1,
                          ),
                          iconSize: size.width * 0.08,
                          onPressed: playNext,
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            MdiIcons.repeat,
                            color: repeatNotifier.value ? accent : Colors.white,
                          ),
                          iconSize: size.width * 0.056,
                          onPressed: changeLoopStatus,
                        ),
                        Column(
                          children: [
                            ValueListenableBuilder<bool>(
                              valueListenable: playNextSongAutomatically,
                              builder: (_, value, __) {
                                return IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    MdiIcons.chevronRight,
                                    color: value ? accent : Colors.white,
                                  ),
                                  iconSize: size.width * 0.056,
                                  onPressed: changeAutoPlayNextStatus,
                                );
                              },
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: songLikeStatus,
                              builder: (_, value, __) {
                                if (value == true) {
                                  return IconButton(
                                    color: accent,
                                    icon: const Icon(MdiIcons.star),
                                    iconSize: size.width * 0.056,
                                    onPressed: () => {
                                      removeUserLikedSong(ytid),
                                      songLikeStatus.value = false
                                    },
                                  );
                                } else {
                                  return IconButton(
                                    color: Colors.white,
                                    icon: const Icon(MdiIcons.starOutline),
                                    iconSize: size.width * 0.056,
                                    onPressed: () => {
                                      addUserLikedSong(ytid),
                                      songLikeStatus.value = true
                                    },
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: size.height * 0.047),
                    child: Builder(
                      builder: (context) {
                        return TextButton(
                          onPressed: () {
                            getSongLyrics(
                              artist.value,
                              title.value,
                            );

                            showBottomSheet(
                              context: context,
                              builder: (context) => Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF151515),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    topRight: Radius.circular(18),
                                  ),
                                ),
                                height: size.height / 2.14,
                                child: Column(
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: size.height * 0.012,
                                      ),
                                      child: Row(
                                        children: <Widget>[
                                          IconButton(
                                            icon: Icon(
                                              Icons.arrow_back_ios,
                                              color: accent,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                {Navigator.pop(context)},
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                right: 42,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!
                                                      .lyrics,
                                                  style: TextStyle(
                                                    color: accent,
                                                    fontSize: 30,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ValueListenableBuilder<String>(
                                      valueListenable: lyrics,
                                      builder: (_, value, __) {
                                        if (value != 'null' &&
                                            value != 'not found') {
                                          return Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Center(
                                                child: SingleChildScrollView(
                                                  child: Text(
                                                    value,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: accentLight,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        } else if (value == 'null') {
                                          return const SizedBox(
                                              child: Spinner());
                                        } else {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 120,
                                            ),
                                            child: Center(
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!
                                                    .lyricsNotAvailable,
                                                style: TextStyle(
                                                  color: accentLight,
                                                  fontSize: 25,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Text(
                            AppLocalizations.of(context)!.lyrics,
                            style: TextStyle(color: accent),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      );

  Row _buildProgressView() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            position != null
                ? '$positionText '.replaceFirst('0:0', '0')
                : duration != null
                    ? durationText
                    : '',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          const Spacer(),
          Text(
            position != null
                ? durationText.replaceAll('0:', '')
                : duration != null
                    ? durationText
                    : '',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          )
        ],
      );
}
