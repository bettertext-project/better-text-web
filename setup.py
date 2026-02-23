import sys
from cx_Freeze import setup, Executable

# Dependencies
build_exe_options = {
    "packages": ["tkinter", "ollama", "datetime", "random"],
    "include_files": [] # Add files like 'error_log.txt' here if you want them included
}

# Fix for the Error: In newer cx_Freeze, 'Win32GUI' is now just 'gui'
base = None
if sys.platform == "win32":
    base = "gui" 

setup(
    name="BetterText",
    version="1.0",
    description="AI Powered Text Editor",
    options={"build_exe": build_exe_options},
    executables=[Executable("main.py", base=base)] # Changed to your actual file name
)