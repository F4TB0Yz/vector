import 'package:vector/features/map/domain/entities/route_entity.dart'; // Using entities for simplicity, in a real app this would be a Model

/// Abstract class for the map data source.
/// This would handle fetching data from a remote API or local database.
abstract class MapDataSource {
  /// Fetches the active route.
  /// Throws a [ServerException] for all error codes.
  Future<RouteEntity> getActiveRoute();
}
