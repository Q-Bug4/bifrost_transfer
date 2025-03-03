import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';
import 'file_picker_service.dart';

/// 文件选择服务实现
class FilePickerServiceImpl implements FilePickerService {
  /// 日志记录器
  final _logger = Logger('FilePickerServiceImpl');

  @override
  Future<String?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first.path;
      }
    } catch (e) {
      _logger.warning('选择文件失败', e);
    }
    return null;
  }

  @override
  Future<List<String>> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => file.path!)
            .toList();
      }
    } catch (e) {
      _logger.warning('选择多个文件失败', e);
    }
    return [];
  }

  @override
  Future<String?> pickDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      return result;
    } catch (e) {
      _logger.warning('选择目录失败', e);
    }
    return null;
  }
}
