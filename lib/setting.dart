import 'package:flutter/material.dart';
import 'package:theme_mode_handler/theme_mode_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:websocket/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Setting {
  String title;
  String value;
  Setting({this.title, this.value});
}

class SettingPage extends StatefulWidget {
  SettingPage({Key key}) : super(key: key);
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  List<Setting> listItems;
  @override
  Widget build(BuildContext context) {
    final List<String> styleStrings = [
      AppLocalizations.of(context).theme_system,
      AppLocalizations.of(context).theme_light,
      AppLocalizations.of(context).theme_dark
    ];

    listItems = [
      Setting(
          title: AppLocalizations.of(context).theme,
          value: styleStrings[ThemeModeHandler.of(context).themeMode.index]),
      Setting(
          title: AppLocalizations.of(context).language,
          value:
              Localizations.localeOf(context).toString().split('_')[0] == 'zh'
                  ? '繁體中文'
                  : 'English')
    ];

    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).setting),
        ),
        body: ListView.separated(
            itemCount: listItems.length,
            itemBuilder: (context, index) {
              return settingList(index);
            },
            separatorBuilder: (context, index) {
              return Divider();
            }));
  }

  Widget settingList(index) {
    return InkWell(
        onTap: () {
          switch (index) {
            case 0:
              setTheme();
              break;
            case 1:
              setLanguage();
              break;
          }
        },
        child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listItems[index].title,
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500)),
                Text(listItems[index].value,
                    style:
                        TextStyle(fontSize: 14.0, fontWeight: FontWeight.w300))
              ],
            )));
  }

  void setTheme() async {
    ThemeMode result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text(AppLocalizations.of(context).theme),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, ThemeMode.system);
                },
                child: Text(AppLocalizations.of(context).theme_system,
                    style: TextStyle(fontSize: 16.0)),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, ThemeMode.light);
                },
                child: Text(AppLocalizations.of(context).theme_light,
                    style: TextStyle(fontSize: 16.0)),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, ThemeMode.dark);
                },
                child: Text(AppLocalizations.of(context).theme_dark,
                    style: TextStyle(fontSize: 16.0)),
              ),
            ],
          );
        });
    if (result != null) {
      ThemeModeHandler.of(context)
          .saveThemeMode(ThemeMode.values[result.index]);
    }
  }

  void setLanguage() async {
    String result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text(AppLocalizations.of(context).language),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 'en');
                },
                child: Text('English', style: TextStyle(fontSize: 16.0)),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 'zh');
                },
                child: const Text('繁體中文', style: TextStyle(fontSize: 16.0)),
              ),
            ],
          );
        });

    if (result != null) {
      {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('locale', result);
        MyApp.of(context).setLocal();
      }
    }
  }
}

/*
class SettingOption extends StatelessWidget {
  final Setting setting;

  SettingOption({Key key, this.setting}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {setTheme()},
        child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(setting.title,
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500)),
                Text(setting.value,
                    style:
                        TextStyle(fontSize: 14.0, fontWeight: FontWeight.w100))
              ],
            )));
  }
}
*/
