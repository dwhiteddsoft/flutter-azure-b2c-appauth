import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Azure B2C Flutter Integration Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Azure B2C Flutter Integration'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterAppAuth appAuth = FlutterAppAuth();
  String _clientId = '90185a76-af9b-4ff0-9fdc-55c888583e2d';
  String _redirectUrl = 'com.davetest.wow://oauth/redirect';
  String _discoveryURL = 'https://detroitdaveb2c.b2clogin.com/detroitdaveb2c.onmicrosoft.com/v2.0/.well-known/openid-configuration?p=B2C_1_susi';
  String _authorizeUrl = 'https://detroitdaveb2c.b2clogin.com/te/detroitdaveb2c.onmicrosoft.com/b2c_1_susi/oauth2/v2.0/authorize';
  String _tokenUrl = 'https://detroitdaveb2c.b2clogin.com/te/detroitdaveb2c.onmicrosoft.com/b2c_1_susi/oauth2/v2.0/token';
  String _idToken;
  String _refreshToken;
  String _accessToken;
  String _accessTokenExpiration;
  String _firstName = "";
  String _lastName = "";
  String _displayName = "";
  String _email = "";
  Map<String, dynamic> _jwt;
  List<String> _scopes = ['openid'];

  Future<void> _logIn() async {
    try {
      final AuthorizationTokenResponse result = await appAuth
          .authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          serviceConfiguration: AuthorizationServiceConfiguration(_authorizeUrl, _tokenUrl),
          scopes: _scopes,
        ),
      );
      if (result != null) {
        _processAuthTokenResponse(result);
      }
    } catch (e) {
      print(e);
    }
  }

  void _processAuthTokenResponse(AuthorizationTokenResponse response) {
    setState(() {
      _accessToken = response.accessToken;
      _refreshToken = response.refreshToken;
      _accessTokenExpiration = response.accessTokenExpirationDateTime?.toIso8601String();
      _idToken = response.idToken;
      //get individual claims from jwt token
      _jwt = parseJwt(response.idToken);
      _firstName = _jwt['given_name'].toString();
      _lastName = _jwt['family_name'].toString();
      _displayName = _jwt['name'].toString();
      _email = _jwt['emails'][0];
    });
  }

  Map<String, dynamic> parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('invalid token');
    }

    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('invalid payload');
    }

    return payloadMap;
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');

    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!"');
    }

    return utf8.decode(base64Url.decode(output));
  }

  Future<void> _logOut() async {
    try {
      //for some reason the API works differently on iOS and Android
      Map<String,String> additionalParameters;
      if (Platform.isAndroid) {
        //works on Android but is missing p parameter when redirected back to authorize on iOS
        additionalParameters = {
          "id_token_hint": _idToken,
          "post_logout_redirect_uri": _redirectUrl
        };
      } else if (Platform.isIOS) {
        //missing p parameter when redirected back to authorize on iOS so the below difference
        additionalParameters = {
          "id_token_hint": _idToken,
          "post_logout_redirect_uri": _redirectUrl,
          'p':'B2C_1_susi'
        };
      }
      await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          promptValues: ['login'],
          discoveryUrl: _discoveryURL,
          additionalParameters: additionalParameters,
          scopes: _scopes,
        ),
      );
    } catch (e) {
      print(e);
    }
    setState(() {
      _jwt = null;
    });
  }
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: (_jwt == null) ?  <Widget>[ Text('Please press + sign to log in',)] :
          <Widget>[
            Text(
              'Display Name: $_displayName',
            ),
            Text(' '),
            Text(
              'Name: $_firstName $_lastName',
            ),
            Text(' '),
            Text(
              'Email: $_email',
            ),
            Text(' '),
            RaisedButton(
              onPressed: _logOut,
              elevation: 5,
              child: Text('Logout'),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _logIn,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
