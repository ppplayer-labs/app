require 'xcodeproj'

project_path = 'macos/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'Runner' }
if target.nil?
  puts "Target 'Runner' not found"
  exit(1)
end

phase_name = 'Embed CEF Framework'
existing_phase = target.shell_script_build_phases.find { |p| p.name == phase_name }
unless existing_phase
  phase = project.new(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
  phase.name = phase_name
  phase.shell_script = 'python3 "$PROJECT_DIR/Flutter/ephemeral/.symlinks/plugins/flutter_chromium_webview/macos/scripts/embed_cef.py"'
  
  # Insert before Code Signing or at the end
  target.build_phases << phase
  
  puts "Added build phase: #{phase_name}"
  project.save
else
  puts "Build phase already exists"
end
