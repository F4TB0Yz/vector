import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String account;
  final String token;
  final String uuid;
  final int id;
  final String name;
  final String staffNo;
  final String networkName;
  final String networkCode;
  final String mobile;
  final String email;
  final String financialCenterDesc;
  final String deptName;
  final String postName;
  final String loginTime;

  const User({
    required this.account,
    required this.token,
    required this.uuid,
    required this.id,
    required this.name,
    required this.staffNo,
    required this.networkName,
    required this.networkCode,
    required this.mobile,
    required this.email,
    required this.financialCenterDesc,
    required this.deptName,
    required this.postName,
    required this.loginTime,
  });

  @override
  List<Object?> get props => [
    account,
    token,
    uuid,
    id,
    name,
    staffNo,
    networkName,
    networkCode,
    mobile,
    email,
    financialCenterDesc,
    deptName,
    postName,
    loginTime,
  ];
}
