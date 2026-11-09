# 04 - 数据库设计

> **语言：** 简体中文 · [English](04-database.md)

RcTool 使用 **SQLite** 做本地持久化，由 `sqflite` 系列库驱动，并通过平台适配实现全端可用：

- 移动 / Web：原生 `sqflite` / `sqflite_common_ffi_web`
- 桌面（Windows / macOS / Linux）：`sqflite_common_ffi`（启动时调用 `sqfliteFfiInit()`）

数据库文件名为 `music_database.db`，当前版本 `version: 6`。

## 1. 数据库初始化

入口在 `lib/repository/SqlLiteConn/index.dart`：

- 使用单例 + `Completer` 保证只初始化一次。
- `onConfigure` 中开启外键约束（`PRAGMA foreign_keys = ON;`）。
- `onCreate` 首次建表；`onUpgrade` 用 `IF NOT EXISTS` 为老库补建缺失表，避免跨版本升级丢表。
- 外键为会话级设置，每次打开连接都会重新开启。

## 2. 表结构

### `music` — 音乐主表
| 字段 | 类型 | 约束 |
| --- | --- | --- |
| id | INTEGER | PK, AUTOINCREMENT |
| url | TEXT | NOT NULL（音频地址） |
| imageUrl | TEXT | NOT NULL（封面） |
| songName | TEXT | NOT NULL（歌名） |
| decoration | TEXT | NOT NULL（描述 / 歌手等） |

### `favorite_music` — 收藏歌曲
| 字段 | 类型 | 约束 |
| --- | --- | --- |
| id | INTEGER | PK, AUTOINCREMENT |
| musicId | INTEGER | NOT NULL, FK → music(id) ON DELETE/UPDATE CASCADE |

### `playlist` — 歌单
| 字段 | 类型 | 约束 |
| --- | --- | --- |
| id | INTEGER | PK, AUTOINCREMENT |
| name | TEXT | NOT NULL |
| createdAt | INTEGER | NOT NULL（创建时间戳） |

### `playlist_music` — 歌单-歌曲关联（含排序）
| 字段 | 类型 | 约束 |
| --- | --- | --- |
| id | INTEGER | PK, AUTOINCREMENT |
| playlistId | INTEGER | NOT NULL, FK → playlist(id) |
| musicId | INTEGER | NOT NULL, FK → music(id) |
| sortOrder | INTEGER | NOT NULL（排序） |
| — | — | UNIQUE(playlistId, musicId) |

### `favorite_playlist` — 收藏歌单
| 字段 | 类型 | 约束 |
| --- | --- | --- |
| id | INTEGER | PK, AUTOINCREMENT |
| playlistId | INTEGER | NOT NULL UNIQUE, FK → playlist(id) |

### `recommend_history` — 每日推荐日期记录
| 字段 | 类型 | 约束 |
| --- | --- | --- |
| id | INTEGER | PK, AUTOINCREMENT |
| recommendDate | TEXT | NOT NULL UNIQUE（日期，如 `yyyy-MM-dd`） |
| createdAt | INTEGER | NOT NULL |

### `recommend_history_music` — 每日推荐的歌曲明细
| 字段 | 类型 | 约束 |
| --- | --- | --- |
| id | INTEGER | PK, AUTOINCREMENT |
| historyId | INTEGER | NOT NULL, FK → recommend_history(id) |
| musicId | INTEGER | NOT NULL, FK → music(id) |
| sortOrder | INTEGER | NOT NULL（排序） |
| — | — | UNIQUE(historyId, musicId) |

### `play_history` — 播放历史
| 字段 | 类型 | 约束 |
| --- | --- | --- |
| id | INTEGER | PK, AUTOINCREMENT |
| url | TEXT | NOT NULL（音频地址） |
| imageUrl | TEXT | NOT NULL（封面快照） |
| songName | TEXT | NOT NULL（歌名快照） |
| decoration | TEXT | NOT NULL（描述快照） |
| playedAt | INTEGER | NOT NULL（播放时间戳） |

`play_history.playedAt` 建立 `idx_play_history_played_at(playedAt DESC)` 索引，加速最近播放和按时间统计。该表**不设外键**，故意保留歌曲快照，使歌曲从曲库删除后历史仍可用。最近记录查询按 `url` 分组取 `MAX(playedAt)` 去重；`record()` 在 5 秒重复窗口内只更新同一行。

### `lyric` — 本地歌词
| 字段 | 类型 | 约束 |
| --- | --- | --- |
| url | TEXT | PK（音频地址，与 `music.url` 对应） |
| content | TEXT | NOT NULL（LRC 原文） |
| offsetMs | INTEGER | NOT NULL DEFAULT 0（用户微调的偏移） |
| updatedAt | INTEGER | NOT NULL |

以音频 url 作为主键，同一首歌无论从曲库、歌单还是历史进入播放，都能读到同一份歌词；解码与滚动逻辑在 `lib/utils/lrc_parser.dart` 与 `lib/widget/lyric_view.dart` 中完成，表里只存原文与偏移，方便用户随时改词。

> 其余所有 `FK` 均配置 `ON DELETE CASCADE` / `ON UPDATE CASCADE`，删除歌曲或歌单时会级联清理关联行，保证引用完整性。

## 3. 关系图

```
music ──< favorite_music
  │
  ├──< playlist_music >── playlist ──< favorite_playlist
  │
  └──< recommend_history_music >── recommend_history

play_history（独立快照表，无外键）
```

## 4. 实体类（Dart）

位于 `lib/repository/entity/`：

- `Music`：`id / url / imageUrl / songName / decoration`，重写 `==` 与 `toMap()`。
- `FavoriteMusic`：`id / musicId`。
- `Playlist`：`id / name / createdAt / musicCount`（构造时附带计数）。
- `RecommendHistory`：推荐日期历史。
- `PlayHistory`：播放历史快照，可转换为 `Music`；`PlayedSongSummary` 承载按歌曲聚合的播放次数。
- `musicEntity/` 下为组合视图对象（如每日推荐列表、歌单列表），用于承载联表查询结果。
- `MusicOld`：旧版实体（含 `isFavorite` 字段），已标记 `@Deprecated`，保留作兼容过渡。

## 5. 数据访问层（DAO）

位于 `lib/repository/SqlLiteConn/`：

- `index.dart`：数据库连接与建表（见上）。
- `music_conn.dart`：音乐的增删查。
- `favorite_conn.dart`：收藏歌曲的插入 / 删除 / 查询。
- `playlist_conn.dart`：歌单与"收藏歌单"的查询 / 增删，以及拖动排序写回 `updateSortOrders`。
- `recommend_history_conn.dart`：每日推荐历史与明细的读写。
- `play_history_conn.dart`：播放历史写入、最近记录、聚合统计、单条删除与清空。
- `lyric_conn.dart`：歌词按 `url` 的读取 / 保存 / 偏移更新 / 删除。

> 业务逻辑（如"切换收藏"）封装在 `FavoriteController`，DAO 只负责 SQL 操作，职责清晰。

## 6. 升级注意事项

- 数据库版本从 1 升到 7（v6 新增 `play_history` 及时间索引，v7 新增 `lyric`），每次发布迁移都应在 `onUpgrade` 中补建缺失表（当前实现已用 `IF NOT EXISTS` 兜底）。
- 若需新增字段或修改约束，建议在 `_createTables` 中追加 `ALTER` 语句或在 `onUpgrade` 按 `oldVersion` 分支处理，并同步更新本文档中英两份的表结构。

下一篇：[05 - Live2D 集成](./05-live2d.zh-CN.md)
