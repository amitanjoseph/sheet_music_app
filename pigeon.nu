#Generate API bindings
def pigeon [filename = "scanner"] {
	#Filename with uppercase first character
	let $upFilename = ($filename | str substring 0..1 | str upcase) ++ ($filename | str substring 1..)
	dart run pigeon --input $'pigeon\($filename).dart' --dart_out $'lib\pigeon\($filename).dart' --kotlin_out $'.\android\app\src\main\kotlin\com\example\sheet_music_app\pigeon\($upFilename).kt' --kotlin_package 'com.example.sheet_music_app.pigeon'
}