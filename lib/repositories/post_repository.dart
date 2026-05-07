import '../models/post_model.dart';
import '../services/firestore_service.dart';

class PostRepository {
  final FirestoreService _service;

  PostRepository({FirestoreService? service})
    : _service = service ?? FirestoreService();

  Stream<List<PostModel>> streamPosts() {
    return _service
        .streamCollection('posts')
        .map((snap) => snap.docs.map(PostModel.fromDoc).toList());
  }

  Future<void> addPost(PostModel post) =>
      _service.collection('posts').add(post.toMap());

  Future<void> deletePost(String id) => _service.delete('posts', id);
}
