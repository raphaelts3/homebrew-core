class Csound < Formula
  desc "Sound and music computing system"
  homepage "https://csound.com"
  url "https://github.com/csound/csound.git",
      tag:      "6.16.1",
      revision: "19a10801d1bc32593e2cd3a5a8b24e3686d96a95"
  license "LGPL-2.1-or-later"
  revision 2
  head "https://github.com/csound/csound.git", branch: "develop"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 big_sur:  "569d8b8ca4c60fe6af258b35a05a9f1a5c01158da03b140bdb35b94f6e782f08"
    sha256 catalina: "12d5c83ad1845c7d4c64de1e19a643a9666fd1ef00858db17f6b3aead92b1ec1"
    sha256 mojave:   "92d638e1f39149bab2ddcb82f0f72dc5986f25fb7f11ae6952bd8417cb54f31e"
  end

  depends_on "asio" => :build
  depends_on "cmake" => :build
  depends_on "eigen" => :build
  depends_on "swig" => :build
  depends_on "fltk"
  depends_on "fluid-synth"
  depends_on "gettext"
  depends_on "hdf5"
  depends_on "jack"
  depends_on "liblo"
  depends_on "libsamplerate"
  depends_on "libsndfile"
  depends_on "numpy"
  depends_on "openjdk"
  depends_on "portaudio"
  depends_on "portmidi"
  depends_on "stk"
  depends_on "wiiuse"

  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build
  uses_from_macos "curl"
  uses_from_macos "zlib"

  conflicts_with "libextractor", because: "both install `extract` binaries"
  conflicts_with "pkcrack", because: "both install `extract` binaries"

  resource "getfem" do
    url "https://download.savannah.gnu.org/releases/getfem/stable/getfem-5.4.1.tar.gz"
    sha256 "6b58cc960634d0ecf17679ba12f8e8cfe4e36b25a5fa821925d55c42ff38a64e"
  end

  def install
    ENV["JAVA_HOME"] = Formula["openjdk"].libexec/"openjdk.jdk/Contents/Home"

    resource("getfem").stage { cp_r "src/gmm", buildpath }

    args = std_cmake_args + %W[
      -DBUILD_JAVA_INTERFACE=ON
      -DBUILD_LINEAR_ALGEBRA_OPCODES=ON
      -DBUILD_LUA_INTERFACE=OFF
      -DBUILD_WEBSOCKET_OPCODE=OFF
      -DCMAKE_INSTALL_RPATH=#{frameworks}
      -DCS_FRAMEWORK_DEST=#{frameworks}
      -DGMM_INCLUDE_DIR=#{buildpath}/gmm
      -DJAVA_MODULE_INSTALL_DIR=#{libexec}
    ]

    mkdir "build" do
      system "cmake", "..", *args
      system "make", "install"
    end

    include.install_symlink frameworks/"CsoundLib64.framework/Headers" => "csound"

    libexec.install buildpath/"interfaces/ctcsound.py"

    python_version = Language::Python.major_minor_version Formula["python@3.9"].bin/"python3"
    (lib/"python#{python_version}/site-packages/homebrew-csound.pth").write <<~EOS
      import site; site.addsitedir('#{libexec}')
    EOS
  end

  def caveats
    <<~EOS
      To use the Python bindings, you may need to add to #{shell_profile}:
        export DYLD_FRAMEWORK_PATH="$DYLD_FRAMEWORK_PATH:#{opt_frameworks}"

      To use the Java bindings, you may need to add to #{shell_profile}:
        export CLASSPATH="#{opt_libexec}/csnd6.jar:."
      and link the native shared library into your Java Extensions folder:
        mkdir -p ~/Library/Java/Extensions
        ln -s "#{opt_libexec}/lib_jcsound6.jnilib" ~/Library/Java/Extensions
    EOS
  end

  test do
    (testpath/"test.orc").write <<~EOS
      0dbfs = 1
      FLrun
      gi_fluidEngineNumber fluidEngine
      gi_realVector la_i_vr_create 1
      instr 1
          a_, a_, a_ chuap 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
          a_signal STKPlucked 440, 1
          a_, a_ hrtfstat a_signal, 0, 0, sprintf("hrtf-%d-left.dat", sr), sprintf("hrtf-%d-right.dat", sr), 9, sr
          hdf5write "test.h5", a_signal
          out a_signal
      endin
    EOS

    (testpath/"test.sco").write <<~EOS
      i 1 0 1
      e
    EOS

    ENV["OPCODE6DIR64"] = frameworks/"CsoundLib64.framework/Resources/Opcodes64"
    ENV["RAWWAVE_PATH"] = Formula["stk"].pkgshare/"rawwaves"
    ENV["SADIR"] = frameworks/"CsoundLib64.framework/Versions/Current/samples"

    output = shell_output "#{bin}/csound test.orc test.sco 2>&1"
    assert_match(/^rtaudio:/, output)
    assert_match(/^rtmidi:/, output)

    assert_predicate testpath/"test.aif", :exist?
    assert_predicate testpath/"test.h5", :exist?

    (testpath/"opcode-existence.orc").write <<~EOS
      JackoInfo
      instr 1
          i_success wiiconnect 1, 1
      endin
    EOS
    system bin/"csound", "--orc", "--syntax-check-only", "opcode-existence.orc"

    with_env("DYLD_FRAMEWORK_PATH" => frameworks) do
      system Formula["python@3.9"].bin/"python3", "-c", "import ctcsound"
    end

    (testpath/"test.java").write <<~EOS
      import csnd6.*;
      public class test {
          public static void main(String args[]) {
              csnd6.csoundInitialize(csnd6.CSOUNDINIT_NO_ATEXIT | csnd6.CSOUNDINIT_NO_SIGNAL_HANDLER);
          }
      }
    EOS
    system Formula["openjdk"].bin/"javac", "-classpath", "#{libexec}/csnd6.jar", "test.java"
    system Formula["openjdk"].bin/"java", "-classpath", "#{libexec}/csnd6.jar:.",
                                          "-Djava.library.path=#{libexec}", "test"
  end
end
