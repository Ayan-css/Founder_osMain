import os
import re

directory = 'lib/services/database/collections'
counter = 1

for filename in os.listdir(directory):
    if filename.endswith('.g.dart'):
        filepath = os.path.join(directory, filename)
        with open(filepath, 'r') as f:
            content = f.read()
        
        def replace_large_int(match):
            global counter
            val_str = match.group(1)
            try:
                val = int(val_str)
                # JavaScript safe integer limit is 9,007,199,254,740,991
                if val > 9007199254740991 or val < -9007199254740991:
                    new_val = counter
                    counter += 1
                    return f"id: {new_val},"
            except ValueError:
                pass
            return match.group(0)

        new_content = re.sub(r'id:\s*(-?\d+),', replace_large_int, content)
        
        if new_content != content:
            with open(filepath, 'w') as f:
                f.write(new_content)
            print(f"Patched {filename}")

print("Done patching Isar files for Web!")
