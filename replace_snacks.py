import os
import re

def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex finding ScaffoldMessenger
    # We will match from ScaffoldMessenger.of(context).showSnackBar( to the balancing parenthesis );
    # And extract the text from content: Text(...)
    
    pattern = re.compile(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\((.*?)\)\s*?,?\s*\);",
        re.DOTALL
    )

    matches = pattern.finditer(content)
    new_content = content
    modified = False

    for m in reversed(list(matches)):
        full_match = m.group(0)
        inner = m.group(1)
        
        # extracted text inside content: Text(...)
        text_match = re.search(r"content:\s*Text\(\s*(.*?)\s*\)", inner, re.DOTALL)
        if text_match:
            text = text_match.group(1).strip()
            # remove trailing comma if present
            if text.endswith(','): text = text[:-1]
        else:
            text = "'Thông báo'"
            
        # check color
        is_error = False
        is_success = False
        if 'Colors.red' in inner or 'Colors.orange' in inner:
            is_error = True
        elif 'Colors.green' in inner:
            is_success = True
            
        if is_error:
            method = "showError"
            title = "Lỗi"
        elif is_success:
            method = "showSuccess"
            title = "Thành công"
        else:
            method = "showInfo"
            title = "Thông báo"
            
        replacement = f"NotificationUtils.{method}(context: context, title: '{title}', description: {text});"
        
        start, end = m.span()
        new_content = new_content[:start] + replacement + new_content[end:]
        modified = True

    if modified:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)

def main():
    lib_dir = r"d:\WorkSpace\Bittech_Project\notification_flutter_client\lib"
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith(".dart"):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
