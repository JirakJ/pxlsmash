class Imgcrush < Formula
  desc "Metal-accelerated image optimizer for macOS"
  homepage "https://optipix.dev"
  url "https://github.com/htmeta/optipix/archive/refs/tags/v__VERSION__.tar.gz"
  sha256 "__SHA256__"
  license "Commercial"

  depends_on :macos

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/optipix"
  end

  test do
    assert_match "optipix", shell_output("#{bin}/optipix --version")
  end
end
