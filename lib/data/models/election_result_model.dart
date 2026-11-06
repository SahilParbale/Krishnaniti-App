/// Election result model matching Nagarsevak-Managment schema and database
class ElectionResultModel {
  final String id;
  final String wardName;
  final String boothNumber;
  final String boothName;
  final int totalVoters;
  final int totalVotesCasted;
  final Map<String, int> candidateVotes;
  final String winner;
  final int margin;
  final DateTime? createdAt;

  const ElectionResultModel({
    required this.id,
    required this.wardName,
    required this.boothNumber,
    required this.boothName,
    this.totalVoters = 0,
    required this.totalVotesCasted,
    required this.candidateVotes,
    required this.winner,
    this.margin = 0,
    this.createdAt,
  });

  /// Get votes won by specific candidate in this booth
  int votesFor(String candidate) => candidateVotes[candidate] ?? 0;

  /// Vote share percentage for a candidate in this booth
  double voteShareFor(String candidate) {
    if (totalVotesCasted <= 0) return 0.0;
    return (votesFor(candidate) / totalVotesCasted) * 100;
  }

  /// Whether candidate won this booth
  bool isWinner(String candidate) => winner.trim() == candidate.trim();

  /// Voter turnout percentage in this booth
  double get turnoutPercentage {
    if (totalVoters <= 0) return 0.0;
    return (totalVotesCasted / totalVoters) * 100;
  }

  ElectionResultModel copyWith({
    String? id,
    String? wardName,
    String? boothNumber,
    String? boothName,
    int? totalVoters,
    int? totalVotesCasted,
    Map<String, int>? candidateVotes,
    String? winner,
    int? margin,
    DateTime? createdAt,
  }) {
    return ElectionResultModel(
      id: id ?? this.id,
      wardName: wardName ?? this.wardName,
      boothNumber: boothNumber ?? this.boothNumber,
      boothName: boothName ?? this.boothName,
      totalVoters: totalVoters ?? this.totalVoters,
      totalVotesCasted: totalVotesCasted ?? this.totalVotesCasted,
      candidateVotes: candidateVotes ?? this.candidateVotes,
      winner: winner ?? this.winner,
      margin: margin ?? this.margin,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ElectionResultModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> candidateMap = {};
    if (json['candidateVotes'] != null && json['candidateVotes'] is Map) {
      (json['candidateVotes'] as Map).forEach((k, v) {
        candidateMap[k.toString()] = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
      });
    } else if (json['candidate_votes'] != null && json['candidate_votes'] is Map) {
      (json['candidate_votes'] as Map).forEach((k, v) {
        candidateMap[k.toString()] = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
      });
    }

    return ElectionResultModel(
      id: json['id']?.toString() ?? '',
      wardName: json['wardName']?.toString() ?? json['ward_name']?.toString() ?? '',
      boothNumber: json['boothNumber']?.toString() ?? json['booth_number']?.toString() ?? '',
      boothName: json['boothName']?.toString() ?? json['booth_name']?.toString() ?? '',
      totalVoters: (json['totalVoters'] ?? json['total_voters'] ?? 0) as int,
      totalVotesCasted: (json['totalVotesCasted'] ?? json['total_votes_casted'] ?? 0) as int,
      candidateVotes: candidateMap,
      winner: json['winner']?.toString() ?? '',
      margin: (json['margin'] ?? 0) as int,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : (json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ward_name': wardName,
      'booth_number': boothNumber,
      'booth_name': boothName,
      'total_voters': totalVoters,
      'total_votes_casted': totalVotesCasted,
      'candidate_votes': candidateVotes,
      'winner': winner,
      'margin': margin,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

