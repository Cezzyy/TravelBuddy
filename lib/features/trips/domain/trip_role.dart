/// Roles for trip collaborators
enum TripRole {
  owner('owner'),
  editor('editor'),
  viewer('viewer');

  const TripRole(this.value);
  final String value;

  static TripRole fromString(String value) {
    return TripRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => TripRole.viewer,
    );
  }

  /// Check if this role can edit the trip
  bool get canEdit => this == TripRole.owner || this == TripRole.editor;

  /// Check if this role can delete the trip
  bool get canDelete => this == TripRole.owner;

  /// Check if this role can invite others
  bool get canInvite => this == TripRole.owner;

  /// Check if this role can manage collaborators
  bool get canManageCollaborators => this == TripRole.owner;

  /// Display name for the role
  String get displayName {
    switch (this) {
      case TripRole.owner:
        return 'Owner';
      case TripRole.editor:
        return 'Editor';
      case TripRole.viewer:
        return 'Viewer';
    }
  }

  /// Description of what this role can do
  String get description {
    switch (this) {
      case TripRole.owner:
        return 'Full access - can edit, delete, and manage collaborators';
      case TripRole.editor:
        return 'Can view and edit trip details';
      case TripRole.viewer:
        return 'Can only view trip details';
    }
  }
}

/// Status for trip invitations
enum InvitationStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  expired('expired');

  const InvitationStatus(this.value);
  final String value;

  static InvitationStatus fromString(String value) {
    return InvitationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => InvitationStatus.pending,
    );
  }

  bool get isPending => this == InvitationStatus.pending;
  bool get isAccepted => this == InvitationStatus.accepted;
  bool get isDeclined => this == InvitationStatus.declined;
  bool get isExpired => this == InvitationStatus.expired;
}
