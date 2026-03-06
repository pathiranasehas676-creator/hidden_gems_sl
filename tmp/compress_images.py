from PIL import Image
import os

files = [
    r'c:\Users\sehas\.gemini\antigravity\scratch\hidden_gems_sl\assets\images\sri_lanka_live_map.png',
    r'c:\Users\sehas\.gemini\antigravity\scratch\hidden_gems_sl\assets\images\sri_lanka_live_base.jpg'
]

for f in files:
    if os.path.exists(f):
        size_before = os.path.getsize(f)
        img = Image.open(f)
        
        if f.endswith('.png'):
            # Convert to RGB if needed, but PNG is usually fine
            img.save(f, optimize=True)
        else:
            img.save(f, quality=85, optimize=True)
            
        size_after = os.path.getsize(f)
        print(f"Compressed {os.path.basename(f)}: {size_before} -> {size_after} bytes ({(size_before-size_after)/size_before:.1%})")
