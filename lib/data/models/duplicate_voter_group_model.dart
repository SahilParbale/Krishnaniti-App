import 'voter_model.dart';

/// Represents a group of duplicate voter records identified by matching criteria
class DuplicateVoterGroupModel {
  final String normalizedKey;
  final String displayName;
  /// 'name' | 'epic' | 'mobile'
  final String matchType;
  final List<VoterModel> voters;

  const DuplicateVoterGroupModel({
    required this.normalizedKey,
    required this.displayName,
    this.matchType = 'name',
    required this.voters,
  });

  int get recordsCount => voters.length;

  int get extraRecordsCount => voters.length > 1 ? voters.length - 1 : 0;

  DuplicateVoterGroupModel copyWith({
    String? normalizedKey,
    String? displayName,
    String? matchType,
    List<VoterModel>? voters,
  }) {
    return DuplicateVoterGroupModel(
      normalizedKey: normalizedKey ?? this.normalizedKey,
      displayName: displayName ?? this.displayName,
      matchType: matchType ?? this.matchType,
      voters: voters ?? this.voters,
    );
  }
}

