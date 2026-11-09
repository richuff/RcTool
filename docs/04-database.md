# 04 - Database Design

> **Languages:** English · [简体中文](04-database.zh-CN.md)

RcTool uses **SQLite** for local persistence, driven by the `sqflite` family of packages and adapted per platform:

- Mobile / Web: native `sqflite` / `sqflite_common_ffi_web`
- Desktop (Windows / macOS / Linux): `sqflite_common_ffi` (initialized via `sqfliteFfiInit()` at startup)

The database file is `music_database.db`; the current schema version is `version: 6` (migrations have reached version 7 in practice — see §6).

## 1. Initialization

Entry point: `lib/repository/SqlLiteConn/index.dart`:

- A singleton plus a `Completer` guarantees initialization happens only once.
- `onConfigure` enables foreign keys (`PRAGMA foreign_keys = ON;`).
- `onCreate` creates the tables on first run; `onUpgrade` uses `IF NOT EXISTS` to add missing tables to older databases, so upgrading never drops tables.
- Foreign keys are a per-connection setting, so they are re-enabled on every open.

## 2. Tables

### `music` — main music table
| Column | Type | Constraints |
| --- | --- | --- |
| id | INTEGER | PK, AUTOINCREMENT |
| url | TEXT | NOT NULL (audio address) |
| imageUrl | TEXT | NOT NULL (cover) |
| songName | TEXT | NOT NULL (title) |
| decoration | TEXT | NOT NULL (description / artist, etc.) |

### `favorite_music` — favorite songs
| Column | Type | Constraints |
| --- | --- | --- |
| id | INTEGER | PK, AUTOINCREMENT |
| musicId | INTEGER | NOT NULL, FK → music(id) ON DELETE/UPDATE CASCADE |

### `playlist` — playlists
| Column | Type | Constraints |
| --- | --- | --- |
| id | INTEGER | PK, AUTOINCREMENT |
| name | TEXT | NOT NULL |
| createdAt | INTEGER | NOT NULL (creation timestamp) |

### `playlist_music` — playlist-song association (ordered)
| Column | Type | Constraints |
| --- | --- | --- |
| id | INTEGER | PK, AUTOINCREMENT |
| playlistId | INTEGER | NOT NULL, FK → playlist(id) |
| musicId | INTEGER | NOT NULL, FK → music(id) |
| sortOrder | INTEGER | NOT NULL (ordering) |
| — | — | UNIQUE(playlistId, musicId) |

### `favorite_playlist` — favorite playlists
| Column | Type | Constraints |
| --- | --- | --- |
| id | INTEGER | PK, AUTOINCREMENT |
| playlistId | INTEGER | NOT NULL UNIQUE, FK → playlist(id) |

### `recommend_history` — daily recommendation dates
| Column | Type | Constraints |
| --- | --- | --- |
| id | INTEGER | PK, AUTOINCREMENT |
| recommendDate | TEXT | NOT NULL UNIQUE (date, e.g. `yyyy-MM-dd`) |
| createdAt | INTEGER | NOT NULL |

### `recommend_history_music` — daily recommendation detail
| Column | Type | Constraints |
| --- | --- | --- |
| id | INTEGER | PK, AUTOINCREMENT |
| historyId | INTEGER | NOT NULL, FK → recommend_history(id) |
| musicId | INTEGER | NOT NULL, FK → music(id) |
| sortOrder | INTEGER | NOT NULL (ordering) |
| — | — | UNIQUE(historyId, musicId) |

### `play_history` — playback history
| Column | Type | Constraints |
| --- | --- | --- |
| id | INTEGER | PK, AUTOINCREMENT |
| url | TEXT | NOT NULL (audio address) |
| imageUrl | TEXT | NOT NULL (cover snapshot) |
| songName | TEXT | NOT NULL (title snapshot) |
| decoration | TEXT | NOT NULL (description snapshot) |
| playedAt | INTEGER | NOT NULL (playback timestamp) |

`play_history.playedAt` has an `idx_play_history_played_at(playedAt DESC)` index to speed up recently-played queries and time-based statistics. This table **has no foreign keys**: it deliberately keeps song snapshots so history remains usable after a song is deleted from the library. Recent-history queries group by `url` with `MAX(playedAt)` to collapse duplicates, and `record()` updates the existing row when the same song is played again within a 5-second window.

### `lyric` — local lyrics
| Column | Type | Constraints |
| --- | --- | --- |
| url | TEXT | PK (audio address, matching `music.url`) |
| content | TEXT | NOT NULL (raw LRC text) |
| offsetMs | INTEGER | NOT NULL DEFAULT 0 (user-adjusted offset) |
| updatedAt | INTEGER | NOT NULL |

Using the audio URL as the primary key means the same lyrics are found no matter whether the song was opened from the library, a playlist or history. Decoding and scrolling live in `lib/utils/lrc_parser.dart` and `lib/widget/lyric_view.dart`; the table stores only raw text and the offset so users can edit freely.

> All other `FK`s are configured with `ON DELETE CASCADE` / `ON UPDATE CASCADE`, so deleting a song or playlist cascades to associated rows and preserves referential integrity.

## 3. Relationship diagram

```
music ──< favorite_music
  │
  ├──< playlist_music >── playlist ──< favorite_playlist
  │
  └──< recommend_history_music >── recommend_history

play_history (standalone snapshot table, no foreign keys)
```

## 4. Dart entities

Located in `lib/repository/entity/`:

- `Music`: `id / url / imageUrl / songName / decoration`, with `==` and `toMap()` overridden.
- `FavoriteMusic`: `id / musicId`.
- `Playlist`: `id / name / createdAt / musicCount` (count included at construction).
- `RecommendHistory`: recommendation date history.
- `PlayHistory`: history snapshot convertible to `Music`; `PlayedSongSummary` carries per-song play counts.
- `musicEntity/` holds composite view objects (e.g. daily recommendation lists, playlist lists) for join query results.
- `MusicOld`: legacy entity (with `isFavorite`), marked `@Deprecated` and kept for compatibility.

## 5. Data access layer (DAO)

Located in `lib/repository/SqlLiteConn/`:

- `index.dart`: connection and table creation (see above).
- `music_conn.dart`: music CRUD.
- `favorite_conn.dart`: insert / delete / query favorite songs.
- `playlist_conn.dart`: playlist and "favorite playlist" queries / mutations, including `updateSortOrders` for drag sorting.
- `recommend_history_conn.dart`: read/write recommendation history and detail rows.
- `play_history_conn.dart`: write history, recent records, aggregated statistics, single-row deletion and clearing.
- `lyric_conn.dart`: read / save / adjust offset / delete lyrics by `url`.

> Business logic (such as "toggle favorite") is encapsulated in `FavoriteController`; the DAO only performs SQL, keeping responsibilities clear.

## 6. Upgrade notes

- The database version went from 1 to 7 (v6 added `play_history` and its time index, v7 added `lyric`); every released migration should add missing tables in `onUpgrade` (the current implementation uses `IF NOT EXISTS` as a safety net).
- To add columns or change constraints, append `ALTER` statements in `_createTables` or branch on `oldVersion` in `onUpgrade`, and update the schema in this document — in both language versions.

Next: [05 - Live2D Integration](./05-live2d.md)
