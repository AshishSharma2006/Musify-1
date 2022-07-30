import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/delayed_display.dart';
import 'package:musify/customWidgets/spinner.dart';
import 'package:musify/style/appColors.dart';
import 'package:musify/ui/playlistPage.dart';

class PlaylistsPage extends StatefulWidget {
  @override
  _PlaylistsPageState createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final TextEditingController _searchBar = TextEditingController();
  final ValueNotifier<bool> _fetchingSongs = ValueNotifier(false);
  final FocusNode _inputNode = FocusNode();
  String _searchQuery = '';

  Future<void> search() async {
    _searchQuery = _searchBar.text;
    if (_searchQuery.isEmpty) {
      setState(() {});
      return;
    }

    _fetchingSongs.value = true;
    await fetchSongsList(_searchQuery);
    _fetchingSongs.value = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.playlists,
          style: TextStyle(
            color: accent,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  top: 12, bottom: 20, right: 70, left: 70),
              child: TextField(
                onSubmitted: (String value) {
                  search();
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                controller: _searchBar,
                focusNode: _inputNode,
                style: TextStyle(
                  fontSize: 16,
                  color: accent,
                ),
                cursorColor: Colors.green[50],
                decoration: InputDecoration(
                  fillColor: bgLight,
                  filled: true,
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(100),
                    ),
                    borderSide: BorderSide(
                      color: Color(0xff263238),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(100),
                    ),
                    borderSide: BorderSide(color: accent),
                  ),
                  suffixIcon: ValueListenableBuilder<bool>(
                      valueListenable: _fetchingSongs,
                      builder: (_, value, __) {
                        if (value == true) {
                          return IconButton(
                              icon: const SizedBox(
                                  height: 18, width: 18, child: Spinner()),
                              color: accent,
                              onPressed: () {
                                search();
                                FocusManager.instance.primaryFocus?.unfocus();
                              });
                        } else {
                          return IconButton(
                              icon: Icon(
                                Icons.search,
                                color: accent,
                              ),
                              color: accent,
                              onPressed: () {
                                search();
                                FocusManager.instance.primaryFocus?.unfocus();
                              });
                        }
                      }),
                  border: InputBorder.none,
                  hintText: '${AppLocalizations.of(context)!.search}...',
                  hintStyle: TextStyle(
                    color: accent,
                  ),
                  contentPadding: const EdgeInsets.only(
                    left: 18,
                    right: 20,
                    top: 14,
                    bottom: 14,
                  ),
                ),
              ),
            ),
            if (_searchQuery.isEmpty)
              FutureBuilder(
                future: getPlaylists(),
                builder: (context, data) {
                  return (data as dynamic).data != null
                      ? GridView.builder(
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: false,
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          shrinkWrap: true,
                          physics: const ScrollPhysics(),
                          itemCount: (data as dynamic).data.length as int,
                          padding: const EdgeInsets.only(
                            left: 60,
                            right: 60,
                            top: 16,
                            bottom: 20,
                          ),
                          itemBuilder: (BuildContext context, index) {
                            return Center(
                              child: GetPlaylist(
                                index: index,
                                image: (data as dynamic).data[index]['image'],
                                title: (data as dynamic)
                                    .data[index]['title']
                                    .toString(),
                                id: (data as dynamic).data[index]['ytid'],
                              ),
                            );
                          },
                        )
                      : const Spinner();
                },
              )
            else
              FutureBuilder(
                future: searchPlaylist(_searchQuery),
                builder: (context, data) {
                  return (data as dynamic).data != null
                      ? GridView.builder(
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: false,
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          shrinkWrap: true,
                          physics: const ScrollPhysics(),
                          itemCount: (data as dynamic).data.length as int,
                          padding: const EdgeInsets.only(
                            left: 60,
                            right: 60,
                            top: 16,
                            bottom: 20,
                          ),
                          itemBuilder: (BuildContext context, index) {
                            return Center(
                              child: GetPlaylist(
                                index: index,
                                image: (data as dynamic).data[index]['image'],
                                title: (data as dynamic)
                                    .data[index]['title']
                                    .toString(),
                                id: (data as dynamic).data[index]['ytid'],
                              ),
                            );
                          },
                        )
                      : const Spinner();
                },
              )
          ],
        ),
      ),
    );
  }
}

class GetPlaylist extends StatelessWidget {
  const GetPlaylist({
    Key? key,
    required this.index,
    required this.image,
    required this.title,
    required this.id,
  }) : super(key: key);
  final int index;
  final dynamic image;
  final String title;
  final dynamic id;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return DelayedDisplay(
      delay: const Duration(milliseconds: 200),
      fadingDuration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: () {
          getPlaylistInfoForWidget(id).then(
            (value) => {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistPage(playlist: value),
                ),
              )
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 15),
          child: SizedBox(
            width: size.width * 0.4,
            height: size.height * 0.18,
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 6,
                        color: Color.fromARGB(40, 0, 0, 0),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: image != ''
                        ? CachedNetworkImage(
                            width: size.width * 0.4,
                            height: size.height * 0.18,
                            imageUrl: image.toString(),
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => DecoratedBox(
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
                                    size: 30,
                                    color: accent,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  MdiIcons.musicNoteOutline,
                                  size: 30,
                                  color: accent,
                                ),
                                Text(
                                  title,
                                  style: TextStyle(color: accent),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    width: size.width * 0.4,
                    height: size.height * 0.18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromARGB(30, 255, 255, 255),
                          const Color.fromARGB(30, 233, 233, 233),
                        ],
                        begin: index.isOdd
                            ? Alignment.bottomCenter
                            : Alignment.topCenter,
                        end: index.isOdd
                            ? Alignment.topCenter
                            : Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
