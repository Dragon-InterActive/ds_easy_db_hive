# DS-EasyDB Hive Example

```dart
import 'packages:ds_easy_db/ds_easy_db.dart';
import 'packages:ds_easy_db_hive/ds_easy_db_hive.dart';

void main() async {
    // Configure with Hive
    db.configure(
        prefs: HiveDatabase(),
        secure: MockDatabase(),
        storage: MockDatabase(),
        stream: MockDatabase(),
    );

    await db.init();

    // Store user preferences
    await db.prefs.set('settings', 'theme', {
        'mode': 'dark',
        'primaryColor': '#ff5722',
    });

    // Read prefences
    final theme = await db.prefs.get('settings', 'theme');
    print('Theme mode: ${theme?['mode']}');

    // Query data
    final darkThemes = await db.prefs.query('settings', where: {'mode': 'dark'});
}
```
