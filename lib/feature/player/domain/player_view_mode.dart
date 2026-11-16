enum PlayerViewMode {
  standard,
  cd;

  static PlayerViewMode fromStorage(String? rawValue) {
    return switch (rawValue) {
      'cd' => PlayerViewMode.cd,
      _ => PlayerViewMode.standard,
    };
  }
}
