class Libdeflate < Formula
  desc "Heavily optimized DEFLATE/zlib/gzip compression and decompression"
  homepage "https://github.com/ebiggers/libdeflate"
  url "https://github.com/ebiggers/libdeflate/archive/v1.7.tar.gz"
  sha256 "a5e6a0a9ab69f40f0f59332106532ca76918977a974e7004977a9498e3f11350"
  license "MIT"

  bottle do
    sha256 cellar: :any,                 arm64_big_sur: "df5771ac751913a0eae915367ba0ace049ed47d9f9862197b75bbd96bced9507"
    sha256 cellar: :any,                 big_sur:       "fbce754935620074120dd4cb0e24df65d371505c453b4ac95ee73bf6fa098eba"
    sha256 cellar: :any,                 catalina:      "e270c74afc8fbd5171ba5b5e9cecd2c429e4934a6db9b0da1830b0a2a4298b8f"
    sha256 cellar: :any,                 mojave:        "02fb406299f342554d4c236955b6c0cf0e917afb76ed7c8bfe622b03fd6a2b55"
    sha256 cellar: :any,                 high_sierra:   "1c16f650b82c5e7b910b98249e635353d9beee3a3a0cd4f0c841b0d8d19e19c6"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "a6e8b8d2915b3868a099772be109884b4e1a3a6add7ab5f0ab56bd660109fef5"
  end

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"foo").write "test"
    system "#{bin}/libdeflate-gzip", "foo"
    system "#{bin}/libdeflate-gunzip", "-d", "foo.gz"
    assert_equal "test", File.read(testpath/"foo")
  end
end
