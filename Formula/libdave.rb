class Libdave < Formula
  desc "Discord's DAVE library for end-to-end encryption"
  homepage "https://github.com/discord/libdave"
  url "https://github.com/discord/libdave/archive/refs/tags/v1.1.1/cpp.tar.gz"
  sha256 "23827d585a2020e1bfc01f0b999d6db63de6033be38ff43b6e4e3b4067139325"
  license "MIT"
  version "1.1.1"
  revision 1
  head "https://github.com/discord/libdave.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "nlohmann-json"
  depends_on "openssl@3"

  resource "mlspp" do
    url "https://github.com/cisco/mlspp/archive/1cc50a124a3bc4e143a787ec934280dc70c1034d.tar.gz"
    sha256 "7a9d6318627e548903bc65c3dc5a4de4a90290983efea9a49af8561ed3f999f5"
  end

  def rewrite_local_dylib_linkage!
    dylibs = Dir[lib/"*.dylib"].sort
    dylib_names = dylibs.map { |path| File.basename(path) }

    dylibs.each do |dylib|
      system "install_name_tool", "-id", (opt_lib/File.basename(dylib)).to_s, dylib
    end

    dylibs.each do |dylib|
      Utils.safe_popen_read("otool", "-L", dylib).lines.drop(1).each do |line|
        dependency = line.strip.split.first
        next unless dependency&.start_with?("@rpath/")

        dependency_name = dependency.delete_prefix("@rpath/")
        next unless dylib_names.include?(dependency_name)

        system "install_name_tool", "-change", dependency, (opt_lib/dependency_name).to_s, dylib
      end
    end
  end

  def post_install
    rewrite_local_dylib_linkage! if OS.mac?
  end

  def install
    prefix_path = [
      Formula["nlohmann-json"].opt_prefix,
      Formula["openssl@3"].opt_prefix,
      prefix,
    ].join(";")

    resource("mlspp").stage do
      system "cmake", "-S", ".", "-B", "build",
        *std_cmake_args,
        "-DBUILD_SHARED_LIBS=ON",
        "-DTESTING=OFF",
        "-DDISABLE_GREASE=ON",
        "-DMLS_CXX_NAMESPACE=mlspp",
        "-DCMAKE_PREFIX_PATH=#{prefix_path}",
        "-DOPENSSL_ROOT_DIR=#{Formula["openssl@3"].opt_prefix}"
      system "cmake", "--build", "build"
      system "cmake", "--install", "build"
    end

    system "cmake", "-S", "cpp", "-B", "build",
      *std_cmake_args,
      "-DBUILD_SHARED_LIBS=ON",
      "-DTESTING=OFF",
      "-DPERSISTENT_KEYS=OFF",
      "-DCMAKE_PREFIX_PATH=#{prefix_path}",
      "-DOPENSSL_ROOT_DIR=#{Formula["openssl@3"].opt_prefix}"
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    rewrite_local_dylib_linkage! if OS.mac?
  end

  test do
    if OS.mac?
      system "/usr/bin/ruby", "-e", "require 'fiddle'; Fiddle.dlopen(ARGV.fetch(0))", lib/"libdave.dylib"
    end

    (testpath/"CMakeLists.txt").write <<~CMAKE
      cmake_minimum_required(VERSION 3.20)
      project(libdave_smoke LANGUAGES CXX)

      find_package(libdave CONFIG REQUIRED)

      add_executable(libdave_smoke main.cpp)
      target_link_libraries(libdave_smoke PRIVATE libdave::libdave)
    CMAKE

    (testpath/"main.cpp").write <<~CPP
      #include <dave/version.h>

      int main() {
        return discord::dave::MaxSupportedProtocolVersion() > 0 ? 0 : 1;
      }
    CPP

    system "cmake", "-S", ".", "-B", "build",
      "-DCMAKE_BUILD_TYPE=Release",
      "-DCMAKE_PREFIX_PATH=#{opt_prefix};#{Formula["openssl@3"].opt_prefix}"
    system "cmake", "--build", "build"
    system "./build/libdave_smoke"
  end
end
