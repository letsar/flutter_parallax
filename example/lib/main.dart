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
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new ListView.builder(
        itemBuilder: buildItem,
        itemCount: 12,
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    if (index != 6) {
      return new Parallax(
        child: new Image.network('https://flutter.io/images/homepage/header-illustration.png'),
        mainAxisExtent: 150.0,
      );
    } else {
      return new Parallax(
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
        followScrollDirection: true,
      );
    }

//    return new Align(
//        alignment: Alignment.topCenter,
//        heightFactor: 0.5,
//        child: new Image.network('https://flutter.io/images/homepage/header-illustration.png'),
//      );

//    return new ClipRect(
//      child: new Align(
//        alignment: Alignment.topCenter,
//        heightFactor: 0.5,
//        child: new Image.network('https://flutter.io/images/homepage/header-illustration.png'),
//      ),
//    );

//    return new Padding(
//      padding: const EdgeInsets.only(bottom: 8.0),
//      child: new Parallax(
//        child: new Image.network('https://flutter.io/images/homepage/header-illustration.png'),
//        mainAxisExtent: 150.0,
//      ),
//    );
  }
}

class _Clipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return new Rect.fromLTRB(0.0, 100.0, size.width, size.height - 100.0);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}
