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
           CustomToast.show(context, message: AppStrings.toastDownloadFailed, isError: true);
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
        CustomToast.show(context, message: AppStrings.toastAiScannerReady);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        CustomToast.show(context, message: '${AppStrings.toastErrorInit}$e', isError: true);
      }
    }
  }

  void _showComingSoonPopup(String title, String description) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(AppStrings.comingSoonTitle, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colorScheme.primary)),
            const SizedBox(height: 12),
            Text(description, style: GoogleFonts.inter(fontSize: 14, color: colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            child: Text(AppStrings.ok, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDownloadPopup() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.cloud_download_outlined, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(AppStrings.aiDownloadRequired, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          ],
        ),
        content: Text(AppStrings.aiDownloadBody, style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: colorScheme.onSurfaceVariant),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadModel();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
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
        if (isBeta) {
          if (id == 'edit') {
            _showComingSoonPopup(AppStrings.aiSubEdit, AppStrings.magicEditDesc);
          } else if (id == 'copy') {
            _showComingSoonPopup(AppStrings.aiSubCopy, AppStrings.smartCopyDesc);
          }
          return;
        }

        if (isDisabled && id != 'erase') {
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
              ? const Color(0xFF6C63FF).withValues(alpha: 0.2) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive && !isDisabled 
                ? const Color(0xFF6C63FF) 
                : Colors.transparent,
          ),
        ),
        child: Opacity(
          opacity: (isDisabled && id != 'erase') ? 0.4 : 1.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                size: 18, 
                color: isActive ? const Color(0xFF6C63FF) : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
              ),
              const SizedBox(width: 8),
              if (isBeta) ...[
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isActive && !isDisabled ? FontWeight.w600 : FontWeight.w400,
                    color: isActive && !isDisabled ? const Color(0xFF6C63FF) : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(AppStrings.labelBeta, style: const TextStyle(fontSize: 8, color: Colors.orange)),
                ),
              ] else ...[
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? const Color(0xFF6C63FF) : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                if (id == 'erase' && isDisabled) ...[
                   const SizedBox(width: 4),
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(AppStrings.labelBasic, style: const TextStyle(fontSize: 8, color: Colors.blue)),
                  ),
                ],
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
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
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
                color: Colors.black.withValues(alpha: 0.1),
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
