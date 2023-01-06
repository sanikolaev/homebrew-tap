class Manticoresearch < Formula
  desc "Open source database for search"
  homepage "https://www.manticoresearch.com"
  url "https://github.com/manticoresoftware/manticoresearch.git", revision: "cc13519f4590466b92cb5ce1cc99fd1d03fa2a9c"
  version "5.0.3-2022010512-cc13519"
  license "GPL-2.0"
  version_scheme 1
  head "https://github.com/manticoresoftware/manticoresearch.git"

  bottle do
    root_url "https://github.com/manticoresoftware/homebrew-manticore/releases/download/manticoresearch-5.0.3-2022010512-cc13519"
    sha256 monterey: "c487e3bd1b7645b797afdebaa2bf31a31e2c757dbdf479c19e5d923342f4ff17"
    sha256 big_sur:  "eb91d06182d5462996ef6130db6af4152d90a98a8300483f2613025b4755e37c"
  end

  depends_on "boost" => :build
  depends_on "cmake" => :build
  depends_on "libpq" => :build
  depends_on "mysql" => :build
  depends_on "postgresql@14" => :build
  depends_on "openssl@1.1"
  depends_on "manticoresoftware/manticore/manticore-backup" => :recommended

  conflicts_with "sphinx", because: "manticore is a fork of sphinx"

  def install
    args = %W[
      -DCMAKE_INSTALL_LOCALSTATEDIR=#{var}
      -DDISTR_BUILD=macosbrew
      -DBoost_NO_BOOST_CMAKE=ON
      -DWITH_ODBC=OFF
    ]

    # Disable support for Manticore Columnar Library on ARM (since the library itself doesn't support it as well)
    args << "-DWITH_COLUMNAR=OFF" if Hardware::CPU.arm?

    mkdir "build" do
      system "cmake", "..", *std_cmake_args, *args
      system "make", "install"
    end
  end

  def post_install
    (var/"run/manticore").mkpath
    (var/"log/manticore").mkpath
    (var/"manticore/data").mkpath
  end

  service do
    run [opt_bin/"searchd", "--config", etc/"manticoresearch/manticore.conf", "--nodetach"]
    keep_alive false
    working_dir HOMEBREW_PREFIX
  end

  test do
    (testpath/"manticore.conf").write <<~EOS
      searchd {
        pid_file = searchd.pid
        binlog_path=#
      }
    EOS
    pid = fork do
      exec bin/"searchd"
    end
  ensure
    Process.kill(9, pid)
    Process.wait(pid)
  end
end
