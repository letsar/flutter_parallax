import 'package:flutter/material.dart';
import 'package:flutter_parallax/flutter_parallax.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Parallax demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = new ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text(widget.title)),
      body: new Stack(
        children: <Widget>[
          new Parallax.outside(
            controller: _scrollController,
            child: new Column(
              children: <Widget>[
                new Container(
                  color: Colors.red,
                  height: 200.0,
                ),
                new Container(
                  color: Colors.pink,
                  height: 200.0,
                ),
                new Container(
                  color: Colors.lightGreen,
                  height: 200.0,
                ),
                new Container(
                  color: Colors.orange,
                  height: 200.0,
                ),
                new Container(
                  color: Colors.teal,
                  height: 200.0,
                ),
                new Container(
                  color: Colors.purple,
                  height: 200.0,
                ),
                new Container(
                  color: Colors.grey,
                  height: 200.0,
                ),
                new Container(
                  color: Colors.lime,
                  height: 200.0,
                ),
                new Container(
                  color: Colors.indigo,
                  height: 200.0,
                ),
                new Container(
                  color: Colors.yellow,
                  height: 200.0,
                ),
                new Container(
                  color: Colors.green,
                  height: 200.0,
                ),
                new Container(
                  color: Colors.blue,
                  height: 200.0,
                ),
              ],
            ),
          ),
          new ListView.builder(
            controller: _scrollController,
            itemBuilder: buildItem,
            itemCount: 20,
          ),
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    var mode = index % 4;
    switch (mode) {
      case 0:
        return new Parallax.inside(
          child: new Image.network('https://flutter.io/images/homepage/header-illustration.png'),
          mainAxisExtent: 150.0,
        );
      case 1:
        return new Parallax.inside(
          child: new Image.network('http://t.wallpaperweb.org/wallpaper/nature/3840x1024/9XMedia1280TripleHorizontalMountainsclouds.jpg'),
          mainAxisExtent: 150.0,
          direction: AxisDirection.right,
        );
      case 2:
        return new Parallax.inside(
          child: new Image.network('https://flutter.io/images/homepage/header-illustration.png'),
          mainAxisExtent: 150.0,
          flipDirection: true,
        );
      default:
        return new Parallax.inside(
          child: new Image.network('http://t.wallpaperweb.org/wallpaper/nature/3840x1024/9XMedia1280TripleHorizontalMountainsclouds.jpg'),
          mainAxisExtent: 150.0,
          direction: AxisDirection.left,
        );
    }
  }
}
