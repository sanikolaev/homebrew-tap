require 'hardware'

class Manticoresearch < Formula
  desc "Open source database for search"
  homepage "https://manticoresearch.com"
  license "GPL-2.0"

  arch = Hardware::CPU.arch
  url "https://repo.manticoresearch.com/repository/manticoresearch_macos/release/manticore-6.2.12-230822-dc5144d35-osx11.6-#{arch}-main.tar.gz"
  version "6.2.12-230822-dc5144d35"
  sha256 "123"

  depends_on "libpq"
  depends_on "mysql-client"
  depends_on "openssl@1.1"
  depends_on "unixodbc"
  depends_on "zstd"
  depends_on "sanikolaev/tap/manticore-backup" => :recommended
  depends_on "sanikolaev/tap/manticore-buddy" => :recommended
  depends_on "sanikolaev/tap/manticore-icudata" => :recommended

  conflicts_with "sphinx", because: "Manticore Search is a fork of Sphinxsearch"

  def install
    bin.install Dir["bin/*"]
    man1.install Dir["share/doc/manticore/doc/*.1"]
    share.install "share/manticore"
    include.install "include/manticore"
    etc.install "etc/manticoresearch"
  end

  def post_install
    (var/"run/manticore").mkpath
    (var/"log/manticore").mkpath
    (var/"manticore").mkpath
  end

  service do
    run [opt_bin/"searchd", "--config", etc/"manticoresearch/manticore.conf", "--nodetach"]
    environment_variables PATH: std_service_path_env
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
      exec bin/"searchd", "--config", testpath/"manticore.conf"
    end
  ensure
    Process.kill(9, pid)
    Process.wait(pid)
  end

  def caveats; <<~EOS
    If you're facing an issue with "too many open files", you may need to adjust your
    system's maxfiles limit. You can do this by executing the following command:

    sudo launchctl limit maxfiles 16384 65536

    Bear in mind, this will only establish the limit for the duration of your current
    login session. If you want this adjustment to be permanent, you'll need to modify
    your system's launchd configuration.
    EOS
  end

end
