// // lib/screens/user/user_home.dart
// import 'package:f6/screens/user/user_profile_screen.dart';
// import 'package:f6/services/theme_service.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:uuid/uuid.dart';
// import 'package:pocketbase/pocketbase.dart';

// import '../../services/pocketbase_service.dart';
// import 'take_test_screen.dart';

// class UserHome extends StatefulWidget {
//   final String? studentCode;
//   final String? publicTestId;
//   final String? guestId;
//   final String? guestName;

//   const UserHome({
//     this.studentCode,
//     this.publicTestId,
//     this.guestId,
//     this.guestName,
//     super.key,
//   });

//   @override
//   State<UserHome> createState() => _UserHomeState();
// }

// class _UserHomeState extends State<UserHome> {
//   List<Map<String, dynamic>> _testsWithStatus = [];
//   bool _loading = true;
//   String? _studentName;
//   String? _currentGuestId;

//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   bool get _isGuestOnly =>
//       widget.studentCode == null && widget.publicTestId != null;

//   @override
//   void initState() {
//     super.initState();
//     _currentGuestId = widget.guestId;
//     _loadStudentName();
//     _loadAllData();
//   }

//   Future<void> _loadStudentName() async {
//     if (widget.studentCode == null || widget.studentCode!.trim().isEmpty) {
//       if (mounted) setState(() => _studentName = null);
//       return;
//     }

//     try {
//       final result = await PocketBaseService.pb
//           .collection('allowed_students')
//           .getList(
//             filter: 'student_code = "${widget.studentCode!.trim()}"',
//             page: 1,
//             perPage: 1,
//           );

//       final name = result.items.isNotEmpty
//           ? result.items.first.data['student_name']?.toString().trim()
//           : null;
//       if (mounted) {
//         setState(() => _studentName = name?.isNotEmpty == true ? name : null);
//       }
//     } catch (e) {
//       if (mounted) setState(() => _studentName = null);
//     }
//   }

//   void _logout(BuildContext context) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text(
//           'خروج',
//           style: TextStyle(fontFamily: 'SB', fontWeight: FontWeight.bold),
//         ),
//         content: const Text('آیا مطمئن هستید که می‌خواهید خارج شوید؟'),
//         actionsAlignment: MainAxisAlignment.center,
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('خیر', style: TextStyle(fontFamily: 'SB')),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: const Text(
//               'بله، خارج شو',
//               style: TextStyle(fontFamily: 'SB', color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true && mounted) {
//       Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
//     }
//   }

//   Future<void> _loadAllData() async {
//     if (!mounted) return;
//     setState(() => _loading = true);

//     try {
//       List<Map<String, dynamic>> finalList = [];

//       if (_currentGuestId == null && widget.studentCode == null) {
//         _currentGuestId = const Uuid().v4();
//       }

//       List<RecordModel> attempts = [];
//       if (widget.studentCode != null && widget.studentCode!.trim().isNotEmpty) {
//         final res = await PocketBaseService.pb
//             .collection('attempts')
//             .getList(
//               filter:
//                   'student_code = "${widget.studentCode!.trim()}" && submitted_at != null',
//             );
//         attempts = res.items;
//       } else if (_currentGuestId != null) {
//         final res = await PocketBaseService.pb
//             .collection('attempts')
//             .getList(
//               filter: 'guest_id = "$_currentGuestId" && submitted_at != null',
//             );
//         attempts = res.items;
//       }

//       final Map<String, int> completedMap = {};
//       for (var a in attempts) {
//         final testId = a.data['test_id'].toString();
//         final score = (a.data['score'] as num?)?.toInt() ?? 0;
//         completedMap[testId] = score;
//       }

//       if (widget.publicTestId != null && widget.studentCode == null) {
//         try {
//           final testRecord = await PocketBaseService.pb
//               .collection('tests')
//               .getOne(widget.publicTestId!);
//           if (testRecord.data['is_public'] == true) {
//             final testId = testRecord.id;
//             final completed = completedMap.containsKey(testId);
//             final score = completedMap[testId] ?? 0;

//             finalList.add({
//               'testRecord': testRecord,
//               'completed': completed,
//               'score': score,
//               'guestId': _currentGuestId,
//             });
//           }
//         } catch (e) {}
//       } else if (widget.studentCode != null &&
//           widget.studentCode!.trim().isNotEmpty) {
//         final allowedResult = await PocketBaseService.pb
//             .collection('allowed_students')
//             .getList(filter: 'student_code = "${widget.studentCode!.trim()}"');

//         final allowedTestIds = allowedResult.items
//             .map((e) => e.data['test_id'].toString())
//             .toSet();

//         if (allowedTestIds.isNotEmpty) {
//           final testsResult = await PocketBaseService.pb
//               .collection('tests')
//               .getList(
//                 filter: allowedTestIds.map((id) => 'id = "$id"').join(' || '),
//               );

//           for (var testRecord in testsResult.items) {
//             final testId = testRecord.id;
//             final completed = completedMap.containsKey(testId);
//             final score = completedMap[testId] ?? 0;

//             finalList.add({
//               'testRecord': testRecord,
//               'completed': completed,
//               'score': score,
//             });
//           }
//         }

//         if (widget.publicTestId != null) {
//           try {
//             final testRecord = await PocketBaseService.pb
//                 .collection('tests')
//                 .getOne(widget.publicTestId!);
//             if (testRecord.data['is_public'] == true) {
//               final testId = testRecord.id;
//               final completed = completedMap.containsKey(testId);
//               final score = completedMap[testId] ?? 0;

//               finalList.add({
//                 'testRecord': testRecord,
//                 'completed': completed,
//                 'score': score,
//               });
//             }
//           } catch (e) {}
//         }
//       }

//       if (mounted) {
//         setState(() {
//           _testsWithStatus = finalList;
//           _loading = false;
//         });
//       }
//     } catch (e) {
//       print('خطا در بارگذاری: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('خطا در بارگذاری آزمون‌ها'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         setState(() => _loading = false);
//       }
//     }
//   }

//   // تابع جدید امن برای تبدیل رشته تاریخ به DateTime
//   DateTime _safeParseDateTime(String dateStr) {
//     String trimmed = dateStr.trim();

//     // اول سعی کن فرمت استاندارد ISO (با T)
//     try {
//       return DateTime.parse(trimmed);
//     } catch (e) {
//       // اگر نشد، فرمت "YYYY-MM-DD HH:MM:SS" رو امتحان کن
//       final parts = trimmed.split(' ');
//       if (parts.length == 2) {
//         final datePart = parts[0];
//         final timePart = parts[1];

//         final dateParts = datePart.split('-');
//         final timeParts = timePart.split(':');

//         if (dateParts.length == 3 && timeParts.length == 3) {
//           return DateTime(
//             int.parse(dateParts[0]),
//             int.parse(dateParts[1]),
//             int.parse(dateParts[2]),
//             int.parse(timeParts[0]),
//             int.parse(timeParts[1]),
//             int.parse(timeParts[2]),
//           );
//         }
//       }
//       // اگر هیچ‌کدوم کار نکرد، زمان فعلی رو برگردون
//       return DateTime.now();
//     }
//   }

//   Map<String, dynamic> _getTestStatus(RecordModel testRecord) {
//     final now = DateTime.now();

//     final String? startStr = testRecord.data['start_at'];
//     final String? endStr = testRecord.data['end_at'];

//     // اگر زمان تنظیم نشده باشه → همیشه فعال
//     if (startStr == null ||
//         startStr.trim().isEmpty ||
//         endStr == null ||
//         endStr.trim().isEmpty) {
//       return {'status': 'active', 'message': '', 'remainingTime': 'نامحدود'};
//     }

//     DateTime startAt;
//     DateTime endAt;

//     try {
//       startAt = _safeParseDateTime(startStr);
//       endAt = _safeParseDateTime(endStr);
//     } catch (e) {
//       return {'status': 'active', 'message': '', 'remainingTime': 'نامحدود'};
//     }

//     if (now.isBefore(startAt)) {
//       final diff = startAt.difference(now);
//       final hours = diff.inHours;
//       final minutes = diff.inMinutes % 60;

//       return {
//         'status': 'not_started',
//         'message':
//             'آزمون از ساعت ${startAt.hour.toString().padLeft(2, '0')}:${startAt.minute.toString().padLeft(2, '0')} شروع می‌شود',
//         'remainingTime': hours > 0
//             ? '$hours ساعت و $minutes دقیقه دیگر'
//             : '$minutes دقیقه دیگر',
//       };
//     }

//     if (now.isAfter(endAt)) {
//       return {
//         'status': 'expired',
//         'message': 'زمان آزمون به پایان رسیده',
//         'remainingTime': '',
//       };
//     }

//     final diff = endAt.difference(now);
//     final hours = diff.inHours;
//     final minutes = diff.inMinutes % 60;
//     final seconds = diff.inSeconds % 60;

//     return {
//       'status': 'active',
//       'message': '',
//       'remainingTime':
//           '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
//     };
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final primaryColor = isDark
//         ? const Color(0xff00D4FF)
//         : const Color(0xff1A237E);
//     final cardBg = isDark ? const Color(0xff1E1E1E) : Colors.white;
//     final backgroundGradient = isDark
//         ? const LinearGradient(
//             colors: [Color(0xff0D1B2A), Color(0xff1B263B)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           )
//         : const LinearGradient(
//             colors: [Color.fromARGB(255, 223, 235, 250), Colors.white],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           );

//     final headerText = _studentName != null
//         ? '$_studentName (${widget.studentCode})'
//         : (widget.guestName ?? 'مهمان');

//     return Scaffold(
//       key: _scaffoldKey,
//       endDrawer: Drawer(
//         width: MediaQuery.of(context).size.width * 0.6,
//         backgroundColor: cardBg,
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(30),
//             bottomLeft: Radius.circular(30),
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 ListTile(
//                   leading: Icon(
//                     Provider.of<ThemeService>(context).themeMode ==
//                             ThemeMode.dark
//                         ? Icons.dark_mode
//                         : Provider.of<ThemeService>(context).themeMode ==
//                               ThemeMode.light
//                         ? Icons.light_mode
//                         : Icons.brightness_auto,
//                     color: primaryColor,
//                     size: 25,
//                   ),
//                   title: const Text(
//                     'حالت نمایش',
//                     style: TextStyle(fontFamily: 'SB', fontSize: 15),
//                   ),
//                   onTap: () {
//                     showModalBottomSheet(
//                       context: context,
//                       shape: const RoundedRectangleBorder(
//                         borderRadius: BorderRadius.vertical(
//                           top: Radius.circular(25),
//                         ),
//                       ),
//                       builder: (ctx) => SafeArea(
//                         child: Padding(
//                           padding: const EdgeInsets.all(20),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               const Text(
//                                 'انتخاب حالت نمایش',
//                                 style: TextStyle(
//                                   fontFamily: 'SB',
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 20),
//                               ListTile(
//                                 leading: const Icon(Icons.light_mode),
//                                 title: const Text('روشن'),
//                                 onTap: () {
//                                   Provider.of<ThemeService>(
//                                     context,
//                                     listen: false,
//                                   ).setThemeMode(ThemeMode.light);
//                                   Navigator.pop(ctx);
//                                 },
//                               ),
//                               ListTile(
//                                 leading: const Icon(Icons.dark_mode),
//                                 title: const Text('تیره'),
//                                 onTap: () {
//                                   Provider.of<ThemeService>(
//                                     context,
//                                     listen: false,
//                                   ).setThemeMode(ThemeMode.dark);
//                                   Navigator.pop(ctx);
//                                 },
//                               ),
//                               ListTile(
//                                 leading: const Icon(Icons.brightness_auto),
//                                 title: const Text('تطبیقی با سیستم'),
//                                 onTap: () {
//                                   Provider.of<ThemeService>(
//                                     context,
//                                     listen: false,
//                                   ).setThemeMode(ThemeMode.system);
//                                   Navigator.pop(ctx);
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),

//                 Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 20,
//                       backgroundColor: primaryColor.withOpacity(0.1),
//                       child: const Icon(
//                         Icons.person,
//                         size: 25,
//                         color: Color.fromARGB(255, 129, 137, 218),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             headerText,
//                             style: TextStyle(
//                               fontFamily: 'SB',
//                               fontSize: 15,
//                               fontWeight: FontWeight.bold,
//                               color: primaryColor,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           Text(
//                             'شرکت‌کننده آزمون',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: isDark ? Colors.white60 : Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const Divider(height: 50, thickness: 1),

//                 if (!_isGuestOnly)
//                   ListTile(
//                     leading: Icon(
//                       Icons.account_circle_outlined,
//                       size: 28,
//                       color: primaryColor,
//                     ),
//                     title: const Text(
//                       'حساب کاربری',
//                       style: TextStyle(fontFamily: 'SB', fontSize: 17),
//                     ),
//                     onTap: () {
//                       _scaffoldKey.currentState?.closeEndDrawer();
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => UserProfileScreen(
//                             studentCode: widget.studentCode ?? '',
//                           ),
//                         ),
//                       );
//                     },
//                   ),

//                 ListTile(
//                   leading: const Icon(
//                     Icons.logout,
//                     size: 25,
//                     color: Colors.red,
//                   ),
//                   title: const Text(
//                     'خروج از حساب',
//                     style: TextStyle(
//                       fontFamily: 'SB',
//                       fontSize: 15,
//                       color: Colors.red,
//                     ),
//                   ),
//                   onTap: () {
//                     _scaffoldKey.currentState?.closeEndDrawer();
//                     _logout(context);
//                   },
//                 ),

//                 const Spacer(),

//                 Center(
//                   child: Text(
//                     'فرآزمون v1.0',
//                     style: TextStyle(
//                       color: isDark ? Colors.white60 : Colors.grey[600],
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(gradient: backgroundGradient),
//         child: SafeArea(
//           child: Column(
//             children: [
//               Container(
//                 height: 50,
//                 margin: const EdgeInsets.all(15),
//                 padding: const EdgeInsets.symmetric(horizontal: 15),
//                 decoration: BoxDecoration(
//                   color: cardBg,
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
//                       blurRadius: 12,
//                       offset: const Offset(0, 6),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     GestureDetector(
//                       onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
//                       child: Icon(Icons.menu, color: primaryColor, size: 30),
//                     ),
//                     const SizedBox(width: 15),
//                     const Expanded(
//                       child: Text(
//                         'پنل کاربری',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontFamily: 'SB',
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(12),
//                       child: Image.asset('assets/images/logo.png', width: 44),
//                     ),
//                   ],
//                 ),
//               ),

//               Expanded(
//                 child: _loading
//                     ? const Center(child: CircularProgressIndicator())
//                     : RefreshIndicator(
//                         onRefresh: _loadAllData,
//                         color: primaryColor,
//                         child: _testsWithStatus.isEmpty
//                             ? Center(
//                                 child: Column(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.hourglass_empty,
//                                       size: 90,
//                                       color: isDark
//                                           ? Colors.white60
//                                           : Colors.grey,
//                                     ),
//                                     const SizedBox(height: 20),
//                                     Text(
//                                       'هیچ آزمونی یافت نشد',
//                                       style: TextStyle(
//                                         fontSize: 18,
//                                         color: isDark
//                                             ? Colors.white70
//                                             : Colors.grey,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               )
//                             : ListView.builder(
//                                 padding: const EdgeInsets.all(16),
//                                 itemCount: _testsWithStatus.length,
//                                 itemBuilder: (context, i) {
//                                   final item = _testsWithStatus[i];
//                                   final testRecord =
//                                       item['testRecord'] as RecordModel;
//                                   final bool completed =
//                                       item['completed'] as bool;
//                                   final int score = item['score'] as int? ?? 0;

//                                   final statusInfo = _getTestStatus(testRecord);
//                                   final String status = statusInfo['status'];
//                                   final String message = statusInfo['message'];
//                                   final String remainingTime =
//                                       statusInfo['remainingTime'];

//                                   final bool isActive = status == 'active';
//                                   final bool isNotStarted =
//                                       status == 'not_started';
//                                   final bool isExpired = status == 'expired';

//                                   return Container(
//                                     margin: const EdgeInsets.only(bottom: 16),
//                                     padding: const EdgeInsets.all(16),
//                                     decoration: BoxDecoration(
//                                       color: cardBg,
//                                       borderRadius: BorderRadius.circular(20),
//                                       boxShadow: [
//                                         BoxShadow(
//                                           color: Colors.black.withOpacity(
//                                             isDark ? 0.3 : 0.1,
//                                           ),
//                                           blurRadius: 10,
//                                           offset: const Offset(0, 4),
//                                         ),
//                                       ],
//                                       border: Border.all(
//                                         color: isActive
//                                             ? primaryColor.withOpacity(0.4)
//                                             : Colors.grey.withOpacity(0.6),
//                                         width: 3,
//                                       ),
//                                     ),
//                                     child: Row(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         CircleAvatar(
//                                           radius: 30,
//                                           backgroundColor: completed
//                                               ? Colors.grey[400]
//                                               : (isActive
//                                                     ? Colors.green
//                                                     : Colors.grey[500]),
//                                           child: Icon(
//                                             completed
//                                                 ? Icons.check_circle
//                                                 : (isActive
//                                                       ? Icons.play_circle_fill
//                                                       : Icons.lock_clock),
//                                             color: Colors.white,
//                                             size: 34,
//                                           ),
//                                         ),
//                                         const SizedBox(width: 16),
//                                         Expanded(
//                                           child: Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               Text(
//                                                 testRecord.data['title'] ??
//                                                     'بدون عنوان',
//                                                 style: TextStyle(
//                                                   fontFamily: 'SB',
//                                                   fontSize: 18,
//                                                   fontWeight: FontWeight.bold,
//                                                   color: completed || !isActive
//                                                       ? (isDark
//                                                             ? Colors.white60
//                                                             : Colors.grey[700])
//                                                       : primaryColor,
//                                                 ),
//                                               ),
//                                               const SizedBox(height: 8),
//                                               if (isActive &&
//                                                   remainingTime != 'نامحدود')
//                                                 Text(
//                                                   'زمان باقی‌مانده: $remainingTime',
//                                                   style: TextStyle(
//                                                     fontFamily: 'SB',
//                                                     fontSize: 15,
//                                                     color: Colors.orange[700],
//                                                     fontWeight: FontWeight.bold,
//                                                   ),
//                                                 )
//                                               else if (isNotStarted)
//                                                 Text(
//                                                   message,
//                                                   style: TextStyle(
//                                                     fontSize: 14,
//                                                     color: Colors.orange[700],
//                                                   ),
//                                                 )
//                                               else if (isExpired)
//                                                 Text(
//                                                   message,
//                                                   style: TextStyle(
//                                                     fontSize: 14,
//                                                     color: Colors.red[700],
//                                                   ),
//                                                 )
//                                               else if (remainingTime ==
//                                                   'نامحدود')
//                                                 Text(
//                                                   'زمان نامحدود',
//                                                   style: TextStyle(
//                                                     fontSize: 14,
//                                                     color: Colors.blue[700],
//                                                   ),
//                                                 ),
//                                               if (completed) ...[
//                                                 const SizedBox(height: 10),
//                                                 Container(
//                                                   padding:
//                                                       const EdgeInsets.symmetric(
//                                                         horizontal: 12,
//                                                         vertical: 8,
//                                                       ),
//                                                   decoration: BoxDecoration(
//                                                     color: score >= 12
//                                                         ? Colors.green[50]
//                                                         : Colors.red[50],
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                           12,
//                                                         ),
//                                                     border: Border.all(
//                                                       color: score >= 12
//                                                           ? Colors.green
//                                                           : Colors.red,
//                                                       width: 1.5,
//                                                     ),
//                                                   ),
//                                                   child: FittedBox(
//                                                     fit: BoxFit.scaleDown,
//                                                     child: Row(
//                                                       mainAxisSize:
//                                                           MainAxisSize.min,
//                                                       children: [
//                                                         Icon(
//                                                           score >= 12
//                                                               ? Icons
//                                                                     .check_circle
//                                                               : Icons.cancel,
//                                                           color: score >= 12
//                                                               ? Colors.green
//                                                               : Colors.red,
//                                                           size: 22,
//                                                         ),
//                                                         const SizedBox(
//                                                           width: 6,
//                                                         ),
//                                                         Text(
//                                                           'نمره: $score/۲۰',
//                                                           style: TextStyle(
//                                                             fontFamily: 'SB',
//                                                             fontSize: 15,
//                                                             fontWeight:
//                                                                 FontWeight.bold,
//                                                             color: score >= 12
//                                                                 ? Colors
//                                                                       .green[800]
//                                                                 : Colors
//                                                                       .red[800],
//                                                           ),
//                                                         ),
//                                                         const SizedBox(
//                                                           width: 10,
//                                                         ),
//                                                         Text(
//                                                           score >= 12
//                                                               ? 'قبول'
//                                                               : 'مردود',
//                                                           style: TextStyle(
//                                                             fontFamily: 'SB',
//                                                             fontSize: 16,
//                                                             fontWeight:
//                                                                 FontWeight.bold,
//                                                             color: score >= 12
//                                                                 ? Colors.green
//                                                                 : Colors.red,
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ],
//                                           ),
//                                         ),
//                                         const SizedBox(width: 16),
//                                         ElevatedButton(
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor:
//                                                 isActive && !completed
//                                                 ? Colors.green[600]
//                                                 : Colors.grey[400],
//                                             foregroundColor: Colors.white,
//                                             elevation: isActive && !completed
//                                                 ? 8
//                                                 : 0,
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 28,
//                                               vertical: 14,
//                                             ),
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(20),
//                                             ),
//                                           ),
//                                           onPressed: isActive && !completed
//                                               ? () => Navigator.push(
//                                                   context,
//                                                   MaterialPageRoute(
//                                                     builder: (_) =>
//                                                         TakeTestScreen(
//                                                           testId: testRecord.id,
//                                                           studentCode: widget
//                                                               .studentCode,
//                                                           studentName:
//                                                               _studentName,
//                                                           guestId:
//                                                               _currentGuestId,
//                                                           guestName:
//                                                               widget.guestName,
//                                                         ),
//                                                   ),
//                                                 ).then((_) => _loadAllData())
//                                               : null,
//                                           child: Text(
//                                             completed
//                                                 ? 'انجام شده'
//                                                 : (isActive
//                                                       ? 'شروع آزمون'
//                                                       : (isNotStarted
//                                                             ? 'شروع نشده'
//                                                             : 'منقضی شده')),
//                                             style: const TextStyle(
//                                               fontFamily: 'SB',
//                                               fontSize: 15,
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 },
//                               ),
//                       ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// lib/screens/user/user_home.dart
import 'package:fetrati_farazmoon/screens/user/user_profile_screen.dart';
import 'package:fetrati_farazmoon/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../services/pocketbase_service.dart';
import 'take_test_screen.dart';

class UserHome extends StatefulWidget {
  final String? studentCode;
  final String? publicTestId;
  final String? guestId;
  final String? guestName;

  const UserHome({
    this.studentCode,
    this.publicTestId,
    this.guestId,
    this.guestName,
    super.key,
  });

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  List<Map<String, dynamic>> _testsWithStatus = [];
  bool _loading = true;
  String? _studentName;
  String? _currentGuestId;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool get _isGuestOnly =>
      widget.studentCode == null && widget.publicTestId != null;

  @override
  void initState() {
    super.initState();
    _currentGuestId = widget.guestId;
    _loadStudentName();
    _loadAllData();
  }

  Future<void> _loadStudentName() async {
    if (widget.studentCode == null || widget.studentCode!.trim().isEmpty) {
      if (mounted) setState(() => _studentName = null);
      return;
    }

    try {
      final result = await PocketBaseService.pb
          .collection('allowed_students')
          .getList(
            filter: 'student_code = "${widget.studentCode!.trim()}"',
            page: 1,
            perPage: 1,
          );

      final name = result.items.isNotEmpty
          ? result.items.first.data['student_name']?.toString().trim()
          : null;
      if (mounted) {
        setState(() => _studentName = name?.isNotEmpty == true ? name : null);
      }
    } catch (e) {
      if (mounted) setState(() => _studentName = null);
    }
  }

  void _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'خروج',
          style: TextStyle(fontFamily: 'SB', fontWeight: FontWeight.bold),
        ),
        content: const Text('آیا مطمئن هستید که می‌خواهید خارج شوید؟'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('خیر', style: TextStyle(fontFamily: 'SB')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'بله، خارج شو',
              style: TextStyle(fontFamily: 'SB', color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      List<Map<String, dynamic>> finalList = [];

      if (_currentGuestId == null && widget.studentCode == null) {
        _currentGuestId = const Uuid().v4();
      }

      List<RecordModel> attempts = [];
      if (widget.studentCode != null && widget.studentCode!.trim().isNotEmpty) {
        final res = await PocketBaseService.pb
            .collection('attempts')
            .getList(
              filter:
                  'student_code = "${widget.studentCode!.trim()}" && submitted_at != null',
            );
        attempts = res.items;
      } else if (_currentGuestId != null) {
        final res = await PocketBaseService.pb
            .collection('attempts')
            .getList(
              filter: 'guest_id = "$_currentGuestId" && submitted_at != null',
            );
        attempts = res.items;
      }

      final Map<String, int> completedMap = {};
      for (var a in attempts) {
        final testId = a.data['test_id'].toString();
        final score = (a.data['score'] as num?)?.toInt() ?? 0;
        completedMap[testId] = score;
      }

      if (widget.publicTestId != null && widget.studentCode == null) {
        try {
          final testRecord = await PocketBaseService.pb
              .collection('tests')
              .getOne(widget.publicTestId!);
          if (testRecord.data['is_public'] == true) {
            final testId = testRecord.id;
            final completed = completedMap.containsKey(testId);
            final score = completedMap[testId] ?? 0;

            finalList.add({
              'testRecord': testRecord,
              'completed': completed,
              'score': score,
              'guestId': _currentGuestId,
            });
          }
        } catch (e) {}
      } else if (widget.studentCode != null &&
          widget.studentCode!.trim().isNotEmpty) {
        final allowedResult = await PocketBaseService.pb
            .collection('allowed_students')
            .getList(filter: 'student_code = "${widget.studentCode!.trim()}"');

        final allowedTestIds = allowedResult.items
            .map((e) => e.data['test_id'].toString())
            .toSet();

        if (allowedTestIds.isNotEmpty) {
          final testsResult = await PocketBaseService.pb
              .collection('tests')
              .getList(
                filter: allowedTestIds.map((id) => 'id = "$id"').join(' || '),
              );

          for (var testRecord in testsResult.items) {
            final testId = testRecord.id;
            final completed = completedMap.containsKey(testId);
            final score = completedMap[testId] ?? 0;

            finalList.add({
              'testRecord': testRecord,
              'completed': completed,
              'score': score,
            });
          }
        }

        if (widget.publicTestId != null) {
          try {
            final testRecord = await PocketBaseService.pb
                .collection('tests')
                .getOne(widget.publicTestId!);
            if (testRecord.data['is_public'] == true) {
              final testId = testRecord.id;
              final completed = completedMap.containsKey(testId);
              final score = completedMap[testId] ?? 0;

              finalList.add({
                'testRecord': testRecord,
                'completed': completed,
                'score': score,
              });
            }
          } catch (e) {}
        }
      }

      if (mounted) {
        setState(() {
          _testsWithStatus = finalList;
          _loading = false;
        });
      }
    } catch (e) {
      print('خطا در بارگذاری: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در بارگذاری آزمون‌ها'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color(0xff00D4FF)
        : const Color(0xff1A237E);
    final cardBg = isDark ? const Color(0xff1E1E1E) : Colors.white;
    final backgroundGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xff0D1B2A), Color(0xff1B263B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color.fromARGB(255, 223, 235, 250), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    final headerText = _studentName != null
        ? '$_studentName (${widget.studentCode})'
        : (widget.guestName ?? 'مهمان');

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.6,
        backgroundColor: cardBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            bottomLeft: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(
                    Provider.of<ThemeService>(context).themeMode ==
                            ThemeMode.dark
                        ? Icons.dark_mode
                        : Provider.of<ThemeService>(context).themeMode ==
                              ThemeMode.light
                        ? Icons.light_mode
                        : Icons.brightness_auto,
                    color: primaryColor,
                    size: 25,
                  ),
                  title: const Text(
                    'حالت نمایش',
                    style: TextStyle(fontFamily: 'SB', fontSize: 15),
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(25),
                        ),
                      ),
                      builder: (ctx) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'انتخاب حالت نمایش',
                                style: TextStyle(
                                  fontFamily: 'SB',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ListTile(
                                leading: const Icon(Icons.light_mode),
                                title: const Text('روشن'),
                                onTap: () {
                                  Provider.of<ThemeService>(
                                    context,
                                    listen: false,
                                  ).setThemeMode(ThemeMode.light);
                                  Navigator.pop(ctx);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.dark_mode),
                                title: const Text('تیره'),
                                onTap: () {
                                  Provider.of<ThemeService>(
                                    context,
                                    listen: false,
                                  ).setThemeMode(ThemeMode.dark);
                                  Navigator.pop(ctx);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.brightness_auto),
                                title: const Text('تطبیقی با سیستم'),
                                onTap: () {
                                  Provider.of<ThemeService>(
                                    context,
                                    listen: false,
                                  ).setThemeMode(ThemeMode.system);
                                  Navigator.pop(ctx);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: const Icon(
                        Icons.person,
                        size: 25,
                        color: Color.fromARGB(255, 129, 137, 218),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerText,
                            style: TextStyle(
                              fontFamily: 'SB',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'شرکت‌کننده آزمون',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 50, thickness: 1),

                if (!_isGuestOnly)
                  ListTile(
                    leading: Icon(
                      Icons.account_circle_outlined,
                      size: 28,
                      color: primaryColor,
                    ),
                    title: const Text(
                      'حساب کاربری',
                      style: TextStyle(fontFamily: 'SB', fontSize: 17),
                    ),
                    onTap: () {
                      _scaffoldKey.currentState?.closeEndDrawer();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(
                            studentCode: widget.studentCode ?? '',
                          ),
                        ),
                      );
                    },
                  ),

                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    size: 25,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'خروج از حساب',
                    style: TextStyle(
                      fontFamily: 'SB',
                      fontSize: 15,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    _scaffoldKey.currentState?.closeEndDrawer();
                    _logout(context);
                  },
                ),

                const Spacer(),

                Center(
                  child: Text(
                    'فرآزمون v1.0',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                height: 50,
                margin: const EdgeInsets.all(15),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                      child: Icon(Icons.menu, color: primaryColor, size: 30),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Text(
                        'پنل کاربری',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'SB',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset('assets/images/logo.png', width: 44),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadAllData,
                        color: primaryColor,
                        child: _testsWithStatus.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.hourglass_empty,
                                      size: 90,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.grey,
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'هیچ آزمونی یافت نشد',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _testsWithStatus.length,
                                itemBuilder: (context, i) {
                                  final item = _testsWithStatus[i];
                                  final testRecord =
                                      item['testRecord'] as RecordModel;
                                  final bool completed =
                                      item['completed'] as bool;
                                  final int score = item['score'] as int? ?? 0;

                                  // زمان آزمون — پیش‌فرض ۳۰ دقیقه
                                  final int duration =
                                      (testRecord.data['duration_minutes']
                                              as num?)
                                          ?.toInt() ??
                                      30;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(
                                            isDark ? 0.3 : 0.1,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: completed
                                            ? Colors.grey.withOpacity(0.6)
                                            : primaryColor.withOpacity(0.4),
                                        width: 3,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 25,
                                          backgroundColor: completed
                                              ? Colors.grey[400]
                                              : Colors.green,
                                          child: Icon(
                                            completed
                                                ? Icons.check_circle
                                                : Icons.play_circle_fill,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                testRecord.data['title'] ??
                                                    'بدون عنوان',
                                                style: TextStyle(
                                                  fontFamily: 'SB',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: completed
                                                      ? (isDark
                                                            ? Colors.white60
                                                            : Colors.grey[700])
                                                      : primaryColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$duration دقیقه',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark
                                                      ? Colors.white60
                                                      : Colors.black87,
                                                ),
                                              ),
                                              if (completed) ...[
                                                const SizedBox(height: 10),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: score >= 12
                                                        ? Colors.green[50]
                                                        : Colors.red[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: score >= 12
                                                          ? Colors.green
                                                          : Colors.red,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          score >= 12
                                                              ? Icons
                                                                    .check_circle
                                                              : Icons.cancel,
                                                          color: score >= 12
                                                              ? Colors.green
                                                              : Colors.red,
                                                          size: 22,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          'نمره: $score/۲۰',
                                                          style: TextStyle(
                                                            fontFamily: 'SB',
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: score >= 12
                                                                ? Colors
                                                                      .green[800]
                                                                : Colors
                                                                      .red[800],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        Text(
                                                          score >= 12
                                                              ? 'قبول'
                                                              : 'مردود',
                                                          style: TextStyle(
                                                            fontFamily: 'SB',
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: score >= 12
                                                                ? Colors.green
                                                                : Colors.red,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: completed
                                                ? Colors.grey[400]
                                                : Colors.green[600],
                                            foregroundColor: Colors.white,
                                            elevation: completed ? 0 : 8,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 15,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          onPressed: completed
                                              ? null
                                              : () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        TakeTestScreen(
                                                          testId: testRecord.id,
                                                          studentCode: widget
                                                              .studentCode,
                                                          studentName:
                                                              _studentName,
                                                          guestId:
                                                              _currentGuestId,
                                                          guestName:
                                                              widget.guestName,
                                                        ),
                                                  ),
                                                ).then((_) => _loadAllData()),
                                          child: Text(
                                            completed
                                                ? 'انجام شده'
                                                : 'شروع آزمون',
                                            style: const TextStyle(
                                              fontFamily: 'SB',
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
