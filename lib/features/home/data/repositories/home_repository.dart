import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/lpk_model.dart';
import '../../../course/data/models/course_model.dart';
import '../../../../core/widgets/organisms/hero_banner.dart';

class HomeRepository {
  final ApiClient apiClient;

  HomeRepository({required this.apiClient});

  Future<List<CourseModel>> getCourses({
    String? search,
    String? category,
  }) async {
    try {
      final response = await apiClient.get(
        '/courses',
        queryParameters: {
          if (search != null && search.isNotEmpty)
            'search': search,

          if (category != null && category.isNotEmpty)
            'category': category,
        },
      );

      List<dynamic> data = [];

      if (response.data is List) {
        data = response.data;
      } else if (response.data is Map) {
  if (response.data['data'] is List) {
    data = response.data['data'];
  } else if (response.data['data'] is Map &&
      response.data['data']['data'] is List) {
    data = response.data['data']['data'];
  }
}

print('========================');
print('COURSES RAW RESPONSE:');
print(response.data);
print('COURSES PARSED LENGTH: ${data.length}');
print('========================');

return data
    .map((json) => CourseModel.fromJson(json))
    .toList();
    } on DioException catch (e) {
      print('DioException getCourses: ${e.message}');
      return [];
    } catch (e) {
      print('Exception getCourses: $e');
      return [];
    }
  }

  Future<List<LpkModel>> getLpks({
  String? search,
  String? location,
}) async {
    try {
      final response = await apiClient.get(
  '/lpks',
  queryParameters: {
    if (search != null && search.isNotEmpty)
      'search': search,

    if (location != null &&
        location.isNotEmpty &&
        location != 'Semua')
      'location': location,
  },
);

      List<dynamic> data = [];

      if (response.data is List) {
        data = response.data;
      } else if (response.data is Map) {
        if (response.data['data'] is List) {
          data = response.data['data'];
        } else if (response.data['data'] is Map &&
            response.data['data']['data'] is List) {
          data = response.data['data']['data'];
        }
      }

      final result = <LpkModel>[];

for (final item in data) {
  try {
    result.add(LpkModel.fromJson(item));
  } catch (e) {
    print('ERROR PARSING LPK: $e');
    print(item);
  }
}

return result;
    } on DioException catch (e) {
      print('DioException getLpks: ${e.message}');
      return [];
    } catch (e) {
      print('Exception getLpks: $e');
      return [];
    }
  }

  Future<List<BannerItem>> getBanners() async {
    try {
      final response = await apiClient.get('/banners');

      List<dynamic> data = [];

      if (response.data is Map &&
          response.data['data'] is List) {
        data = response.data['data'];
      }

      return data.map((item) {
  print('====================');
  print('BANNER RAW = ${item['image_url']}');
  print('====================');

  return BannerItem(
    id: item['id'].toString(),
    title: item['title'] ?? '',
    subtitle: null,
    imageUrl: item['image_url'] ?? '',
    tag: 'Promo',
  );
}).toList();
    } catch (e) {
      print('ERROR GET BANNERS: $e');
      return [];
    }
  }
}