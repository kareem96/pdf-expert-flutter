import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/constants/app_strings.dart';
import '../providers/app_language_provider.dart';
import 'custom_toast.dart';

class AiToolsBottomBar extends ConsumerStatefulWidget {
  final String activeTool;
  final ValueChanged<String> onToolChanged;

  const AiToolsBottomBar({
    super.key,
    required this.activeTool,
    required this.onToolChanged,
  });

  @override
  ConsumerState<AiToolsBottomBar> createState() => _AiToolsBottomBarState();
}

class _AiToolsBottomBarState extends ConsumerState<AiToolsBottomBar> {
  static const String _modelPrefKey = 'has_downloaded_mlkit_model';
  bool _isCheckingModel = true;
  bool _isModelReady = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    setState(() => _isCheckingModel = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDownloaded = prefs.getBool(_modelPrefKey) ?? false;
      
      setState(() {
        _isModelReady = isDownloaded;
        _isCheckingModel = false;
      });

      // If not downloaded, show the Smart Popup immediately
      if (!isDownloaded && mounted) {
        _showDownloadPopup();
      }
    } catch (e) {
      debugPrint('Error checking ML Kit pref: $e');
      setState(() {
        _isModelReady = false;
        _isCheckingModel = false;
      });
    }
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _downloadModel() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);
    CustomToast.show(context, message: AppStrings.toastDownloadWait);

    try {
      // Step 1: Check Internet Connection
      final hasInternet = await _hasInternetConnection();
      
      if (!hasInternet) {
        if (mounted) {
           setState(() => _isDownloading = false);
           CustomToast.show(context, message: 'Download failed. No internet connection.', isError: true);
        }
        return;
      }

      // Step 2: "Simulate" the download progress so UI doesn't freeze.
      // Google Play Services will handle the ACTUAL 15MB download seamlessly in the background.
      await Future.delayed(const Duration(seconds: 4));
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_modelPrefKey, true);

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isModelReady = true;
        });
        CustomToast.show(context, message: 'AI Scanner is ready!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        CustomToast.show(context, message: 'Error initializing: $e', isError: true);
      }
    }
  }

  void _showDownloadPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cloud_download_outlined, color: Color(0xFF6C63FF)),
            const SizedBox(width: 8),
            Text(AppStrings.aiDownloadRequired, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(AppStrings.aiDownloadBody, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadModel();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            child: Text(AppStrings.btnDownload),
          ),
        ],
      ),
    );
  }

  Widget _buildAiToolButton(String id, IconData icon, String label, {bool isBeta = false}) {
    final isActive = widget.activeTool == id;
    final isDisabled = !_isModelReady; // Lock all tools if model not ready

    return GestureDetector(
      onTap: () {
        if (isDisabled) {
           _showDownloadPopup();
           return;
        }
        widget.onToolChanged(id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive && !isDisabled 
              ? const Color(0xFF6C63FF).withOpacity(0.2) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive && !isDisabled 
                ? const Color(0xFF6C63FF) 
                : Colors.transparent,
          ),
        ),
        child: Opacity(
          opacity: isDisabled ? 0.4 : 1.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                size: 18, 
                color: isActive && !isDisabled ? const Color(0xFF6C63FF) : Colors.white70
              ),
              const SizedBox(width: 8),
              if (isBeta) ...[
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isActive && !isDisabled ? FontWeight.w600 : FontWeight.w400,
                    color: isActive && !isDisabled ? const Color(0xFF6C63FF) : Colors.white70,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Beta', style: TextStyle(fontSize: 8, color: Colors.orange)),
                ),
              ] else ...[
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isActive && !isDisabled ? FontWeight.w600 : FontWeight.w400,
                    color: isActive && !isDisabled ? const Color(0xFF6C63FF) : Colors.white70,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appStringsProvider);
    
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh.withOpacity(0.85),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3E3E5A)
                    : Colors.grey.shade200,
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: _isCheckingModel
              ? const Center(
                  child: SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                )
              : Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAiToolButton('erase', Icons.cleaning_services_rounded, AppStrings.aiSubErase),
                        const SizedBox(width: 12),
                        _buildAiToolButton('edit', Icons.auto_fix_high_rounded, AppStrings.aiSubEdit, isBeta: true),
                        const SizedBox(width: 12),
                        _buildAiToolButton('copy', Icons.copy_rounded, AppStrings.aiSubCopy, isBeta: true),
                        
                        // Show a tiny downloading indicator on the right side if active
                        if (_isDownloading)
                          const Padding(
                            padding: EdgeInsets.only(left: 12.0),
                            child: SizedBox(
                              width: 14, 
                              height: 14, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF))
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
