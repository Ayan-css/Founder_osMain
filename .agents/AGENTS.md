# Project Rules

## Documentation
- **CHANGELOG RULE**: After completing any major or mid-sized updates (new features, major UI redesigns, significant bug fixes), you MUST explicitly update `CHANGELOG.md` with the new changes before finishing the task.

## Architecture Guidelines
- **Memory File**: Always consult and update `memory.md` in the root folder when modifying the project architecture, dependencies, or database schema. It serves as the primary handoff document across AI models.
- **Database Migrations**: When adding or altering Isar schema collections, run `dart run build_runner build` and ensure `SyncMapper` is updated to serialize/deserialize correctly. Supabase SQL migrations must be run via the Supabase SQL Editor.
