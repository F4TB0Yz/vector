import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/features/packages/domain/entities/package_entity.dart';
import 'package:vector/features/packages/domain/usecases/update_package_coordinates.dart';

/// Provider para gestionar la asignación de coordenadas a paquetes
class CoordinateAssignmentProvider extends ChangeNotifier {
  final UpdatePackageCoordinates updatePackageCoordinatesUseCase;
  final List<PackageEntity> packagesWithoutCoordinates;

  int _currentIndex = 0;
  Position? _selectedCoordinates;
  bool _isLoading = false;
  String? _errorMessage;

  CoordinateAssignmentProvider({
    required this.updatePackageCoordinatesUseCase,
    required this.packagesWithoutCoordinates,
  });

  // Getters
  int get currentIndex => _currentIndex;
  int get totalPackages => packagesWithoutCoordinates.length;
  PackageEntity get currentPackage => packagesWithoutCoordinates[_currentIndex];
  Position? get selectedCoordinates => _selectedCoordinates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSelectedCoordinates => _selectedCoordinates != null;
  bool get isLastPackage => _currentIndex == totalPackages - 1;

  /// Actualiza las coordenadas seleccionadas en el mapa
  void updateSelectedCoordinates(Position coordinates) {
    _selectedCoordinates = coordinates;
    _errorMessage = null;
    notifyListeners();
  }

  /// Navega al siguiente paquete
  void nextPackage() {
    if (_currentIndex < totalPackages - 1) {
      _currentIndex++;
      _selectedCoordinates = null;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Navega al paquete anterior
  void previousPackage() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _selectedCoordinates = null;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Guarda las coordenadas actuales y avanza al siguiente paquete
  Future<bool> saveCurrentCoordinates() async {
    if (_selectedCoordinates == null) {
      _errorMessage = 'Selecciona una ubicación en el mapa';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await updatePackageCoordinatesUseCase(
      waybillNo: currentPackage.id,
      coordinates: _selectedCoordinates!,
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        // Éxito: limpiar coordenadas seleccionadas
        _selectedCoordinates = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Guarda y continúa al siguiente paquete o cierra si es el último
  Future<bool> saveAndContinue() async {
    final success = await saveCurrentCoordinates();
    
    if (success && !isLastPackage) {
      nextPackage();
    }
    
    return success;
  }
}
