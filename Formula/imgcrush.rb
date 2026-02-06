class Imgcrush < Formula
  desc "Metal-accelerated image optimizer for macOS"
  homepage "https://imgcrush.dev"
  url "https://github.com/htmeta/imgcrush/archive/refs/tags/v__VERSION__.tar.gz"
  sha256 "__SHA256__"
  license "Commercial"

  depends_on :macos

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/imgcrush"
  end

  test do
    assert_match "imgcrush", shell_output("#{bin}/imgcrush --version")
  end
end
