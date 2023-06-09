import 'package:flutter/material.dart';
import 'package:runsplit/main.dart';

class SaveRun extends StatelessWidget {
  const SaveRun({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text("Save Run"),
        ),
        body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text("Run Saved!"),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(context,
                          MaterialPageRoute(builder: (BuildContext context) {
                        return MyApp();
                      }), (r) {
                        return false;
                      });
                    },
                    child: Text("Home"))
              ]),
        ));
  }
}
