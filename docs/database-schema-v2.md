# Database Schema v2 - Guides & Invitations

## Overview
This document describes the database schema changes from v1 to v2, adding support for travel guides and trip invitations.

## Migration Summary
- **Schema Version**: 1 → 2
- **New Tables**: 6
- **Migration Type**: Additive (no breaking changes)

## New Tables

### 1. Guides
Blog-like travel guides created by users to share experiences and itineraries.

**Key Fields:**
- `id` - Firestore document ID
- `authorId` - Reference to Users table
- `title`, `description`, `destination` - Guide content
- `latitude`, `longitude` - Location coordinates
- `coverImageUrl` - Cover image from Firebase Storage
- `content` - Rich content (markdown/JSON)
- `tags` - JSON-encoded array of tags
- `viewCount`, `likeCount` - Engagement metrics
- `isPublished` - Publication status
- `createdAt`, `updatedAt`, `publishedAt` - Timestamps

**Use Cases:**
- Users create guides about destinations they've visited
- Share detailed itineraries and tips
- Inspire other travelers
- Build a community knowledge base

### 2. GuideItineraryItems
Reusable itinerary templates within guides.

**Key Fields:**
- `id` - Firestore document ID
- `guideId` - Parent guide reference
- `title`, `description` - Activity details
- `locationName`, `latitude`, `longitude` - Location info
- `dayNumber` - Relative day (Day 1, Day 2, etc.)
- `suggestedStartTime`, `suggestedEndTime` - Time suggestions
- `category` - transport, food, activity, accommodation, other
- `sortOrder` - Ordering within a day
- `estimatedCost`, `costCurrency` - Cost information

**Use Cases:**
- Provide day-by-day itinerary templates
- Users can import these into their own trips
- Include cost estimates for budgeting
- Suggest optimal timing for activities

### 3. GuideLikes
Tracks user likes on guides.

**Key Fields:**
- `id` - Auto-increment primary key
- `guideId` - Guide reference
- `userId` - User who liked
- `likedAt` - Timestamp

**Constraints:**
- Unique constraint on (guideId, userId)

**Use Cases:**
- Users can like helpful guides
- Track popular guides
- Personalized recommendations

### 4. GuideComments
User comments and feedback on guides.

**Key Fields:**
- `id` - Firestore document ID
- `guideId` - Parent guide reference
- `userId` - Comment author
- `content` - Comment text
- `createdAt`, `updatedAt` - Timestamps
- `isDeleted` - Soft delete flag

**Use Cases:**
- Users ask questions about guides
- Share additional tips
- Provide feedback to authors
- Build community engagement

### 5. TripGuideReferences
Links trips to guides when imported.

**Key Fields:**
- `id` - Auto-increment primary key
- `tripId` - Trip reference
- `guideId` - Guide reference
- `importedAt` - Timestamp

**Constraints:**
- Unique constraint on (tripId, guideId)

**Use Cases:**
- Track which guides inspired a trip
- Attribution for guide authors
- Analytics on guide usage
- Allow users to reference original guide

### 6. TripInvitations
Invitation system for collaborative trip planning.

**Key Fields:**
- `id` - Firestore document ID
- `tripId` - Parent trip reference
- `invitedByUserId` - User who sent invitation
- `invitedEmail` - Email address of invitee
- `invitedUserId` - User ID (once they accept)
- `status` - pending, accepted, declined, expired
- `role` - owner, editor, viewer
- `createdAt`, `expiresAt`, `respondedAt` - Timestamps

**Use Cases:**
- Invite friends to collaborate on trip planning
- Track invitation status
- Manage access levels (owner/editor/viewer)
- Handle invitation expiration

## Feature Workflows

### Collaborative Trip Planning
1. User creates a trip (already supported)
2. User sends invitation via email → `TripInvitations` (new)
3. Invitee accepts → `TripCollaborators` (already supported)
4. Multiple users edit trip → `ItineraryItems.createdBy` tracks changes

### Guide Creation & Discovery
1. User creates guide → `Guides`
2. Adds day-by-day itinerary → `GuideItineraryItems`
3. Publishes guide → `Guides.isPublished = true`
4. Other users discover, like, comment → `GuideLikes`, `GuideComments`
5. User imports guide into trip → `TripGuideReferences`
6. Guide items copied to trip → `ItineraryItems`

## Migration Code

```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Add new tables for guides system
        await m.createTable(guides);
        await m.createTable(guideItineraryItems);
        await m.createTable(guideLikes);
        await m.createTable(guideComments);
        await m.createTable(tripGuideReferences);
        
        // Add trip invitations table
        await m.createTable(tripInvitations);
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
  └─ N:M → Trips (via TripGuideReferences)
```

## Sync Strategy

All new tables include:
- `lastSyncedAt` - Track last Firestore sync
- `isDeleted` (where applicable) - Soft delete for conflict resolution
- Firestore document IDs as primary keys (except join tables)

This maintains consistency with the existing offline-first sync architecture.

## Next Steps

1. ✅ Create table definitions
2. ✅ Update app_db.dart with new tables
3. ✅ Add migration from v1 to v2
4. ✅ Run code generation
5. ⏳ Create repository classes for guides
6. ⏳ Create repository classes for invitations
7. ⏳ Implement Firestore sync logic
8. ⏳ Build UI for guides feature
9. ⏳ Build UI for invitation system

## Testing Migration

To test the migration:
1. Install app with v1 schema
2. Create some trips and users
3. Update to v2 schema
4. Verify all existing data is preserved
5. Verify new tables are created
6. Test creating guides and invitations
