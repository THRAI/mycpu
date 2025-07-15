#!/usr/bin/env python3
import os
from colorama import init, Fore, Style

init(autoreset=True)

def is_text_file(file_path):
    """Check if a file contains text."""
    try:
        with open(file_path, 'rb') as f:
            chunk = f.read(1024)
        chunk.decode('ascii')
        return True

    except UnicodeDecodeError:
        return True  # maybe other format like Chinese
    except Exception:
        return False

def is_utf8_encoded(file_path):
    """Try decoding a file as UTF-8."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            f.read()

        return True

    except UnicodeDecodeError:
        return False

def convert_encoding(file_path, src_encoding='gb18030', dest_encoding='utf-8'):
    filename = os.path.basename(file_path)

    if is_utf8_encoded(file_path):
        print(f"✅  Already utf-8 encoded:  {Fore.GREEN}{filename}{Style.RESET_ALL}")
        return

    try:
        with open(file_path, 'r', encoding=src_encoding) as f:
            content = f.read()
        with open(file_path, 'w', encoding=dest_encoding) as f:
            f.write(content)
        print(f"✅  Converted:              {Fore.GREEN}{filename}{Style.RESET_ALL}")
    except UnicodeDecodeError:
        print(f"⚠️   Skipped (decode error): {Fore.YELLOW}{filename}{Style.RESET_ALL}")
    except Exception as e:
        print(f"❌  Failed:                 {Fore.RED}{filename}{Style.RESET_ALL} - {str(e)}")

def main():
    current_dir = os.getcwd()
    script_name = os.path.basename(__file__)

    for filename in os.listdir(current_dir):
        if filename == script_name:
            continue

        full_path = os.path.join(current_dir, filename)
        
        if os.path.isfile(full_path) and is_text_file(full_path):
            convert_encoding(full_path)

if __name__ == '__main__':
    main()
