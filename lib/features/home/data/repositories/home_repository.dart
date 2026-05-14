import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/lpk_model.dart';
import '../../../course/data/models/course_model.dart';

class HomeRepository {
  final ApiClient apiClient;

  HomeRepository({required this.apiClient});

  Future<List<CourseModel>> getCourses() async {
    try {
      final response = await apiClient.get('/courses');
      List<dynamic> data = [];
      
      if (response.data is List) {
        data = response.data;
      } else if (response.data is Map) {
        if (response.data['data'] is List) {
          data = response.data['data'];
        } else if (response.data['data'] is Map && response.data['data']['data'] is List) {
          data = response.data['data']['data'];
        }
      }
      
      return data.map((json) => CourseModel.fromJson(json)).toList();
    } on DioException catch (e) {
      print('DioException getCourses: ${e.message}');
      return [];
    } catch (e) {
      print('Exception getCourses: $e');
      return [];
    }
  }

  Future<List<LpkModel>> getLpks() async {
    try {
      final response = await apiClient.get('/lpks');
      List<dynamic> data = [];
      
      if (response.data is List) {
        data = response.data;
      } else if (response.data is Map) {
        if (response.data['data'] is List) {
          data = response.data['data'];
        } else if (response.data['data'] is Map && response.data['data']['data'] is List) {
          data = response.data['data']['data'];
        }
      }
      
      return data.map((json) => LpkModel.fromJson(json)).toList();
    } on DioException catch (e) {
      print('DioException getLpks: ${e.message}');
      return [];
    } catch (e) {
      print('Exception getLpks: $e');
      return [];
    }
  }
}
