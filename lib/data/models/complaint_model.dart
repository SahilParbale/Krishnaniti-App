import 'dart:convert';

class ComplaintAttachment {
  final String url;
  final String type; // 'image/jpeg', 'video/mp4', 'application/pdf', etc.
  final String name;
  final int size;

  ComplaintAttachment({
    required this.url,
    required this.type,
    required this.name,
    this.size = 0,
  });

  bool get isImage =>
      type.startsWith('image/') ||
      url.endsWith('.jpg') ||
      url.endsWith('.jpeg') ||
      url.endsWith('.png') ||
      url.endsWith('.webp');

  bool get isVideo =>
      type.startsWith('video/') ||
      url.endsWith('.mp4') ||
      url.endsWith('.mov') ||
      url.endsWith('.webm');

  bool get isAudio =>
      type.startsWith('audio/') ||
      url.endsWith('.mp3') ||
      url.endsWith('.wav') ||
      url.endsWith('.m4a');

  factory ComplaintAttachment.fromJson(Map<String, dynamic> json) {
    return ComplaintAttachment(
      url: json['url']?.toString() ?? '',
      type: json['type']?.toString() ?? 'image/jpeg',
      name: json['name']?.toString() ?? 'Attachment',
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'type': type,
    'name': name,
    'size': size,
  };
}

class ComplaintProgressUpdate {
  final String note;
  final String status; // 'InProgress', 'Resolved'
  final DateTime timestamp;
  final String? updatedBy;
  final List<ComplaintAttachment> images;

  ComplaintProgressUpdate({
    required this.note,
    required this.status,
    required this.timestamp,
    this.updatedBy,
    this.images = const [],
  });

  factory ComplaintProgressUpdate.fromJson(Map<String, dynamic> json) {
    final imgs = <ComplaintAttachment>[];
    if (json['images'] is List) {
      for (final item in json['images']) {
        if (item is Map<String, dynamic>) {
          imgs.add(ComplaintAttachment.fromJson(item));
        } else if (item is Map) {
          imgs.add(ComplaintAttachment.fromJson(Map<String, dynamic>.from(item)));
        } else if (item is String && item.isNotEmpty) {
          imgs.add(ComplaintAttachment(
            url: item,
            type: 'image/jpeg',
            name: 'Photo',
          ));
        }
      }
    }

    DateTime parsedDate;
    if (json['timestamp'] != null) {
      parsedDate = DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now();
    } else if (json['updated_at'] != null) {
      parsedDate = DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now();
    } else if (json['resolved_at'] != null) {
      parsedDate = DateTime.tryParse(json['resolved_at'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return ComplaintProgressUpdate(
      note: json['note']?.toString() ?? '',
      status: json['status']?.toString() ?? 'InProgress',
      timestamp: parsedDate,
      updatedBy: json['updated_by']?.toString() ??
          json['updatedBy']?.toString() ??
          json['resolved_by']?.toString(),
      images: imgs,
    );
  }

  Map<String, dynamic> toJson() => {
    'note': note,
    'status': status,
    'timestamp': timestamp.toIso8601String(),
    if (updatedBy != null) 'updated_by': updatedBy,
    'images': images.map((i) => i.toJson()).toList(),
  };

  ComplaintProgressUpdate copyWith({
    String? note,
    String? status,
    DateTime? timestamp,
    String? updatedBy,
    List<ComplaintAttachment>? images,
  }) {
    return ComplaintProgressUpdate(
      note: note ?? this.note,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      updatedBy: updatedBy ?? this.updatedBy,
      images: images ?? this.images,
    );
  }
}

class ComplaintModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status; // 'Pending', 'Assigned', 'InProgress', 'Resolved', 'Closed'
  final String? ward;
  final String? area;
  final String? location;
  final String? voterId;
  final String? citizenName;
  final String? citizenMobile;
  final String? assignedTo; // Staff UUID
  final String? assignedStaffName;
  final String? assignedStaffMobile;
  final String? addedByStaffId;
  final String? addedByStaffName;
  final List<String> photos;
  final String? imageUrl;
  final String? videoUrl;
  final String? audioUrl;
  final List<ComplaintAttachment> attachments;
  final List<ComplaintProgressUpdate> progressUpdates;
  final ComplaintProgressUpdate? workInProgress;
  final ComplaintProgressUpdate? resolutionDetails;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? tenantId;

  ComplaintModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.ward,
    this.area,
    this.location,
    this.voterId,
    this.citizenName,
    this.citizenMobile,
    this.assignedTo,
    this.assignedStaffName,
    this.assignedStaffMobile,
    this.addedByStaffId,
    this.addedByStaffName,
    this.photos = const [],
    this.imageUrl,
    this.videoUrl,
    this.audioUrl,
    this.attachments = const [],
    this.progressUpdates = const [],
    this.workInProgress,
    this.resolutionDetails,
    required this.createdAt,
    this.updatedAt,
    this.tenantId,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAssigned => status.toLowerCase() == 'assigned';
  bool get isInProgress => status.toLowerCase() == 'inprogress' || status.toLowerCase() == 'assigned';
  bool get isResolved => status.toLowerCase() == 'resolved' || status.toLowerCase() == 'closed';

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    // Parse description_meta if present
    Map<String, dynamic>? meta;
    if (json['description_meta'] != null) {
      if (json['description_meta'] is Map) {
        meta = Map<String, dynamic>.from(json['description_meta'] as Map);
      } else if (json['description_meta'] is String && (json['description_meta'] as String).trim().isNotEmpty) {
        try {
          meta = Map<String, dynamic>.from(jsonDecode(json['description_meta'] as String) as Map);
        } catch (_) {}
      }
    }

    // Citizen details
    String? name;
    String? mobile;
    if (json['voter'] != null && json['voter'] is Map) {
      final v = json['voter'] as Map<String, dynamic>;
      name = v['name_marathi'] ?? v['name_english'] ?? v['name'];
      mobile = v['mobile'];
    } else if (meta != null && meta['submitter_name'] != null) {
      name = meta['submitter_name']?.toString();
      mobile = meta['submitter_mobile']?.toString();
    } else {
      name = json['citizen_name'] ?? json['user_name'] ?? json['reporter_name'];
      mobile = json['citizen_mobile'] ?? json['mobile'] ?? json['reporter_mobile'];
    }

    // Extract Title & Description matching ComplaintDetail.tsx logic
    String title = 'Request';
    String description = '';

    if (meta != null && meta['original_title'] != null) {
      title = meta['original_title']?.toString() ?? 'Request';
      description = meta['original_description']?.toString() ?? json['description']?.toString() ?? '';
    } else if (json['title'] != null && json['title'].toString().isNotEmpty) {
      title = json['title'].toString();
      description = json['description']?.toString() ?? '';
    } else if (json['request_type'] != null && json['request_type'].toString().isNotEmpty) {
      title = json['request_type'].toString();
      description = json['description']?.toString() ?? '';
    } else if (json['problem'] != null) {
      final problemStr = json['problem'].toString();
      final parts = problemStr.split('\n');
      if (parts.length > 1) {
        title = parts[0].trim();
        description = parts.sublist(1).join('\n').trim();
      } else {
        title = parts[0].trim();
        description = json['description']?.toString() ?? '';
      }
    } else {
      title = json['description']?.toString() ?? 'Civic Issue';
    }

    // Photos & Attachments
    final photosList = <String>[];
    if (json['photos'] != null && json['photos'] is List) {
      for (final p in json['photos']) {
        if (p is String && p.isNotEmpty) photosList.add(p);
      }
    } else if (json['image_url'] != null && json['image_url'].toString().isNotEmpty) {
      photosList.add(json['image_url'].toString());
    }

    final attachmentsList = <ComplaintAttachment>[];
    if (json['attachments'] != null) {
      List rawList = [];
      if (json['attachments'] is List) {
        rawList = json['attachments'] as List;
      } else if (json['attachments'] is String) {
        try {
          rawList = jsonDecode(json['attachments'] as String) as List;
        } catch (_) {}
      }
      for (final att in rawList) {
        if (att is Map) {
          attachmentsList.add(ComplaintAttachment.fromJson(Map<String, dynamic>.from(att)));
        }
      }
    }

    // Progress updates from meta
    ComplaintProgressUpdate? wip;
    if (meta != null && meta['work_in_progress'] != null && meta['work_in_progress'] is Map) {
      wip = ComplaintProgressUpdate.fromJson(Map<String, dynamic>.from(meta['work_in_progress'] as Map));
    }

    ComplaintProgressUpdate? resDetails;
    if (meta != null && meta['resolution_details'] != null && meta['resolution_details'] is Map) {
      resDetails = ComplaintProgressUpdate.fromJson(Map<String, dynamic>.from(meta['resolution_details'] as Map));
    }

    final updatesList = <ComplaintProgressUpdate>[];
    if (meta != null && meta['progress_updates'] != null && meta['progress_updates'] is List) {
      for (final u in meta['progress_updates']) {
        if (u is Map) {
          updatesList.add(ComplaintProgressUpdate.fromJson(Map<String, dynamic>.from(u)));
        }
      }
    } else {
      // Fallback matching ComplaintDetail.tsx
      if (wip != null) updatesList.add(wip);
      if (resDetails != null) updatesList.add(resDetails);
    }

    // Staff details
    String? staffName;
    String? staffMobile;
    if (json['staff'] != null && json['staff'] is Map) {
      final s = json['staff'] as Map;
      staffName = s['name']?.toString();
      staffMobile = s['mobile']?.toString();
    } else if (json['assigned_staff_name'] != null) {
      staffName = json['assigned_staff_name']?.toString();
    }

    String? addedByStaffName;
    if (json['added_by_staff'] != null && json['added_by_staff'] is Map) {
      addedByStaffName = (json['added_by_staff'] as Map)['name']?.toString();
    }

    return ComplaintModel(
      id: json['id']?.toString() ?? '',
      title: title,
      description: description,
      category: json['category'] ?? json['type'] ?? json['request_type'] ?? 'General',
      status: json['status'] ?? 'Pending',
      ward: json['ward']?.toString() ?? json['location']?.toString(),
      area: json['area']?.toString(),
      location: json['location']?.toString(),
      voterId: json['voter_id']?.toString(),
      citizenName: name,
      citizenMobile: mobile,
      assignedTo: json['assigned_to']?.toString(),
      assignedStaffName: staffName,
      assignedStaffMobile: staffMobile,
      addedByStaffId: json['added_by_staff_id']?.toString(),
      addedByStaffName: addedByStaffName,
      photos: photosList,
      imageUrl: json['image_url']?.toString(),
      videoUrl: json['video_url']?.toString(),
      audioUrl: json['audio_url']?.toString(),
      attachments: attachmentsList,
      progressUpdates: updatesList,
      workInProgress: wip,
      resolutionDetails: resDetails,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      tenantId: json['tenant_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'problem': title,
      'description': description,
      'category': category,
      'status': status,
      'ward': ward,
      'area': area,
      'location': location,
      'voter_id': voterId,
      'photos': photos,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'audio_url': audioUrl,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'tenant_id': tenantId,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (addedByStaffId != null) 'added_by_staff_id': addedByStaffId,
    };
  }

  ComplaintModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? status,
    String? ward,
    String? area,
    String? location,
    String? voterId,
    String? citizenName,
    String? citizenMobile,
    String? assignedTo,
    String? assignedStaffName,
    String? assignedStaffMobile,
    String? addedByStaffId,
    String? addedByStaffName,
    List<String>? photos,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    List<ComplaintAttachment>? attachments,
    List<ComplaintProgressUpdate>? progressUpdates,
    ComplaintProgressUpdate? workInProgress,
    ComplaintProgressUpdate? resolutionDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? tenantId,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      ward: ward ?? this.ward,
      area: area ?? this.area,
      location: location ?? this.location,
      voterId: voterId ?? this.voterId,
      citizenName: citizenName ?? this.citizenName,
      citizenMobile: citizenMobile ?? this.citizenMobile,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      assignedStaffMobile: assignedStaffMobile ?? this.assignedStaffMobile,
      addedByStaffId: addedByStaffId ?? this.addedByStaffId,
      addedByStaffName: addedByStaffName ?? this.addedByStaffName,
      photos: photos ?? this.photos,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      attachments: attachments ?? this.attachments,
      progressUpdates: progressUpdates ?? this.progressUpdates,
      workInProgress: workInProgress ?? this.workInProgress,
      resolutionDetails: resolutionDetails ?? this.resolutionDetails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tenantId: tenantId ?? this.tenantId,
    );
  }
}
