import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../repositories/post_repository.dart';

class PostProvider extends ChangeNotifier {
  final PostRepository _repo = PostRepository();
  List<PostModel> _posts = [];

  List<PostModel> get posts => _posts;

  PostProvider() {
    _repo.streamPosts().listen((posts) {
      _posts = posts;
      notifyListeners();
    });
  }

  Future<void> addPost(PostModel post) => _repo.addPost(post);
  Future<void> deletePost(String id) => _repo.deletePost(id);
}
