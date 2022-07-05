part of logger_flutter;

class LogConsole extends StatefulWidget {
  final bool? dark;
  final bool? showCloseButton;

  const LogConsole({this.dark = false, this.showCloseButton = false});

  @override
  _LogConsoleState createState() => _LogConsoleState();
}

class RenderedEvent {
  final int id;
  final Level level;
  final TextSpan span;
  final String lowerCaseText;

  RenderedEvent(this.id, this.level, this.span, this.lowerCaseText);
}

class _LogConsoleState extends State<LogConsole> {
  OutputCallback? _callback;

  final ListQueue<RenderedEvent> _renderedBuffer = ListQueue();
  List<RenderedEvent> _filteredBuffer = [];

  final _scrollController = ScrollController();
  final _filterController = TextEditingController();

  Level _filterLevel = Level.verbose;
  double _logFontSize = 14;

  var _currentId = 0;
  bool _scrollListenerEnabled = true;
  bool _followBottom = true;
  bool _pause = false;

  @override
  void initState() {
    super.initState();

    _callback = (e) {
      if (_pause) return;

      _renderedBuffer.add(_renderEvent(e));

      if (_renderedBuffer.length > AppSettings().loggerConfig.maxLogMessages) {
        _renderedBuffer.removeFirst();
      }

      _refreshFilter();
    };

    TelloLogger().addOutputListener(_callback!);

    _scrollController.addListener(() {
      if (!_scrollListenerEnabled) return;
      final scrolledToBottom = _scrollController.offset >=
          _scrollController.position.maxScrollExtent;
      setState(() {
        _followBottom = scrolledToBottom;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _renderedBuffer.clear();
    for (final event in TelloLogger().outputEventBuffer) {
      _renderedBuffer.add(_renderEvent(event));
    }
    _refreshFilter();
  }

  Future<void> dumpLogToFile() async {
    _pause = true;
    try {
      if (_renderedBuffer == null || _renderedBuffer.isEmpty) return;

      final String dir = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOWNLOADS);
      final filePath = "$dir/bazz_logger_dump_${DateTime.now().toString()}.txt";
      final File f = File(filePath);

      final StringBuffer sb = StringBuffer();

      _renderedBuffer.forEach((element) {
        sb.writeln("###########${element.level.toString()}###########");
        sb.writeln(element.lowerCaseText);
      });

      f.writeAsString(sb.toString());
      await OpenFile.open(filePath);
    } catch (e, s) {
      TelloLogger().e('dumpLogToFile() error: $e', stackTrace: s);
    } finally {
      _pause = false;
    }
  }

  void _refreshFilter() {
    final newFilteredBuffer = _renderedBuffer.where((it) {
      final logLevelMatches = it.level.index >= _filterLevel.index;
      if (!logLevelMatches) {
        return false;
      } else if (_filterController.text.isNotEmpty) {
        final filterText = _filterController.text.toLowerCase();
        return it.lowerCaseText.contains(filterText);
      } else {
        return true;
      }
    }).toList();
    setState(() {
      _filteredBuffer = newFilteredBuffer;
    });

    if (_followBottom) {
      Future.delayed(Duration.zero, _scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: widget.dark!
          ? ThemeData(
              brightness: Brightness.dark,
              accentColor: Colors.blueGrey,
            )
          : ThemeData(
              brightness: Brightness.light,
              accentColor: Colors.lightBlueAccent,
            ),
      home: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTopBar(),
              Expanded(
                child: _buildLogContent(),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
        floatingActionButton: AnimatedOpacity(
          opacity: _followBottom ? 0 : 1,
          duration: const Duration(milliseconds: 150),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: FloatingActionButton(
              mini: true,
              clipBehavior: Clip.antiAlias,
              onPressed: _scrollToBottom,
              child: Icon(
                Icons.arrow_downward,
                color: widget.dark! ? Colors.white : Colors.lightBlue[900],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogContent() {
    return Container(
      color: widget.dark! ? Colors.black : Colors.grey[150],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1600,
          child: ListView.builder(
            shrinkWrap: true,
            controller: _scrollController,
            itemBuilder: (context, index) {
              final logEntry = _filteredBuffer[index];
              return Text.rich(
                logEntry.span,
                key: Key(logEntry.id.toString()),
                style: TextStyle(fontSize: _logFontSize),
              );
            },
            itemCount: _filteredBuffer.length,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return LogBar(
      dark: widget.dark!,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          const Text(
            "Log Console",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          //const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            icon:
                _pause ? const Icon(Icons.play_arrow) : const Icon(Icons.pause),
            onPressed: () {
              setState(() {
                _pause = !_pause;
              });
            },
          ),
          // const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            icon: const Icon(Icons.archive_outlined),
            onPressed: () {
              dumpLogToFile();
            },
          ),
          //  const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _logFontSize++;
              });
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            icon: const Icon(Icons.remove),
            onPressed: () {
              setState(() {
                _logFontSize--;
              });
            },
          ),
          const Spacer(),
          if (widget.showCloseButton!)
            IconButton(
              iconSize: 20,
              color: Colors.red,
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return LogBar(
      dark: widget.dark!,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 14),
              controller: _filterController,
              onChanged: (s) => _refreshFilter(),
              decoration: const InputDecoration(
                labelText: "Filter log output",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 20),
          DropdownButton(
            value: _filterLevel,
            items: const [
              DropdownMenuItem(
                value: Level.verbose,
                child: Text(
                  "VERBOSE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DropdownMenuItem(
                value: Level.debug,
                child: Text(
                  "DEBUG",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DropdownMenuItem(
                value: Level.info,
                child: Text(
                  "INFO",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DropdownMenuItem(
                value: Level.warning,
                child: Text(
                  "WARNING",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DropdownMenuItem(
                value: Level.error,
                child: Text(
                  "ERROR",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DropdownMenuItem(
                value: Level.wtf,
                child: Text(
                  "WTF",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
            onChanged: (value) {
              _filterLevel = value as Level;
              _refreshFilter();
            },
          )
        ],
      ),
    );
  }

  Future<void> _scrollToBottom() async {
    _scrollListenerEnabled = false;

    setState(() {
      _followBottom = true;
    });

    final scrollPosition = _scrollController.position;
    await _scrollController.animateTo(
      scrollPosition.maxScrollExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );

    _scrollListenerEnabled = true;
  }

  RenderedEvent _renderEvent(OutputEvent event) {
    final parser = AnsiParser(widget.dark!);
    final text = event.lines.join('\n');
    TextStyle style;
    switch (event.level) {
      case Level.verbose:
        style = const TextStyle(color: Colors.white, fontSize: 12);
        break;
      case Level.debug:
        style = const TextStyle(color: Colors.purple, fontSize: 12);
        break;
      case Level.info:
        style = const TextStyle(color: Colors.blue, fontSize: 12);
        break;
      case Level.warning:
        style = const TextStyle(color: Colors.orangeAccent, fontSize: 12);
        break;
      case Level.error:
        style = const TextStyle(color: Colors.red, fontSize: 12);
        break;
      case Level.wtf:
        style = const TextStyle(color: Colors.white, fontSize: 12);
        break;
      case Level.nothing:
        style = const TextStyle(color: Colors.white, fontSize: 12);
        break;
    }
    parser.parse(text);
    return RenderedEvent(
      _currentId++,
      event.level,
      TextSpan(children: parser.spans, style: style),
      text.toLowerCase(),
    );
  }

  @override
  void dispose() {
    TelloLogger().removeOutputListener(_callback!);
    super.dispose();
  }
}

class LogBar extends StatelessWidget {
  final bool? dark;
  final Widget? child;

  LogBar({this.dark, this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            if (dark!)
              BoxShadow(
                color: Colors.grey[400]!,
                blurRadius: 3,
              ),
          ],
        ),
        child: Material(
          color: dark! ? Colors.blueGrey[900] : Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
            child: child,
          ),
        ),
      ),
    );
  }
}
