![Sketchpad Logo](assets/icons/icon_128.png)
# Sketchpad
## [Use Online](https://ufosc.github.io/Sketchpad/)
Animate like it's 2009!

Modeled after old handheld animation tools, Sketchpad is meant to be fun and easy to use!

![Screenshot of Sketchpad](.assets/screenshot.png)

## Features
* Lo-fi animations with two resolution options.
* Simple to use UI that gets out of your way.
* Powered by Godot 4.7 for lightweight performance on any device.

## Installation
The easiest way to try Sketchpad is through the [PWA](https://ufosc.github.io/Sketchpad/), as it is cross-platform and updates automatically.

If you want to use native builds of Sketchpad, feel free to download it from the [releases](../../releases/latest) page.

Sketchpad is currently built for Windows and Linux.

## Development
### Building
Make sure you have the standard edition of [Godot 4.7](https://godotengine.org/download/) installed.

1. Clone the repository.
2. Open Godot and load Sketchpad's `project.godot` file. 
3. For instructions on how to export an executable, consult the [Godot documentation](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html).

### GDScript Toolkit
Sketchpad also uses the GDScript Toolkit for linting and formatting. To install it, use the pip package manager:
```
pip install "gdtoolkit==4.*"
```

Once you have it installed, you can run this command in the project folder to verify your contributions follows the [GDScript style guidelines](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html):
```
gdlint $(find . -name "*.gd" -not -path "./addons/*")
```

Any change will be checked for quality in the build automation, so be sure to check to prevent any extra commits.

### Unit Testing
Sketchpad makes use of [Godot Unit Test (GUT)](https://github.com/bitwes/Gut) to test proper functionality. You can run these tests in Godot itself, the command line, or through GUT's VSCode extension.

### Contribution Guidelines
For contributing to Sketchpad, be sure to follow these guidelines:
* For any major change, design considerations should be made in an issue before implementation.
* Your changes should follow the [GDScript style guidelines](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html). The CI builds will halt if any style error is found.
* If you are adding any major new feature, be sure to consider unit testing to verify proper functionality.
* The commit messages should follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) standard.
