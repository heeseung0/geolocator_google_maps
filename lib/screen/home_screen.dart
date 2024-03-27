import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const LatLng destLatLng = LatLng(
    37.5233273, // 위도
    126.921252, // 경도
  );

  static const LatLng homeLatLng = LatLng(
    35.1374147,
    128.9790837,
  );

  static const LatLng useLatlng = homeLatLng;

  static const Marker marker = Marker(
    markerId: MarkerId('destination'),
    position: useLatlng,
  );

  static Circle circle = Circle(
    circleId: const CircleId('checkCircle'),
    center: useLatlng,
    fillColor: Colors.blue.withOpacity(0.5), // 원의 색상
    radius: 100, // 원의 반지름 (미터 단위)
    strokeColor: Colors.blue, // 원의 테두리 색
    strokeWidth: 1, // 원의 테두리 두께
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: renderAppBar(),
      body: FutureBuilder<String>(
        future: checkPermission(),
        builder: (context, snapshot) {
          // 로딩 상태
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          //권한 허가된 상태
          if (snapshot.data == '위치 권한이 허가 되었습니다.') {
            return Column(
              children: [
                Expanded(
                  flex: 2, // 2/3만큼 공간 차지
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: useLatlng,
                      zoom: 16.0, // 확대 정도 (높을수록 크게 보임)
                    ),
                    myLocationEnabled: true, // 내 위치 지도에 보여주기
                    markers: {marker},
                    circles: {circle},
                  ),
                ),
                Expanded(
                  // 1/3만큼 공간 차지
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        // 시계 아이콘
                        Icons.timelapse_outlined,
                        color: Colors.blue,
                        size: 50.0,
                      ),
                      const SizedBox(height: 20.0),
                      ElevatedButton(
                        onPressed: () async {
                          final curPosition =
                              await Geolocator.getCurrentPosition(); // 현재 위치
                          final distance = Geolocator.distanceBetween(
                            curPosition.latitude,
                            curPosition.longitude,
                            useLatlng.latitude,
                            useLatlng.longitude,
                          );

                          bool canCheck = distance < 100; // 100미터 이내에 있으면 출첵 가능

                          showDialog(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                title: Text('출첵하기'),
                                // 출첵 가능 여부에 따라 다른 메시지 제공
                                content: Text(
                                  canCheck
                                      ? '출첵을 하시겠습니까?'
                                      : '출첵할 수 없는 위치입니다.'
                                          '현재 위치 : $curPosition',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                    child: Text('취소'),
                                  ),
                                  if (canCheck) // 출첵 가능한 상태일 때만 [출첵하기] 버튼 제공
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                      },
                                      child: Text('출첵하기'),
                                    ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text('출첵하기!'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          //권한 없는 상태
          return Center(
            child: Text(
              snapshot.data.toString(),
            ),
          );
        },
      ),
    );
  }

  AppBar renderAppBar() {
    return AppBar(
      centerTitle: true,
      title: const Text(
        '오늘도 출첵',
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Future<String> checkPermission() async {
    // 위치 서비스 활성화 여부 확인
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isLocationEnabled) {
      return '위치 서비스를 활성화해주세요.';
    }

    // 위치 권한 확인
    LocationPermission checkPermission = await Geolocator.checkPermission();

    if (checkPermission == LocationPermission.denied) {
      // 위치 권한 거절됨
      checkPermission = await Geolocator.requestPermission();

      if (checkPermission == LocationPermission.denied) {
        return '위치 권한을 허가해주세요.';
      }
    }

    // 위치 권한 거절됨 (앱에서 재요청 불가)
    if (checkPermission == LocationPermission.deniedForever) {
      return '앱의 위치 권한을 설정에서 허가해주세요.';
    }

    // 위 모든 조건이 통과되면 위치 권한 허가 완료
    return '위치 권한이 허가 되었습니다.';
  }
}
