import 'post_summary.dart';

class PostSummaryPageResponse {
  final List<PostSummary> posts;
  final bool isLastPage;

  PostSummaryPageResponse({
    required this.posts,
    required this.isLastPage,
  });
}