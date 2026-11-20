## 1.1.0

* Fixed: nested maps were returned as `Map<dynamic, dynamic>`; documents are
  now converted to `Map<String, dynamic>` at every depth.
* Fixed: non-map values in a box made `get`, `query` and `existsWhere` throw;
  they are skipped now.
* `query` results include the document id as `id` (a document's own `id`
  field is kept).
* `getAll` returns `null` for a collection without documents.
* Added optional `HiveDatabase(path: ...)` to store the files in a specific
  directory (e.g. in tests, without `path_provider`).

## 1.0.1

* Added dartdoc comments to public API
* Added example documentation

## 1.0.0

* Initial release
* Hive CE (Community Edition) integration for EasyDB
* Fast local key-value storage
* Automatic box management
* Zero native dependencies
* Support for Flutter 3.35.1+
