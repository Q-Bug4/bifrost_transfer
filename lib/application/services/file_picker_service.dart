/// 文件选择服务接口
abstract class FilePickerService {
  /// 选择单个文件
  ///
  /// 返回选中文件的路径，如果用户取消选择则返回null
  Future<String?> pickFile();

  /// 选择多个文件
  ///
  /// 返回选中文件的路径列表，如果用户取消选择则返回空列表
  Future<List<String>> pickFiles();

  /// 选择目录
  ///
  /// 返回选中目录的路径，如果用户取消选择则返回null
  Future<String?> pickDirectory();
}
