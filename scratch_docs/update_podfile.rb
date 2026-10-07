podfile_path = '/Users/veneno/Projects/packages/flutter_chromium_webview/packages/flutter_chromium_webview/example/macos/Podfile'
content = File.read(podfile_path)
if !content.include?("config.build_settings['EXCLUDED_ARCHS'] = 'arm64e'")
  content = content.gsub("config.build_settings['ARCHS'] = cef_arch", "config.build_settings['ARCHS'] = cef_arch\n      config.build_settings['EXCLUDED_ARCHS'] = 'arm64e'")
  File.write(podfile_path, content)
end
