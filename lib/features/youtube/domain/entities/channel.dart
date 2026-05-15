import 'package:equatable/equatable.dart';

class Channel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String subscriberCount;
  final String videoCount;

  const Channel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    this.subscriberCount = '0',
    this.videoCount = '0',
  });

  @override
  List<Object?> get props => [id, title];
}
