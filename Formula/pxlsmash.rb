class Imgcrush < Formula
  desc "Metal-accelerated image optimizer for macOS"
  homepage "https://pxlsmash.dev"
  url "https://github.com/htmeta/pxlsmash/archive/refs/tags/v__VERSION__.tar.gz"
  sha256 "__SHA256__"
  license "Commercial"

  depends_on :macos

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/pxlsmash"
  end

  test do
    assert_match "pxlsmash", shell_output("#{bin}/pxlsmash --version")
  end
end
