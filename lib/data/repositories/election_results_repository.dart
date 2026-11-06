import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/election_result_model.dart';

class ElectionResultsRepository {
  final List<ElectionResultModel> _results = [
    // --- Ward 12: Kasba - Vishrambaug Wada (अमित चौगुले) ---
    ElectionResultModel(
      id: 'res-12-01',
      wardName: 'प्रभाग १२ - कसबा-विश्रामबाग वाडा',
      boothNumber: '१२/१',
      boothName: 'म.न.पा. शाळा क्र. ६, शनिवार पेठ',
      totalVoters: 980,
      totalVotesCasted: 684,
      candidateVotes: {
        'अमित चौगुले (आपले उमेदवार)': 385,
        'सुरेश कदम': 175,
        'राजेश जोशी': 82,
        'दिलीप कांबळे': 28,
        'NOTA': 14,
      },
      winner: 'अमित चौगुले (आपले उमेदवार)',
      margin: 210,
      createdAt: DateTime(2026, 1, 16),
    ),
    ElectionResultModel(
      id: 'res-12-02',
      wardName: 'प्रभाग १२ - कसबा-विश्रामबाग वाडा',
      boothNumber: '१२/२',
      boothName: 'न्यू इंग्लिश स्कूल, रमणबाग (हॉल क्र. १)',
      totalVoters: 1050,
      totalVotesCasted: 742,
      candidateVotes: {
        'अमित चौगुले (आपले उमेदवार)': 462,
        'सुरेश कदम': 117,
        'राजेश जोशी': 115,
        'दिलीप कांबळे': 32,
        'NOTA': 16,
      },
      winner: 'अमित चौगुले (आपले उमेदवार)',
      margin: 345,
      createdAt: DateTime(2026, 1, 16),
    ),
    ElectionResultModel(
      id: 'res-12-03',
      wardName: 'प्रभाग १२ - कसबा-विश्रामबाग वाडा',
      boothNumber: '१२/३',
      boothName: 'न्यू इंग्लिश स्कूल, रमणबाग (हॉल क्र. २)',
      totalVoters: 890,
      totalVotesCasted: 620,
      candidateVotes: {
        'अमित चौगुले (आपले उमेदवार)': 345,
        'सुरेश कदम': 165,
        'राजेश जोशी': 78,
        'दिलीप कांबळे': 21,
        'NOTA': 11,
      },
      winner: 'अमित चौगुले (आपले उमेदवार)',
      margin: 180,
      createdAt: DateTime(2026, 1, 16),
    ),
    ElectionResultModel(
      id: 'res-12-04',
      wardName: 'प्रभाग १२ - कसबा-विश्रामबाग वाडा',
      boothNumber: '१२/४',
      boothName: 'अहिल्यादेवी हायस्कूल, कसबा पेठ',
      totalVoters: 1120,
      totalVotesCasted: 815,
      candidateVotes: {
        'अमित चौगुले (आपले उमेदवार)': 475,
        'सुरेश कदम': 185,
        'राजेश जोशी': 98,
        'दिलीप कांबळे': 39,
        'NOTA': 18,
      },
      winner: 'अमित चौगुले (आपले उमेदवार)',
      margin: 290,
      createdAt: DateTime(2026, 1, 16),
    ),
    ElectionResultModel(
      id: 'res-12-05',
      wardName: 'प्रभाग १२ - कसबा-विश्रामबाग वाडा',
      boothNumber: '१२/५',
      boothName: 'जिजामाता प्राथमिक शाळा, कसबा पेठ',
      totalVoters: 840,
      totalVotesCasted: 560,
      candidateVotes: {
        'अमित चौगुले (आपले उमेदवार)': 228,
        'सुरेश कदम': 270,
        'राजेश जोशी': 45,
        'दिलीप कांबळे': 12,
        'NOTA': 5,
      },
      winner: 'सुरेश कदम',
      margin: 42,
      createdAt: DateTime(2026, 1, 16),
    ),
    ElectionResultModel(
      id: 'res-12-06',
      wardName: 'प्रभाग १२ - कसबा-विश्रामबाग वाडा',
      boothNumber: '१२/६',
      boothName: 'म.न.पा. विश्रामबाग वाडा परिसर',
      totalVoters: 1250,
      totalVotesCasted: 890,
      candidateVotes: {
        'अमित चौगुले (आपले उमेदवार)': 565,
        'सुरेश कदम': 153,
        'राजेश जोशी': 120,
        'दिलीप कांबळे': 38,
        'NOTA': 14,
      },
      winner: 'अमित चौगुले (आपले उमेदवार)',
      margin: 412,
      createdAt: DateTime(2026, 1, 16),
    ),
    ElectionResultModel(
      id: 'res-12-07',
      wardName: 'प्रभाग १२ - कसबा-विश्रामबाग वाडा',
      boothNumber: '१२/७',
      boothName: 'गोपाळ गायन समाज, शनिवार पेठ',
      totalVoters: 780,
      totalVotesCasted: 540,
      candidateVotes: {
        'अमित चौगुले (आपले उमेदवार)': 312,
        'सुरेश कदम': 147,
        'राजेश जोशी': 58,
        'दिलीप कांबळे': 15,
        'NOTA': 8,
      },
      winner: 'अमित चौगुले (आपले उमेदवार)',
      margin: 165,
      createdAt: DateTime(2026, 1, 16),
    ),
    ElectionResultModel(
      id: 'res-12-08',
      wardName: 'प्रभाग १२ - कसबा-विश्रामबाग वाडा',
      boothNumber: '१२/८',
      boothName: 'भावे हायस्कूल, नारायण पेठ (खोली १)',
      totalVoters: 1100,
      totalVotesCasted: 795,
      candidateVotes: {
        'अमित चौगुले (आपले उमेदवार)': 510,
        'सुरेश कदम': 130,
        'राजेश जोशी': 105,
        'दिलीप कांबळे': 35,
        'NOTA': 15,
      },
      winner: 'अमित चौगुले (आपले उमेदवार)',
      margin: 380,
      createdAt: DateTime(2026, 1, 16),
    ),
    ElectionResultModel(
      id: 'res-12-09',
      wardName: 'प्रभाग १२ - कसबा-विश्रामबाग वाडा',
      boothNumber: '१२/९',
      boothName: 'भावे हायस्कूल, नारायण पेठ (खोली २)',
      totalVoters: 950,
      totalVotesCasted: 680,
      candidateVotes: {
        'अमित चौगुले (आपले उमेदवार)': 415,
        'सुरेश कदम': 140,
        'राजेश जोशी': 86,
        'दिलीप कांबळे': 27,
        'NOTA': 12,
      },
      winner: 'अमित चौगुले (आपले उमेदवार)',
      margin: 275,
      createdAt: DateTime(2026, 1, 16),
    ),
    ElectionResultModel(
      id: 'res-12-10',
      wardName: 'प्रभाग १२ - कसबा-विश्रामबाग वाडा',
      boothNumber: '१२/१०',
      boothName: 'केळकर स्मारक मंदिर सभागृह, शनिवार पेठ',
      totalVoters: 820,
      totalVotesCasted: 590,
      candidateVotes: {
        'अमित चौगुले (आपले उमेदवार)': 235,
        'सुरेश कदम': 303,
        'राजेश जोशी': 36,
        'दिलीप कांबळे': 10,
        'NOTA': 6,
      },
      winner: 'सुरेश कदम',
      margin: 68,
      createdAt: DateTime(2026, 1, 16),
    ),
    ElectionResultModel(
      id: 'res-12-11',
      wardName: 'प्रभाग १२ - कसबा-विश्रामबाग वाडा',
      boothNumber: '१२/११',
      boothName: 'म.न.पा. शाळा क्र. १८, रास्ता पेठ',
      totalVoters: 930,
      totalVotesCasted: 655,
      candidateVotes: {
        'अमित चौगुले (आपले उमेदवार)': 375,
        'सुरेश कदम': 180,
        'राजेश जोशी': 65,
        'दिलीप कांबळे': 23,
        'NOTA': 12,
      },
      winner: 'अमित चौगुले (आपले उमेदवार)',
      margin: 195,
      createdAt: DateTime(2026, 1, 16),
    ),
    ElectionResultModel(
      id: 'res-12-12',
      wardName: 'प्रभाग १२ - कसबा-विश्रामबाग वाडा',
      boothNumber: '१२/१२',
      boothName: 'ज्ञानप्रबोधिनी केंद्र, सदाशिव पेठ',
      totalVoters: 1040,
      totalVotesCasted: 770,
      candidateVotes: {
        'अमित चौगुले (आपले उमेदवार)': 480,
        'सुरेश कदम': 160,
        'राजेश जोशी': 92,
        'दिलीप कांबळे': 26,
        'NOTA': 12,
      },
      winner: 'अमित चौगुले (आपले उमेदवार)',
      margin: 320,
      createdAt: DateTime(2026, 1, 16),
    ),
    ElectionResultModel(
      id: 'res-12-13',
      wardName: 'प्रभाग १२ - कसबा-विश्रामबाग वाडा',
      boothNumber: '१२/१३',
      boothName: 'जनसंपर्क कार्यालय चौक, शनिवार पेठ',
      totalVoters: 1300,
      totalVotesCasted: 960,
      candidateVotes: {
        'अमित चौगुले (आपले उमेदवार)': 680,
        'सुरेश कदम': 140,
        'राजेश जोशी': 95,
        'दिलीप कांबळे': 32,
        'NOTA': 13,
      },
      winner: 'अमित चौगुले (आपले उमेदवार)',
      margin: 540,
      createdAt: DateTime(2026, 1, 16),
    ),
    ElectionResultModel(
      id: 'res-12-14',
      wardName: 'प्रभाग १२ - कसबा-विश्रामबाग वाडा',
      boothNumber: '१२/१४',
      boothName: 'टाउन हॉल वाचनालय, कसबा पेठ',
      totalVoters: 760,
      totalVotesCasted: 530,
      candidateVotes: {
        'अमित चौगुले (आपले उमेदवार)': 295,
        'सुरेश कदम': 155,
        'राजेश जोशी': 56,
        'दिलीप कांबळे': 16,
        'NOTA': 8,
      },
      winner: 'अमित चौगुले (आपले उमेदवार)',
      margin: 140,
      createdAt: DateTime(2026, 1, 16),
    ),

    // --- Ward 27: Navi Peth - Parvati (matching DB) ---
    ElectionResultModel(
      id: 'res-27-01',
      wardName: 'प्रभाग २७ - नवी पेठ - पर्वती',
      boothNumber: '२७/१',
      boothName: 'नवी पेठ मनपा शाळा क्र. ४, पर्वती',
      totalVoters: 1200,
      totalVotesCasted: 890,
      candidateVotes: {
        'महेश (उर्फ अमर) विलास आवळे': 520,
        'धनंजय विष्णू जाधव': 240,
        'अंबेडकर दिलीप शंकर': 85,
        'रविराज बाळासाहेब भामरे': 30,
        'NOTA': 15,
      },
      winner: 'महेश (उर्फ अमर) विलास आवळे',
      margin: 280,
      createdAt: DateTime(2026, 1, 16),
    ),
    ElectionResultModel(
      id: 'res-27-02',
      wardName: 'प्रभाग २७ - नवी पेठ - पर्वती',
      boothNumber: '२७/२',
      boothName: 'मित्रमंडळ चौक कम्युनिटी हॉल, पर्वती',
      totalVoters: 1150,
      totalVotesCasted: 840,
      candidateVotes: {
        'महेश (उर्फ अमर) विलास आवळे': 480,
        'धनंजय विष्णू जाधव': 260,
        'अंबेडकर दिलीप शंकर': 65,
        'रविराज बाळासाहेब भामरे': 22,
        'NOTA': 13,
      },
      winner: 'महेश (उर्फ अमर) विलास आवळे',
      margin: 220,
      createdAt: DateTime(2026, 1, 16),
    ),
    ElectionResultModel(
      id: 'res-27-03',
      wardName: 'प्रभाग २७ - नवी पेठ - पर्वती',
      boothNumber: '२७/३',
      boothName: 'दांडेकर पूल समाज मंदिर, पर्वती',
      totalVoters: 980,
      totalVotesCasted: 710,
      candidateVotes: {
        'महेश (उर्फ अमर) विलास आवळे': 320,
        'धनंजय विष्णू जाधव': 335,
        'अंबेडकर दिलीप शंकर': 35,
        'रविराज बाळासाहेब भामरे': 12,
        'NOTA': 8,
      },
      winner: 'धनंजय विष्णू जाधव',
      margin: 15,
      createdAt: DateTime(2026, 1, 16),
    ),
  ];

  /// Get list of all distinct wards
  Future<List<String>> getWards() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final wards = _results.map((r) => r.wardName).toSet().toList();
    return wards;
  }

  /// Get list of candidates for a specific ward
  Future<List<String>> getCandidates(String ward) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final wardResults = _results.where((r) => r.wardName == ward).toList();
    if (wardResults.isEmpty) return [];
    return wardResults.first.candidateVotes.keys.toList();
  }

  /// Get results for a ward
  Future<List<ElectionResultModel>> getResults({String? ward}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (ward != null && ward.isNotEmpty) {
      return _results.where((r) => r.wardName == ward).toList();
    }
    return List.unmodifiable(_results);
  }

  /// Add new booth result
  Future<ElectionResultModel> addResult(ElectionResultModel result) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _results.insert(0, result);
    return result;
  }

  /// Update existing booth result
  Future<ElectionResultModel> updateResult(ElectionResultModel result) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _results.indexWhere((r) => r.id == result.id);
    if (idx != -1) {
      _results[idx] = result;
      return result;
    }
    throw Exception('Result not found');
  }

  /// Delete booth result
  Future<void> deleteResult(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _results.removeWhere((r) => r.id == id);
  }
}

final electionResultsRepoProvider = Provider<ElectionResultsRepository>((ref) {
  return ElectionResultsRepository();
});

