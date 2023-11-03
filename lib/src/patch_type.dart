enum PatchType {
  // 忽略
  ignore('ignore'),
  // 可以跳过
  canSkip('canSkip'),
  // 无法跳过
  cannotSkip('cannotSkip');

  final String name;
  const PatchType(this.name);
}
