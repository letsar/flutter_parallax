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
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
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
    final ListView listView = new ListView.builder(
      controller: _scrollController,
      itemBuilder: buildItem,
      itemCount: 12,
    );

    return new Scaffold(
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
          listView,
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    if (index != 20) {
      return new Parallax.inside(
        child: new Image.network('https://flutter.io/images/homepage/header-illustration.png'),
        mainAxisExtent: 150.0,
      );
    } else {
      return new Parallax.inside(
        child: new Column(
          children: <Widget>[
            new Container(
              color: Colors.red,
              height: 173.0,
            ),
            new Container(
              color: Colors.green,
              height: 173.0,
              child: new FlatButton(
                  onPressed: () => showDialog(
                        context: context,
                        child: new AlertDialog(
                          title: new Text('hé'),
                          content: new Text('lo'),
                        ),
                      ),
                  child: new Text('Button')),
            ),
            new Container(
              color: Colors.blue,
              height: 173.0,
            ),
            new Container(
              color: Colors.pink,
              height: 173.0,
            ),
          ],
        ),
        mainAxisExtent: 346.0,
      );
    }
  }
}