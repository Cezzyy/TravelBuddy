# Database Schema v3 - Draft Versioning for Guides

## Overview
This document describes the database schema changes from v2 to v3, adding support for draft versioning of published guides.

## Migration Summary
- **Schema Version**: 2 → 3
- **Modified Tables**: 1 (Guides)
- **New Fields**: 2
- **Migration Type**: Additive (no breaking changes)

## Modified Tables

### Guides
Added draft versioning support to allow safe editing of published guides.

**New Fields:**
- `publishedVersionId` - References the published guide (if this is a draft)
- `draftVersionId` - References the draft guide (if this is published with pending changes)

**Use Cases:**
- Edit published guides without affecting live content
- Preview changes before applying them
- Discard unwanted changes
- Maintain published guide stability

## Feature Workflows

### Editing a Published Guide
1. User clicks "Edit" on published guide → System creates draft version
2. User makes changes → Draft updated, published unchanged
3. User clicks "Apply Changes" → Draft content copied to published, draft deleted
4. Alternative: User clicks "Discard" → Draft deleted, published unchanged

### Publishing from Drafts Tab
1. If draft is linked to published guide → Apply changes (no duplicate)
2. If draft is new → Publish as new guide

## Migration Code

```dart
@override
int get schemaVersion => 3;

@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Migration from v1 to v2: Add guides and invitation tables
      if (from < 2) {
        await m.createTable(guides);
        await m.createTable(guideItineraryItems);
        await m.createTable(guideLikes);
        await m.createTable(guideComments);
        await m.createTable(tripGuideReferences);
        await m.createTable(tripInvitations);
      }
      
      // Migration from v2 to v3: Add draft versioning to guides
      if (from < 3) {
        await m.addColumn(guides, guides.publishedVersionId);
        await m.addColumn(guides, guides.draftVersionId);
      }
    },
  );
}
```

## Database Relationships

```
Users
  ├─ 1:N → Trips (ownerId)
  ├─ 1:N → Guides (authorId)
  ├─ N:M → Trips (via TripCollaborators)
  ├─ N:M → Guides (via GuideLikes)
  └─ 1:N → GuideComments (userId)

Trips
  ├─ 1:N → ItineraryItems (tripId)
  ├─ N:M → Users (via TripCollaborators)
  ├─ 1:N → TripInvitations (tripId)
  └─ N:M → Guides (via TripGuideReferences)

Guides
  ├─ 1:N → GuideItineraryItems (guideId)
  ├─ N:M → Users (via GuideLikes)
  ├─ 1:N → GuideComments (guideId)
  ├─ N:M → Trips (via TripGuideReferences)
  ├─ 0:1 → Guides (publishedVersionId) [NEW]
  └─ 0:1 → Guides (draftVersionId) [NEW]
```

## Sync Strategy

Draft versioning maintains the existing offline-first sync architecture:
- Draft and published guides are separate documents
- Each syncs independently to Firestore
- No sync conflicts between draft and published versions

## Next Steps

1. ✅ Add new fields to Guides table
2. ✅ Update app_db.dart with migration
3. ✅ Run code generation
4. ✅ Create repository methods for draft versioning
5. ✅ Update UI for draft editing workflow
6. ⏳ Implement Firestore sync for draft versioning
7. ⏳ Comprehensive testing

## Testing Migration

To test the migration:
1. Install app with v2 schema
2. Create and publish some guides
3. Update to v3 schema
4. Verify all existing guides are preserved
5. Verify new fields are added (null by default)
6. Test editing published guides (creates drafts)
7. Test applying and discarding drafts

