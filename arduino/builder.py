import json
import os
import platform as os_platform
import shutil
import subprocess
import multiprocessing as os_multiprocessing
from datetime import datetime
from enum import Enum, auto, unique
from typing import List, Set
import sys
import time
import select
from typing import Tuple, Optional
import re
from gettext import ngettext as _n
# from asciidoc.a2x import cli

# List of OPLC dependencies
# This list can be reduced, as soon as the HALs list provides board specific library dependencies.
OPLC_DEPS = [
    'WiFiNINA',
    'Ethernet',
    'Arduino_MachineControl',
    'Arduino_EdgeControl',
    'OneWire',
    'DallasTemperature',
    'P1AM',
    'CONTROLLINO',
    'PubSubClient',
    'ArduinoJson',
    'ArduinoMqttClient',
    'RP2040_PWM',
    'AVR_PWM',
    'megaAVR_PWM',
    'SAMD_PWM',
    'SAMDUE_PWM',
    'Portenta_H7_PWM',
    'CAN',
    'STM32_CAN',
    'STM32_PWM'
]


global base_path
base_path = 'editor/arduino/src'

global cli_command
cli_command = []

global iec_transpiler
iec_transpiler = ''

@unique
class BuildCacheOption(Enum):
    USE_CACHE = auto()
    CLEAN_BUILD = auto()
    UPGRADE_CORE = auto()
    UPGRADE_LIBS = auto()
    CLEAN_LIBS = auto()
    MR_PROPER = auto()

    def __lt__(self, other):
        if self.__class__ is other.__class__:
            return self.value < other.value
        return NotImplemented

    def __le__(self, other):
        if self.__class__ is other.__class__:
            return self.value <= other.value
        return NotImplemented

    def __gt__(self, other):
        if self.__class__ is other.__class__:
            return self.value > other.value
        return NotImplemented

    def __ge__(self, other):
        if self.__class__ is other.__class__:
            return self.value >= other.value
        return NotImplemented

    def __eq__(self, other):
        if self.__class__ is other.__class__:
            return self.value == other.value
        return NotImplemented

    def __ne__(self, other):
        if self.__class__ is other.__class__:
            return self.value != other.value
        return NotImplemented

def append_compiler_log(send_text, output):
    log_file_path = os.path.join(base_path, 'build.log')
    try:
        with open(log_file_path, 'a', newline='') as log_file:
            lines = output.splitlines()
            for line in lines:
                timestamp = datetime.now().isoformat(timespec='milliseconds')
                log_file.write(f"[{timestamp}] {line}\n")
    except IOError as e:
        print(f"Fehler beim Schreiben in die Logdatei: {e}")

    send_text(output)

def runCommand(command):
    cmd_response = None

    try:
        cmd_response = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as exc:
        cmd_response = exc.output

    if cmd_response == None:
        return ''

    return cmd_response.decode('utf-8', errors='backslashreplace')

def read_output(process, send_text, timeout=None):
    start_time = time.time()
    return_code = 0

    while True:
        output = process.stdout.readline()
        if output:
            append_compiler_log(send_text, output)

        # check for process exit
        poll_result = process.poll()
        if poll_result is not None:
            # process terminated, read remaining output data
            for line in process.stdout:
                append_compiler_log(send_text, line)
            return_code = poll_result
            break

        # watch for the timeout
        if (timeout is not None) and ((time.time() - start_time) > timeout):
            process.kill()
            return_code = -1  # timeout error code
            break

        # brief sleep to reduce CPU load
        time.sleep(0.02)

    return return_code

def runCommandToWin(send_text, command, cwd=None, timeout=None):
    return_code = -2  # default value for unexpected errors
    append_compiler_log(send_text, '$ ' + ' '.join(map(str, command)) + '\n')

    popenargs = {
            "cwd":    os.getcwd() if cwd is None else cwd,
            "stdout": subprocess.PIPE,
            "stderr": subprocess.STDOUT,
            "bufsize": 1,
            "universal_newlines": True,
            "close_fds": True,
            "encoding": "utf-8",
            "errors": "backslashreplace"
        }

    try:
        # add extra flags for Windows
        if os.name in ("nt", "ce"):
            popenargs["creationflags"] = subprocess.CREATE_NO_WINDOW

        # start the sub process
        compilation = subprocess.Popen(command, **popenargs)

        return_code = read_output(compilation, send_text, timeout)
        append_compiler_log(send_text, '$? = ' + str(return_code) + '\n')

    except subprocess.CalledProcessError as exc:
        append_compiler_log(send_text, exc.output)
        return_code = exc.returncode if exc.returncode is not None else -3

    return return_code

def log_host_info(send_text):
    # Number of logical CPU cores
    logical_cores = os_multiprocessing.cpu_count()

    # System architecture
    architecture = os_platform.architecture()[0]

    # Processor name
    processor = os_platform.processor()

    # Operating system
    os_name = os_platform.system()

    append_compiler_log(send_text, f"Host architecture: {architecture}\n")
    append_compiler_log(send_text, f"Processor: {processor}\n")
    append_compiler_log(send_text, f"Logical CPU cores: {logical_cores}\n")
    append_compiler_log(send_text, f"Operating system: {os_name}\n")

    # Additional information for Linux systems
    if os_name == "Linux":
        try:
            with open("/proc/cpuinfo", "r") as f:
                cpu_info = f.read()

            # Physical cores (rough estimate)
            physical_cores = len([line for line in cpu_info.split('\n') if line.startswith("physical id")])
            append_compiler_log(send_text, f"Estimated physical CPU cores: {physical_cores or 'Not available'}\n")

            # CPU frequency
            cpu_mhz = [line for line in cpu_info.split('\n') if "cpu MHz" in line]
            if cpu_mhz:
                append_compiler_log(send_text, f"CPU frequency: {cpu_mhz[0].split(':')[1].strip()} MHz\n")
            else:
                append_compiler_log(send_text, "CPU frequency: Not available\n")

        except Exception as e:
            append_compiler_log(send_text, f"Error reading /proc/cpuinfo: {e}\n")

    # Additional information for macOS systems
    elif os_name == "Darwin":  # Darwin is the core of macOS
        try:
            # Physical cores
            physical_cores = int(subprocess.check_output(["sysctl", "-n", "hw.physicalcpu"]).decode().strip())
            append_compiler_log(send_text, f"Physical CPU cores: {physical_cores}\n")

            # CPU frequency
            cpu_freq = subprocess.check_output(["sysctl", "-n", "hw.cpufrequency"]).decode().strip()
            cpu_freq_mhz = int(cpu_freq) / 1000000  # Convert Hz to MHz
            append_compiler_log(send_text, f"CPU frequency: {cpu_freq_mhz:.2f} MHz\n")

            # CPU model
            cpu_model = subprocess.check_output(["sysctl", "-n", "machdep.cpu.brand_string"]).decode().strip()
            append_compiler_log(send_text, f"CPU model: {cpu_model}\n")

        except Exception as e:
            append_compiler_log(send_text, f"Error getting macOS CPU info: {e}\n")

    path_content = os.environ.get('PATH', '')
    append_compiler_log(send_text, "\n" + _("active PATH Variable") + ":\n" + path_content + "\n\n")

def are_libraries_installed(lib_list: List[str]) -> List[str]:
    """
    Check if the specified Arduino libraries are installed.
    
    Args:
        lib_list: List of library names to check
        
    Returns:
        List[str]: List of libraries that are not installed
    """
    try:
        # Get list of installed libraries in JSON format
        cmd = cli_command + ['--json', 'lib', 'list']
        result = runCommand(' '.join(cmd))
        
        if not result:
            return lib_list
            
        # Parse JSON output
        libraries_data = json.loads(result)
        
        # Get set of installed library names
        installed_libs = {
            lib.get('library', {}).get('name')
            for lib in libraries_data.get('installed_libraries', [])
        }
        
        # Return list of libraries that are not in installed set
        return [lib for lib in lib_list if lib not in installed_libs]
        
    except json.JSONDecodeError as e:
        append_compiler_log(send_text, _("Error parsing JSON output while checking libraries: {error}").format(error=str(e)) + '\n')
        return lib_list
    except Exception as e:
        append_compiler_log(send_text, _("Error checking libraries: {error}").format(error=str(e)) + '\n')
        return lib_list

def check_libraries_status() -> Tuple[int, str]:
    """
    Check the status of Arduino libraries using JSON output format.
    
    Returns:
        Tuple[int, str]: (Status code, Description)
        Status codes:
        0 - All up to date
        1 - Updates available
        2 - Error checking libraries
    """
    try:
        import json
        
        # Check for available updates using JSON format
        cmd = cli_command + ['--json', '--no-color', 'lib', 'list', '--updatable']
        json_output = runCommand(' '.join(cmd)).strip()
        
        # Parse JSON output
        lib_data = json.loads(json_output)
        updatable_libs = lib_data.get('installed_libraries', [])
        
        if not updatable_libs:
            return (0, _("All libraries are up to date"))
        
        lib_count = len(updatable_libs)
        return (1, _n(
            "Update available for {count} library",
            "Updates available for {count} libraries",
            lib_count
        ).format(count=lib_count))
            
    except json.JSONDecodeError as e:
        return (2, _("Error parsing JSON output: {error_message}").format(error_message=str(e)))
    except Exception as e:
        return (2, _("Error checking libraries: {error_message}").format(error_message=str(e)))
    
def get_installed_libraries(cli_command_str) -> List[str]:
    #print("Executing command:", cli_command_str + " lib list --json")
    libraries_json = runCommand(cli_command_str + " lib list --json")

    try:
        libraries_data = json.loads(libraries_json)
        installed_libs = []

        for lib in libraries_data.get("installed_libraries", []):
            lib_name = lib.get("library", {}).get("name")
            if lib_name:
                installed_libs.append(lib_name)

        #print("Installed libraries:", installed_libs)
        return installed_libs
    except json.JSONDecodeError as e:
        print("Error decoding JSON:", e)
        print("Raw JSON output:", libraries_json)
        return []
    except Exception as e:
        print("An error occurred:", e)
        return []

def clean_libraries(send_text, cli_command):
    # the intended behavior is to keep the list of installed libraries identical, but remove all and re-install all of them
    return_code = 0
    append_compiler_log(send_text, _("Cleaning libraries") + "...\n")
    installed_libraries = get_installed_libraries(' '.join(cli_command))

    # Merge installed libraries with OPLC_DEPS and remove duplicates
    all_libraries: Set[str] = set(installed_libraries + OPLC_DEPS)

    append_compiler_log(send_text, _n(
        "Processing {count} library",
        "Processing {count} libraries",
        len(all_libraries)
    ).format(count=len(all_libraries)) + "\n")
    
    for lib in all_libraries:
        append_compiler_log(send_text, _("Processing library: {lib}").format(lib=lib) + "\n")
        runCommandToWin(send_text, cli_command + ['lib', 'uninstall', lib])
        return_code = runCommandToWin(send_text, cli_command + ['lib', 'install', lib])
        if (return_code != 0):
            append_compiler_log(send_text, '\n' + _('LIBRARIES INSTALLATION FAILED') + ': ' + lib + '\n')
            return

    return return_code

def upgrade_libraries(send_text) -> Tuple[bool, str]:
    """
    Performs upgrade of all outdated libraries.
    
    Returns:
        Tuple[bool, str]: (Success, Description)
    """
    try:
        # Update library index
        cmd = cli_command + ['lib', 'update-index']
        runCommandToWin(send_text, cmd)
        
        # Check for updates
        status, message = check_libraries_status()
        if status == 0:  # All up to date
            return (True, message)
        elif status == 2:  # Error
            return (False, message)
            
        # Perform upgrade
        cmd = cli_command + ['lib', 'upgrade']
        result = runCommandToWin(send_text, cmd)
        return (True, _("Libraries upgrade completed."))
            
    except Exception as e:
        return (False, _("Libraries upgrade failed: {error_message}").format(error_message=str(e)))

def get_platform_list(json_data: dict) -> List[dict]:
    """
    Safely extracts the platforms array from Arduino CLI JSON output.
    
    Args:
        json_data: Dictionary parsed from Arduino CLI JSON output
        
    Returns:
        List[dict]: List of platform dictionaries, empty list if no platforms or invalid data
    """
    platforms = json_data.get('platforms')
    
    # Check if platforms exists and is a list/tuple
    if platforms is None or not isinstance(platforms, (list, tuple)):
        return []
        
    return platforms

def get_core_version(core_id: str) -> Optional[str]:
    """
    Get the installed version of a specific Arduino core.
    
    Args:
        core_id: The ID of the core (e.g. 'esp32:esp32')
        
    Returns:
        The installed version as string or None if core is not installed
        
    Example:
        >>> get_core_version('esp32:esp32')
        '2.0.11'
    """
    try:
        # Run arduino-cli command and capture output
        cmd = cli_command + ['--json', 'core', 'list']
        result = runCommand(' '.join(cmd))
        
        # Parse JSON output
        data = json.loads(result)
        platforms = get_platform_list(data)
        
        # Search for the specified core
        for platform in platforms:
            if platform.get('id') == core_id:
                return platform.get('installed_version')
                
        return None
        
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON output: {e}")
        return None

def check_core_status(core_name: str) -> Tuple[int, str]:
    """
    Check the status of an Arduino core using JSON output.
    
    Args:
        core_name: Name of the core (e.g. "esp32:esp32")
        
    Returns:
        Tuple[int, str]: (Status code, Description)
        Status codes:
        0 - Up to date or no action needed
        1 - First installation needed
        2 - Reinstallation recommended
    """
    try:
        # Update index first
        cmd = cli_command + ['--json', 'core', 'update-index']
        result = runCommand(' '.join(cmd))
        update_data = json.loads(result)
        
        if 'error' in update_data:
            return (2, _("Error updating core index: {error}").format(
                error=update_data.get('error', 'Unknown error')))
        
        # Check if core is installed
        cmd = cli_command + ['--json', 'core', 'list']
        result = runCommand(' '.join(cmd))
        cores_data = json.loads(result)
        platforms = get_platform_list(cores_data)
        
        core_found = False
        for platform in platforms:
            if platform.get('id') == core_name:
                core_found = True
                break
                
        if not core_found:
            return (1, _("Core {core_name} is not installed").format(core_name=core_name))
        
        # Check for available updates
        cmd = cli_command + ['--json', 'core', 'list', '--updatable']
        result = runCommand(' '.join(cmd))
        updates_data = json.loads(result)
        updatable_platforms = get_platform_list(updates_data)
        
        for platform in updatable_platforms:
            if platform.get('id') == core_name:
                return (2, _("Updates found for {core_name}").format(core_name=core_name))
        
        return (0, _("No updates available for {core_name}").format(core_name=core_name))
            
    except json.JSONDecodeError as e:
        return (2, _("Error parsing JSON output: {error_message}").format(error_message=str(e)))
    except Exception as e:
        return (2, _("Error checking core: {error_message}").format(error_message=str(e)))
    
def reinstall_core(send_text, core_name: str) -> Tuple[bool, str]:
    """
    Forces complete reinstallation of core.
    
    Args:
        core_name: Name of the core (e.g. "esp32:esp32")
        
    Returns:
        Tuple[bool, str]: (Success, Description)
    """
    try:
        # Update index first
        cmd = cli_command + ['core', 'update-index']
        runCommandToWin(send_text, cmd)
        
        # Check if core exists using JSON output
        cmd = cli_command + ['--json', 'core', 'list']
        result = runCommand(' '.join(cmd))
        cores_data = json.loads(result)
        platforms = get_platform_list(cores_data)
        
        core_installed = any(
            platform.get('id') == core_name 
            for platform in platforms
        )
        
        # Remove core if exists
        if core_installed:
            cmd = cli_command + ['core', 'uninstall', core_name]
            runCommandToWin(send_text, cmd)
        
        # Install core
        cmd = cli_command + ['core', 'install', core_name]
        result = runCommandToWin(send_text, cmd)
        if result != 0:
            return (False, _("Core reinstallation failed."))
        return (True, _("Core reinstallation completed.").format(result=result))
            
    except Exception as e:
        return (False, _("Core reinstallation failed: {error_message}").format(error_message=str(e)))

def upgrade_core(send_text, core_name: str) -> Tuple[bool, str]:
    """
    Performs necessary update actions for a core.
    
    Args:
        core_name: Name of the core (e.g. "esp32:esp32")
        
    Returns:
        Tuple[bool, str]: (Success, Description)
    """
    try:
        # Update index
        cmd = cli_command + ['core', 'update-index']
        result = runCommandToWin(send_text, cmd)
        
        # Check status
        status, message = check_core_status(core_name)
        
        if status == 0:
            # Double-check for updates with JSON output
            cmd = cli_command + ['--json', 'core', 'list', '--updatable']
            result = runCommand(' '.join(cmd))
            updates_data = json.loads(result)
            updatable_platforms = get_platform_list(updates_data)
            
            core_needs_update = any(
                platform.get('id') == core_name 
                for platform in updatable_platforms
            )
            
            if core_needs_update:
                cmd = cli_command + ['core', 'upgrade', core_name]
                result = runCommandToWin(send_text, cmd)
                if result != 0:
                    return (False, _("Upgrade failed."))
                return (True, _("Upgrade successful."))
            return (True, _("No action needed"))
            
        elif status == 1:
            # Perform reinstallation
            cmd = cli_command + ['core', 'uninstall', core_name]
            runCommandToWin(send_text, cmd)
            cmd = cli_command + ['core', 'install', core_name]
            result = runCommandToWin(send_text, cmd)
            if result != 0:
                return (False, _("Reinstallation failed."))
            return (True, _("Reinstallation successful."))
            
        elif status == 2:
            # Perform first installation
            cmd = cli_command + ['core', 'install', core_name]
            result = runCommandToWin(send_text, cmd)
            if result != 0:
                return (False, _("Initial core installation failed."))
            return (True, _("Initial core installation successful."))
            
    except Exception as e:
        return (False, _("Error with {core_name}: {err_msg}").format(core_name=core_name, err_msg=str(e)))

def is_board_url_configured(url: str) -> bool:
    """
    Check if a specific board manager URL is configured in arduino-cli.
    
    Args:
        url: Board manager URL to check
        
    Returns:
        bool: True if URL is configured, False otherwise
    """
    try:
        # Get current config
        cmd = cli_command + ['config', 'dump', '--format', 'json']
        result = runCommand(' '.join(cmd))
        
        # Parse JSON output
        config = json.loads(result)
        
        # Check if URL exists in board manager URLs
        configured_urls = config.get('config', {}).get('board_manager', {}).get('additional_urls', [])
        return url in configured_urls
        
    except Exception as e:
        print(f"Error checking board URL configuration: {e}")
        return False

def build(st_file, definitions, arduino_sketch, port, send_text, board_hal, build_option):
    """
    Build and optionally upload Arduino program with specified build cache options.
    
    Args:
        st_file: Content of the ST (Structured Text) file
        port: Serial port for upload (optional)
        send_text: Callback for user notifications
        board_hal: Board HAL configuration
        build_option: BuildCacheOption enum value
    """
    
    arduino_platform = board_hal['platform']
    source_file = board_hal['source']
    required_libs = OPLC_DEPS   # in the future this might take project libraries, board specific libraries and extension specific libraries too

    def setup_environment() -> bool:
        global base_path, cli_command, iec_transpiler
        base_path = 'editor/arduino/src'
        
        # Convert base_path to absolute path
        base_path = os.path.abspath(base_path)
        
        # Clear build log
        open(os.path.join(base_path, 'build.log'), 'w').close()
        log_host_info(send_text)
        
        # Setup CLI command based on platform
        if os_platform.system() == 'Windows':
            cli_command = [os.path.abspath('editor\\arduino\\bin\\arduino-cli-w64.exe'), '--no-color']
            iec_transpiler = os.path.abspath('editor/arduino/bin/iec2c.exe')
        elif os_platform.system() == 'Darwin':
            cli_command = [os.path.abspath('editor/arduino/bin/arduino-cli-mac'), '--no-color']
            iec_transpiler = os.path.abspath('editor/arduino/bin/iec2c_mac')
        else:
            cli_command = [os.path.abspath('editor/arduino/bin/arduino-cli-l64'), '--no-color']
            iec_transpiler = os.path.abspath('editor/arduino/bin/iec2c')
            
        # Clean old files
        old_files = ['POUS.c', 'POUS.h', 'LOCATED_VARIABLES.h', 
                    'VARIABLES.csv', 'Config0.c', 'Config0.h', 'Res0.c']
        for file in old_files:
            if os.path.exists(os.path.join(base_path, file)):
                os.remove(os.path.join(base_path, file))
            
        return True

    def verify_prerequisites() -> bool:
        global cli_command, iec_transpiler
        # Check MatIEC compiler
        if not os.path.exists(iec_transpiler):
            append_compiler_log(send_text, _("Error: iec2c compiler not found!") + '\n')
            return False
            
        if not os.path.exists(cli_command[0]):
            append_compiler_log(send_text, _("Error: arduino-cli not found!") + '\n')
            return False
        
        return True

    def handle_board_installation() -> bool:
        global cli_command
        append_compiler_log(send_text, 'Checking Core and Board installation...\n')
        core = board_hal['core']
        core_status, message = check_core_status(core)
        append_compiler_log(send_text, f'{message}\n')
        
        board_manager_url = board_hal.get('board_manager_url', None)
        if board_manager_url:
            board_installed = is_board_url_configured(board_manager_url)
        else:
            board_installed = re.match(r"arduino:.*", core) # usually all/only arduino cores do not need an additional board manager URL
        
        if not board_installed or build_option >= BuildCacheOption.MR_PROPER:
            append_compiler_log(send_text, _("Cleaning download cache") + "...\n")
            if runCommandToWin(send_text, cli_command + ['cache', 'clean']) != 0:
                return False
                
            # Initialize config
            runCommandToWin(send_text, cli_command + ['config', 'init'])    # ignore return value, most the time we would need '--overwrite', which is not our intent
                
            # Handle board manager URL if present
            if board_manager_url:
                cmds = [
                    ['config', 'remove', 'board_manager.additional_urls', board_manager_url],
                    ['config', 'add', 'board_manager.additional_urls', board_manager_url]
                ]
                for cmd in cmds:
                    if runCommandToWin(send_text, cli_command + cmd) != 0:
                        return False
            
            # Install core
            success, message = reinstall_core(send_text, core)
            if not success:
                append_compiler_log(send_text, f'\n{message}\n')
                return False
            
            board_hal['last_update'] = time.time()
            board_hal['version'] = get_core_version(core)
            
        # Handle core updates based on build option
        elif core_status >= 1 or build_option >= BuildCacheOption.UPGRADE_CORE:
            success, message = upgrade_core(send_text, core)
            if not success:
                append_compiler_log(send_text, f'\n{message}\n')
                return False
            
            board_hal['last_update'] = time.time()
            board_hal['version'] = get_core_version(core)
                
        append_compiler_log(send_text, f'\n')
        return True

    def check_required_libraries() -> bool:
        """
        Check if all required libraries are installed and install missing ones.
        
        Inputs:
            send_text: Function to handle output messages
            required_libs: List of required library names
            
        Returns:
            bool: True if all libraries are installed or were successfully installed,
                  False if any library couldn't be installed
        """
        append_compiler_log(send_text, _("Checking required libraries...") + '\n')
        
        # Check which libraries need to be installed
        missing_libs = are_libraries_installed(required_libs)
        
        if not missing_libs:
            append_compiler_log(send_text, _("All required libraries are already installed.") + '\n')
            return True
        
        # Update the library index before installation
        try:
            cmd = cli_command + ['lib', 'update-index']
            result = runCommandToWin(send_text, cmd)
        except Exception as e:
            append_compiler_log(send_text, _("Error updating library index: {error}").format(error=str(e)) + '\n')
            return False
        
        # Try to install missing libraries
        append_compiler_log(send_text, _n(
            "Installing {count} missing library",
            "Installing {count} missing libraries",
            len(missing_libs)
        ).format(count=len(missing_libs)) + '\n')
        
        for lib in missing_libs:
            append_compiler_log(send_text, _("Installing library: {lib}").format(lib=lib) + '\n')
            try:
                cmd = cli_command + ['lib', 'install', lib]
                result = runCommand(' '.join(cmd))
            except Exception as e:
                append_compiler_log(send_text, _("Error installing library {lib}: {error}").format(lib=lib, error=str(e)) + '\n')
                return False
        
        # Verify all libraries are now installed
        still_missing = are_libraries_installed(required_libs)
        if still_missing:
            append_compiler_log(send_text, _n(
                "Failed to install {count} library: {libs}",
                "Failed to install {count} libraries: {libs}",
                len(still_missing)
            ).format(count=len(still_missing), libs=', '.join(still_missing)) + '\n')
            return False
            
        append_compiler_log(send_text, _("All required libraries have been successfully installed.") + '\n')
        return True

    def update_libraries() -> bool:
        global cli_command
        append_compiler_log(send_text, _('Checking Libraries status...') + '\n')
        libraries_status, message = check_libraries_status()
        append_compiler_log(send_text, f'{message}\n')
        
        if build_option >= BuildCacheOption.CLEAN_LIBS:
            return_code = clean_libraries(send_text, cli_command)
        elif build_option >= BuildCacheOption.UPGRADE_LIBS:
            success, message = upgrade_libraries(send_text)
            if not success:
                append_compiler_log(send_text, f'\n{message}\n')
                return False
        
        append_compiler_log(send_text, f'\n')
        return True

    def compile_st_file() -> bool:
        global base_path, iec_transpiler
        append_compiler_log(send_text, _("Compiling .st file...") + '\n')
        
        # Write ST file
        with open(f'{base_path}/plc_prog.st', 'w') as f:
            f.write(st_file)
            f.flush()
        
        time.sleep(0.2)  # ensure file is written
        
        # Compile based on platform
        cmd = [iec_transpiler, '-f', '-l', '-p', 'plc_prog.st']
        cwd = base_path
            
        return runCommandToWin(send_text, cmd, cwd=cwd) == 0
    
    def provide_hal_data() -> bool:
        global base_path
        # Copy HAL file
        shutil.copyfile(f'{base_path}/hal/{source_file}', f'{base_path}/arduino.cpp')
        
        return True

    def write_definitions_file():
        """
        Write definitions array to defines.h file
        
        Inputs:
            definitions (list): List of definition strings
            base_path (str): Base path for Arduino project
            send_text (callable): Function to handle output messages
            
        Returns:
            bool: True if successful, False if error occurred
        """
        defines_path = os.path.join(base_path, 'defines.h')
        
        try:
            with open(defines_path, 'w') as f:
                content = '\n'.join(definitions)
                f.write(content)
                f.flush()
            return True
                
        except IOError as e:
            append_compiler_log(send_text, _("Error writing defines.h: {err_msg}\n").format(err_msg=str(e)))
            return False
        
    def write_arduino_sketch():
        """
        Write Arduino sketch to header file if sketch exists
        
        Inputs:
            arduino_sketch (str): Arduino sketch content or None
            base_path (str): Base path for Arduino project
            send_text (callable): Function to handle output messages
            
        Returns:
            bool: True if successful or no sketch provided, False if error occurred
        """
        sketch_path = os.path.join(base_path, 'ext', 'arduino_sketch.h')
        
            # Delete existing file if it exists
        try:
            os.remove(sketch_path)
        except FileNotFoundError:
            pass  # File doesn't exist yet - that's fine
        except OSError as e:
            append_compiler_log(send_text, _("Error removing old arduino_sketch.h: {err_msg}\n").format(err_msg=str(e)))
            return False
    
        if arduino_sketch is None:
            return True
            
        try:
            os.makedirs(os.path.dirname(sketch_path), exist_ok=True)
            with open(sketch_path, 'w') as f:
                f.write(arduino_sketch)
                f.flush()
            return True
                
        except (IOError, OSError) as e:
            append_compiler_log(send_text, _("Error writing arduino_sketch.h: {err_msg}\n").format(err_msg=str(e)))
            return False
    
    def generate_glue_code() -> bool:
        global base_path
        if not os.path.exists(f'{base_path}/LOCATED_VARIABLES.h'):
            append_compiler_log(send_text, _("Error: Couldn't find LOCATED_VARIABLES.h") + '\n')
            return False
            
        located_vars_file = open(f'{base_path}/LOCATED_VARIABLES.h', 'r')
        located_vars = located_vars_file.readlines()
        glueVars = """
#include "iec_std_lib.h"

#define __LOCATED_VAR(type, name, ...) type __##name;
#include "LOCATED_VARIABLES.h"
#undef __LOCATED_VAR
#define __LOCATED_VAR(type, name, ...) type* name = &__##name;
#include "LOCATED_VARIABLES.h"
#undef __LOCATED_VAR

TIME __CURRENT_TIME;
BOOL __DEBUG;
extern unsigned long long common_ticktime__;

//OpenPLC Buffers
#if defined(__AVR_ATmega328P__) || defined(__AVR_ATmega168__) || defined(__AVR_ATmega32U4__) || defined(__AVR_ATmega16U4__)

#define MAX_DIGITAL_INPUT          8
#define MAX_DIGITAL_OUTPUT         32
#define MAX_ANALOG_INPUT           6
#define MAX_ANALOG_OUTPUT          32
#define MAX_MEMORY_WORD            0
#define MAX_MEMORY_DWORD           0
#define MAX_MEMORY_LWORD           0

IEC_BOOL *bool_input[MAX_DIGITAL_INPUT/8][8];
IEC_BOOL *bool_output[MAX_DIGITAL_OUTPUT/8][8];
IEC_UINT *int_input[MAX_ANALOG_INPUT];
IEC_UINT *int_output[MAX_ANALOG_OUTPUT];

#else

#define MAX_DIGITAL_INPUT          56
#define MAX_DIGITAL_OUTPUT         56
#define MAX_ANALOG_INPUT           32
#define MAX_ANALOG_OUTPUT          32
#define MAX_MEMORY_WORD            20
#define MAX_MEMORY_DWORD           20
#define MAX_MEMORY_LWORD           20

IEC_BOOL *bool_input[MAX_DIGITAL_INPUT/8][8];
IEC_BOOL *bool_output[MAX_DIGITAL_OUTPUT/8][8];
IEC_UINT *int_input[MAX_ANALOG_INPUT];
IEC_UINT *int_output[MAX_ANALOG_OUTPUT];
IEC_UINT *int_memory[MAX_MEMORY_WORD];
IEC_UDINT *dint_memory[MAX_MEMORY_DWORD];
IEC_ULINT *lint_memory[MAX_MEMORY_LWORD];

#endif


void glueVars()
{
"""
        for located_var in located_vars:
            # cleanup located var line
            if ('__LOCATED_VAR(' in located_var):
                located_var = located_var.split('(')[1].split(')')[0]
                var_data = located_var.split(',')
                if (len(var_data) < 5):
                    append_compiler_log(send_text, _('Error processing located var line: {var_line_text}').format(var_line_text=located_var) + '\n')
                else:
                    var_type = var_data[0]
                    var_name = var_data[1]
                    var_address = var_data[4]
                    var_subaddress = '0'
                    if (len(var_data) > 5):
                        var_subaddress = var_data[5]
    
                    # check variable type and assign to correct buffer pointer
                    if ('QX' in var_name):
                        if (int(var_address) > 6 or int(var_subaddress) > 7):
                            append_compiler_log(send_text, _('Error: wrong location for var {var_name}').format(var_name=var_name) + '\n')
                            return
                        glueVars += '    bool_output[' + var_address + \
                            '][' + var_subaddress + '] = ' + var_name + ';\n'
                    elif ('IX' in var_name):
                        if (int(var_address) > 6 or int(var_subaddress) > 7):
                            append_compiler_log(send_text, _('Error: wrong location for var {var_name}').format(var_name=var_name) + '\n')
                            return
                        glueVars += '    bool_input[' + var_address + \
                            '][' + var_subaddress + '] = ' + var_name + ';\n'
                    elif ('QW' in var_name):
                        if (int(var_address) > 32):
                            append_compiler_log(send_text, _('Error: wrong location for var {var_name}').format(var_name=var_name) + '\n')
                            return
                        glueVars += '    int_output[' + \
                            var_address + '] = ' + var_name + ';\n'
                    elif ('IW' in var_name):
                        if (int(var_address) > 32):
                            append_compiler_log(send_text, _('Error: wrong location for var {var_name}').format(var_name=var_name) + '\n')
                            return
                        glueVars += '    int_input[' + \
                            var_address + '] = ' + var_name + ';\n'
                    elif ('MW' in var_name):
                        if (int(var_address) > 20):
                            append_compiler_log(send_text, _('Error: wrong location for var {var_name}').format(var_name=var_name) + '\n')
                            return
                        glueVars += '    int_memory[' + \
                            var_address + '] = ' + var_name + ';\n'
                    elif ('MD' in var_name):
                        if (int(var_address) > 20):
                            append_compiler_log(send_text, _('Error: wrong location for var {var_name}').format(var_name=var_name) + '\n')
                            return
                        glueVars += '    dint_memory[' + \
                            var_address + '] = ' + var_name + ';\n'
                    elif ('ML' in var_name):
                        if (int(var_address) > 20):
                            append_compiler_log(send_text, _('Error: wrong location for var {var_name}').format(var_name=var_name) + '\n')
                            return
                        glueVars += '    lint_memory[' + \
                            var_address + '] = ' + var_name + ';\n'
                    else:
                        append_compiler_log(send_text, _('Could not process location "{var_name}" from line: {var_line_text}').format(var_name=var_name, var_line_text=located_var) + '\n')
                        return
    
        glueVars += """
}

void updateTime()
{
    __CURRENT_TIME.tv_nsec += common_ticktime__;

    if (__CURRENT_TIME.tv_nsec >= 1000000000)
    {
        __CURRENT_TIME.tv_nsec -= 1000000000;
        __CURRENT_TIME.tv_sec += 1;
    }
}
"""
        f = open(f'{base_path}/glueVars.c', 'w')
        f.write(glueVars)
        f.flush()
        f.close()
    
        time.sleep(2)  # make sure glueVars.c was written to disk
        
        return True

    def patch_generated_files() -> bool:
        global base_path
        # Patch POUS.c
        with open(f'{base_path}/POUS.c', 'r') as f:
            pous_content = f.read()
        with open(f'{base_path}/POUS.c', 'w') as f:
            f.write('#include "POUS.h"\n\n' + pous_content)
            
        # Patch Res0.c
        with open(f'{base_path}/Res0.c', 'r') as f:
            res0_lines = f.readlines()
        with open(f'{base_path}/Res0.c', 'w') as f:
            for line in res0_lines:
                if '#include "POUS.c"' in line:
                    f.write('#include "POUS.h"\n')
                else:
                    f.write(line)
                    
        return True

    def build_project() -> bool:
        global cli_command
        append_compiler_log(send_text, _('Generating binary file...') + '\n')
        
        build_cmd = cli_command + ['compile', '-v']
        if build_option >= BuildCacheOption.CLEAN_BUILD:
            build_cmd.append('--clean')
            
        # TODO: move extra build flags to board_hal
        # Add build flags
        extraflags = ' -MMD -c' if board_hal['core'] == 'esp32:esp32' else ''
        build_cmd.extend([
            '--libraries=editor/arduino',
            '--build-property', f'compiler.c.extra_flags=-Ieditor/arduino/src/lib{extraflags}',
            '--build-property', f'compiler.cpp.extra_flags=-Ieditor/arduino/src/lib{extraflags}',
            '--export-binaries',
            '-b', arduino_platform,
            'editor/arduino/examples/Baremetal/Baremetal.ino'
        ])
        
        return runCommandToWin(send_text, build_cmd) == 0

    def upload_if_needed() -> bool:
        if port is None:
            # Show output directory
            cwd = os.getcwd()
            build_dir = '\\' if os_platform.system() == 'Windows' else '/'
            build_dir = f"{cwd}{build_dir}editor{build_dir}arduino{build_dir}examples{build_dir}Baremetal{build_dir}build"
            append_compiler_log(send_text, f'\n{_("OUTPUT DIRECTORY:")}:\n{build_dir}\n')
            append_compiler_log(send_text, '\n' + _('COMPILATION DONE!'))
            return True
            
        # Upload to board
        append_compiler_log(send_text, f'\n{_("Uploading program to Arduino board at {port}...")}\n')
        cmd = cli_command + ['upload', '--port', port, '--fqbn', arduino_platform, 
                            'editor/arduino/examples/Baremetal/']
        if runCommandToWin(send_text, cmd) != 0:
            return False
            
        append_compiler_log(send_text, '\n' + _('Done!') + '\n')
        return True
    
    def cleanup_build() -> bool:
        # cleanup build remains
        time.sleep(1)  # ensure files are not in use
        
        # return early, no clean up
        return True
    
        # Clean up and return
        if os.path.exists(base_path+'POUS.c'):
            os.remove(base_path+'POUS.c')
        if os.path.exists(base_path+'POUS.h'):
            os.remove(base_path+'POUS.h')
        if os.path.exists(base_path+'LOCATED_VARIABLES.h'):
            os.remove(base_path+'LOCATED_VARIABLES.h')
        if os.path.exists(base_path+'VARIABLES.csv'):
            os.remove(base_path+'VARIABLES.csv')
        if os.path.exists(base_path+'Config0.c'):
            os.remove(base_path+'Config0.c')
        if os.path.exists(base_path+'Config0.h'):
            os.remove(base_path+'Config0.h')
        if os.path.exists(base_path+'Config0.o'):
            os.remove(base_path+'Config0.o')
        if os.path.exists(base_path+'Res0.c'):
            os.remove(base_path+'Res0.c')
        if os.path.exists(base_path+'Res0.o'):
            os.remove(base_path+'Res0.o')
        if os.path.exists(base_path+'glueVars.c'):
            os.remove(base_path+'glueVars.c')


    # Main build sequence
    build_phases = [
        setup_environment,
        verify_prerequisites,
        handle_board_installation,
        check_required_libraries,
        update_libraries,
        compile_st_file,
        provide_hal_data,
        write_definitions_file,
        write_arduino_sketch,
        generate_glue_code,
        patch_generated_files,
        build_project,
        upload_if_needed,
        cleanup_build
    ]
    
    for phase in build_phases:
        if not phase():
            return
            
