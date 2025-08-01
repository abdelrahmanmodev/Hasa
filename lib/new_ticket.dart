import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ticket_details_screen.dart';
import 'create_ticket_screen.dart';
import 'package:my_project/home_screen.dart';

class TicketsScreen extends StatefulWidget {
  final int initialTabIndex;

  const TicketsScreen({super.key, this.initialTabIndex = 1});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen>
    with SingleTickerProviderStateMixin {
  int selectedTab = 1;
  Future<List<dynamic>>? ticketsFuture;
  bool isRefreshing = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Tab controller for smooth animation
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTabIndex;
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          selectedTab = _tabController.index;
        });
      }
    });
    ticketsFuture = fetchTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');
    if (userJson != null) {
      Map<String, dynamic> userData = jsonDecode(userJson);
      return userData['id'].toString();
    }
    return null;
  }

  Future<List<dynamic>> fetchTickets() async {
    try {
      setState(() {
        isRefreshing = true;
      });

      String? userId = await getUserId();
      if (userId == null) return [];

      var dio = Dio();
      var response = await dio
          .get('https://ha55a.exchange/api/v1/ticket/get.php?id=$userId');

      if (response.statusCode == 200 && response.data['tickets'] != null) {
        return List<dynamic>.from(response.data['tickets']);
      } else {
        return [];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحميل التذاكر'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
      }
      return [];
    } finally {
      if (mounted) {
        setState(() {
          isRefreshing = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      ticketsFuture = fetchTickets();
    });
  }

  // Get priority text
  String _getPriorityText(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'low':
        return 'منخفض';
      case 'medium':
        return 'متوسط';
      case 'heigh':
        return 'عالي';
      default:
        return 'غير محدد';
    }
  }

  // Get priority color
  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'low':
        return const Color(0xFFE8F5E9);
      case 'medium':
        return const Color(0xFFFFF8E1);
      case 'heigh':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  // Get priority text color
  Color _getPriorityTextColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'low':
        return const Color(0xFF43A047);
      case 'medium':
        return const Color(0xFFFF8F00);
      case 'heigh':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF757575);
    }
  }

  // Get status text
  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return 'مفتوحة';
      case 'closed':
        return 'مغلقة';
      case 'pending':
        return 'قيد الانتظار';
      case 'answered':
        return 'تم الرد';
      default:
        return status ?? 'غير محدد';
    }
  }

  // Get status color
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return Colors.blue.shade700;
      case 'closed':
        return Colors.grey.shade700;
      case 'pending':
        return Colors.orange.shade700;
      case 'answered':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildTicketsTable() {
    return FutureBuilder<List<dynamic>>(
      future: ticketsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !isRefreshing) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/lottie/loading.json',
                  height: 120.h,
                  frameRate: FrameRate.max,
                ),
                SizedBox(height: 16.h),
                Text(
                  'جاري تحميل التذاكر...',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.data == null || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
              'assets/images/empty.json',
                  height: 150.h,
                ),
                SizedBox(height: 20.h),
                Text(
                  'لا توجد تذاكر',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'يمكنك إنشاء تذكرة جديدة للحصول على المساعدة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      selectedTab = 1;
                      _tabController.animateTo(1);
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('إنشاء تذكرة جديدة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5951F),
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _onRefresh,
          color: const Color(0xFFF5951F),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            var ticket = snapshot.data![index];
              final status = ticket['status']?.toString() ?? 'open';

              return Container(
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
              color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                    int ticketId = int.tryParse(ticket['id'].toString()) ?? 0;
                    if (ticketId != 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TicketDetailsScreen(ticketId: ticketId),
                        ),
                        ).then((_) => _onRefresh());
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with ticket number and status
                          Row(
                            children: [
                              // Ticket number
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFF5951F).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#${ticket['id'] ?? ''}',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFF5951F),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Status indicator
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color:
                                      _getStatusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8.w,
                                      height: 8.w,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      _getStatusText(status),
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: _getStatusColor(status),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12.h),

                          // Subject
                          Text(
                            ticket['subject'] ?? 'بدون عنوان',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: 12.h),

                          // Priority badge
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(ticket['priority']),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8.w,
                                      height: 8.w,
                                      decoration: BoxDecoration(
                                        color: _getPriorityTextColor(
                                            ticket['priority']),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      _getPriorityText(ticket['priority']),
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: _getPriorityTextColor(
                                            ticket['priority']),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(width: 8.w),

                              // Date if available
                              if (ticket['created_at'] != null)
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 12.sp,
                                          color: Colors.grey.shade700,
                                        ),
                                        SizedBox(width: 4.w),
                                        Expanded(
                                          child: Text(
                                            ticket['created_at'] ?? 'غير معروف',
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 12.sp,
                                              color: Colors.grey.shade700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          SizedBox(height: 12.h),

                          // Last reply and details button
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 14.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                    SizedBox(width: 4.w),
                                    Expanded(
                                      child: Text(
                                        ticket['last_reply'] != null &&
                                                ticket['last_reply']
                                                    .toString()
                                                    .isNotEmpty
                                            ? "آخر رد: ${ticket['last_reply']}"
                                            : "لا يوجد ردود",
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 12.sp,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF5951F),
                                      Color(0xFFFF8F00)
                                    ],
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      int ticketId = int.tryParse(
                                              ticket['id'].toString()) ??
                                          0;
                                      if (ticketId != 0) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TicketDetailsScreen(
                                                    ticketId: ticketId),
                                          ),
                                        ).then((_) => _onRefresh());
                                      }
                                    },
                      borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12.w, vertical: 8.h),
                                      child: Text(
                                        "التفاصيل",
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ),
                ),
              ),
            );
          },
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    // Only show FAB on tickets tab
    if (selectedTab != 0) return const SizedBox.shrink();

    return FloatingActionButton(
      onPressed: _onRefresh,
      backgroundColor: const Color(0xFFF5951F),
      child: const Icon(Icons.refresh, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'التذاكر',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            ),
          ),
        ),
        body: Column(
          children: [
            // Custom tab bar that matches the design
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Create Ticket Tab (Orange)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedTab = 1;
                          _tabController.animateTo(1);
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: selectedTab == 1
                              ? const Color(0xFFF5951F)
                              : Colors.white,
                          border: const Border(
                            bottom: BorderSide(
                              color: Color(0xFFF5951F),
                              width: 3,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color:
                                  selectedTab == 1 ? Colors.white : Colors.grey,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'إنشاء تذكرة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: selectedTab == 1
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // My Tickets Tab (Gray)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedTab = 0;
                          _tabController.animateTo(0);
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: selectedTab == 0
                              ? const Color(0xFFF5951F)
                              : Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: selectedTab == 0
                                  ? const Color(0xFFF5951F)
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.list_alt_rounded,
                              color:
                                  selectedTab == 0 ? Colors.white : Colors.grey,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'تذاكري',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: selectedTab == 0
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTicketsTable(),
                  const CreateTicketScreen(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }
}
