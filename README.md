# Multi Command Runner (multi-cmd)

A powerful bash script that executes any command with multiple combinations of variables, providing comprehensive logging, pre/post command execution, and automated output file management.

## Features

- **Universal Command Execution**: Run any command with variable combinations
- **Comprehensive Logging**: Optional detailed logging of all command outputs
- **Pre/Post Commands**: Execute setup and cleanup commands automatically
- **Output File Management**: Automatically copy and organize output files
- **Detailed Reporting**: Beautiful failure reports with formatted tables
- **Flexible Configuration**: Customizable output directories and file handling
- **Cross-Platform**: Works on Linux, macOS, and Windows (with bash)

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Options](#options)
- [Examples](#examples)
- [How Combinations Work](#how-combinations-work)
- [Output Structure](#output-structure)
- [Contributing](#contributing)
- [License](#license)

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/shriram-m/multi-cmd.git
   cd multi-cmd
   ```

2. **Make the script executable (For Linux):**
   ```bash
   chmod +x multi_cmd.sh
   ```

3. **Optional: Add to PATH for global access:**
   **For Linux:**
   ```bash
   sudo cp multi_cmd.sh /usr/local/bin/multi_cmd
   ```

   **For Windows (Git Bash):**
    Add the script directory to your PATH environment variable.
    ```bash
    export PATH=$PATH:/path/to/multi_cmd
    ```

## Usage

```bash
multi_cmd.sh [OPTIONS] VAR1=VAL1,VAL2 VAR2=VAL3,VAL4 ...
```

The script requires at least one command to execute (`-c` option) and variable combinations to iterate through.

## Options

| Option | Description |
|--------|-------------|
| `-c, --command="command"` | **Required.** The main command to execute for each combination |
| `-x, --command-suffix="suffix"` | Fixed suffix to append to every command execution (after variable combinations) |
| `-l, --log` | Enable logging mode - saves command logs for each combination |
| `-p, --pre-command="command"` | Command to run before each main command execution |
| `-s, --post-command="command"` | Command to run after each successful main command execution |
| `-f, --output-file="path"` | Path to output file to copy after successful execution |
| `-d, --output-dir="path"` | Custom output directory for copied files |
| `-h, --help` | Display help information |

## Examples

### Build System (Make)
```bash
# Build with different toolchains and configurations
multi_cmd.sh -c "make build" -x "-j" -l -f "build/app.hex" -p "make clean" \
    TOOLCHAIN=GCC_ARM,ARM CONFIG=Debug,Release
```

### Web Development (npm)
```bash
# Build for different environments and Node versions
multi_cmd.sh -c "npm run build" -x "--verbose" -l -f "dist/bundle.js" \
    --pre-command="npm install" ENV=dev,prod NODE_VERSION=16,18
```

### Containerization (Docker)
```bash
# Build Docker images for multiple architectures
multi_cmd.sh -c "docker build -t myapp ." -x "--no-cache" --log \
    --output-file="myapp.tar" --post-command="docker save myapp > myapp.tar" \
    ARCH=amd64,arm64 VERSION=latest,v1.0
```

### Testing (pytest)
```bash
# Run tests with different Python versions and configurations
multi_cmd.sh -c "python -m pytest tests/" -l \
    PYTHON_VERSION=3.8,3.9,3.10 TEST_CONFIG=unit,integration
```

## 🔍 How Combinations Work

The script generates all possible combinations of the provided variables. Here's how it works:

**Input:**
```bash
multi_cmd.sh -c "echo Processing" \
    TOOLCHAIN=GCC,CLANG CONFIG=Debug,Release ARCH=x86,x64
```

**Generated Combinations:**

| Execution | TOOLCHAIN | CONFIG  | ARCH | Command Executed |
|-----------|-----------|---------|------|------------------|
| 1         | GCC       | Debug   | x86  | `echo Processing TOOLCHAIN=GCC CONFIG=Debug ARCH=x86` |
| 2         | GCC       | Debug   | x64  | `echo Processing TOOLCHAIN=GCC CONFIG=Debug ARCH=x64` |
| 3         | GCC       | Release | x86  | `echo Processing TOOLCHAIN=GCC CONFIG=Release ARCH=x86` |
| 4         | GCC       | Release | x64  | `echo Processing TOOLCHAIN=GCC CONFIG=Release ARCH=x64` |
| 5         | CLANG     | Debug   | x86  | `echo Processing TOOLCHAIN=CLANG CONFIG=Debug ARCH=x86` |
| 6         | CLANG     | Debug   | x64  | `echo Processing TOOLCHAIN=CLANG CONFIG=Debug ARCH=x64` |
| 7         | CLANG     | Release | x86  | `echo Processing TOOLCHAIN=CLANG CONFIG=Release ARCH=x86` |
| 8         | CLANG     | Release | x64  | `echo Processing TOOLCHAIN=CLANG CONFIG=Release ARCH=x64` |

**Total combinations:** 2 × 2 × 2 = 8 executions

**Formula:** If you have variables with `n1`, `n2`, `n3`... values respectively, total combinations = `n1 × n2 × n3 × ...`

## Output Structure

When logging is enabled, the script creates an organized output directory as shown below:

```
../myproject_run_17-09-25_14-30-45/
├── run_GCC_ARM_Debug.log
├── run_GCC_ARM_Release.log
├── run_ARM_Debug.log
├── run_ARM_Release.log
├── output_GCC_ARM_Debug.hex
├── output_GCC_ARM_Release.hex
├── output_ARM_Debug.hex
└── output_ARM_Release.hex
```

### File Naming Convention

- **Log files**: `run_{variable_combination}.log`
- **Output files**: `output_{variable_combination}.{extension}`
- **Directory**: `{project_name}_run_{date}_{time}`

## Failure Reporting

The script provides detailed failure reports in a formatted table:

```text
============================= [Failed Configs] ==============================

  The following command executions failed:

    +----------+---------+
    | COMPILER | CONFIG  |
    +----------+---------+
    | clang    | Debug   |
    | gcc      | Release |
    +----------+---------+

=============================================================================
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the need for systematic testing across multiple configurations
- Built for the developer community to simplify complex build and test workflows
- Special thanks to all contributors and users who provide feedback

## Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/shriram-m/multi-cmd/issues) page
2. Create a new issue with detailed information
3. Include your command, expected behavior, and actual behavior

---

Made with ❤️ for the developer community
