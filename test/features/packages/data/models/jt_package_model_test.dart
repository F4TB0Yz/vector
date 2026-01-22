import 'package:flutter_test/flutter_test.dart';
import 'package:vector/features/packages/data/models/jt_package_model.dart';

void main() {
  group('JTPackageModel', () {
    test('should correctly parse JSON from J&T API', () {
      final json = {
        "waybillNo": "JTC000022488371",
        "waybillId": "881711458990198784",
        "receiverName": "Santiago Moreno",
        "phone": "3133724672",
        "address":
            "carrera 4A #19-21, barrio fusacatan, conjunto la arboleda portería casa 00, FUSAGASUGA",
        "city": "FUSAGASUGA",
        "area": "252211",
        "taskStatus": 3,
        "isAbnormal": false,
        "scanTime": "2026-01-21 07:43:17",
        "signTime": null,
        "deliverStaff": "FELIPE DUARTE.pcp",
        "distance": 10000.0,
        "lngLat": null,
      };

      final model = JTPackageModel.fromJson(json);

      expect(model.waybillNo, "JTC000022488371");
      expect(model.waybillId, "881711458990198784");
      expect(model.receiverName, "Santiago Moreno");
      expect(model.phone, "3133724672");
      expect(model.taskStatus, 3);
      expect(model.isAbnormal, false);
      expect(model.distance, 10000.0);
      expect(model.lngLat, null);
    });

    test('should handle missing fields gracefully', () {
      final json = <String, dynamic>{};
      final model = JTPackageModel.fromJson(json);

      expect(model.waybillNo, '');
      expect(model.taskStatus, 0);
    });
  });
}
